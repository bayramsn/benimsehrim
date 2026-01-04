import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../common/prisma/prisma.service';
import { RedisService } from '../../common/redis/redis.service';
import { NotificationsService } from '../notifications/notifications.service';
import { RideStatus } from '@prisma/client';

/**
 * Taxi Automation Service
 * 
 * Operasyonel Kurallar:
 * - Çağrı 30 sn cevaplanmazsa başka taksi
 * - Kabul sonrası 60 sn hareket yoksa iptal
 * - Günlük iptal limiti
 * - Konum kapalıysa offline
 * - Son 24 saat pasif şoför otomatik devre dışı
 */
@Injectable()
export class TaxiAutomationService {
  private readonly logger = new Logger(TaxiAutomationService.name);
  private readonly MAX_DAILY_CANCELS = 5;

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private notifications: NotificationsService,
  ) {}

  /**
   * Yeni taksi çağrısı başlat
   */
  async startRideSearch(rideId: string): Promise<void> {
    const ride = await this.prisma.taxiRide.findUnique({
      where: { id: rideId },
    });

    if (!ride) return;

    // Yakındaki şoförleri bul
    const nearbyDrivers = await this.findNearbyDrivers(
      ride.pickupLat,
      ride.pickupLng,
      3, // 3 km yarıçap
    );

    if (nearbyDrivers.length === 0) {
      // Hiç şoför yok
      await this.prisma.taxiRide.update({
        where: { id: rideId },
        data: { status: RideStatus.NO_DRIVER },
      });

      await this.notifications.sendPush({
        userId: ride.userId,
        title: 'Taksi Bulunamadı',
        body: 'Şu anda yakınınızda müsait taksi bulunmuyor. Lütfen daha sonra tekrar deneyin.',
        data: { type: 'NO_DRIVER', rideId },
      });

      return;
    }

    // İlk şoföre çağrı gönder
    await this.sendRideCallToDriver(rideId, nearbyDrivers[0].id);
  }

  /**
   * Şoföre çağrı gönder
   */
  private async sendRideCallToDriver(rideId: string, driverId: string): Promise<void> {
    const driver = await this.prisma.driver.findUnique({
      where: { id: driverId },
      include: { user: true },
    });

    if (!driver) return;

    const ride = await this.prisma.taxiRide.findUnique({
      where: { id: rideId },
    });

    if (!ride) return;

    // Çağrı kaydı oluştur
    await this.prisma.rideCall.create({
      data: {
        rideId,
        driverId,
        status: 'PENDING',
      },
    });

    // Push bildirimi gönder
    await this.notifications.sendPush({
      userId: driver.userId,
      title: '🚕 Yeni Çağrı!',
      body: `${ride.pickupAddress} → ${ride.dropAddress}`,
      data: {
        type: 'NEW_RIDE_CALL',
        rideId,
        pickupLat: ride.pickupLat,
        pickupLng: ride.pickupLng,
        dropLat: ride.dropLat,
        dropLng: ride.dropLng,
        estFare: ride.estFare,
      },
    });

    // 30 saniye timeout için işaretle
    await this.redis.set(
      `ride_call:${rideId}:${driverId}`,
      JSON.stringify({ rideId, driverId, sentAt: Date.now() }),
      35,
    );

    this.logger.log(`Ride call sent to driver ${driverId} for ride ${rideId}`);
  }

  /**
   * Yakındaki şoförleri bul
   */
  private async findNearbyDrivers(lat: number, lng: number, radiusKm: number): Promise<any[]> {
    // Redis GEO kullanarak hızlı arama
    const nearbyIds = await this.redis.geoRadius('drivers:locations', lng, lat, radiusKm);

    if (nearbyIds.length === 0) {
      return [];
    }

    const drivers = await this.prisma.driver.findMany({
      where: {
        id: { in: nearbyIds },
        isOnline: true,
        isApproved: true,
        dailyCancel: { lt: this.MAX_DAILY_CANCELS },
      },
      orderBy: [
        { rating: 'desc' },
        { totalRides: 'desc' },
      ],
    });

    return drivers;
  }

  /**
   * Her 5 saniyede bir bekleyen çağrıları kontrol et
   */
  @Cron('*/5 * * * * *')
  async checkPendingCalls(): Promise<void> {
    // 30 saniyeyi geçmiş SEARCHING durumundaki yolculukları bul
    const pendingRides = await this.prisma.taxiRide.findMany({
      where: {
        status: RideStatus.SEARCHING,
        createdAt: {
          lte: new Date(Date.now() - 25000), // 25+ saniye
        },
      },
      include: {
        calls: {
          where: { status: 'PENDING' },
          orderBy: { sentAt: 'desc' },
        },
      },
    });

    for (const ride of pendingRides) {
      await this.handlePendingRide(ride);
    }
  }

  /**
   * Bekleyen çağrıyı işle
   */
  private async handlePendingRide(ride: any): Promise<void> {
    const pendingCall = ride.calls[0];
    if (!pendingCall) return;

    const elapsed = Date.now() - new Date(pendingCall.sentAt).getTime();

    if (elapsed >= 30000) {
      // Mevcut çağrıyı timeout yap
      await this.prisma.rideCall.update({
        where: { id: pendingCall.id },
        data: { status: 'TIMEOUT' },
      });

      // Şoförün günlük iptal sayısını artır
      await this.prisma.driver.update({
        where: { id: pendingCall.driverId },
        data: { dailyCancel: { increment: 1 } },
      });

      // Başka şoför ara
      const attemptedDriverIds = ride.calls.map((c: any) => c.driverId);
      const nextDriver = await this.findNextDriver(
        ride.pickupLat,
        ride.pickupLng,
        attemptedDriverIds,
      );

      if (nextDriver) {
        await this.sendRideCallToDriver(ride.id, nextDriver.id);
        this.logger.log(`Ride ${ride.id} forwarded to next driver`);
      } else {
        // Şoför bulunamadı
        await this.prisma.taxiRide.update({
          where: { id: ride.id },
          data: { status: RideStatus.NO_DRIVER },
        });

        await this.notifications.sendPush({
          userId: ride.userId,
          title: 'Taksi Bulunamadı',
          body: 'Üzgünüz, müsait taksi bulunamadı. Lütfen tekrar deneyin.',
          data: { type: 'NO_DRIVER', rideId: ride.id },
        });
      }
    }
  }

  /**
   * Daha önce denenmemiş sonraki şoförü bul
   */
  private async findNextDriver(lat: number, lng: number, excludeIds: string[]): Promise<any | null> {
    const nearbyIds = await this.redis.geoRadius('drivers:locations', lng, lat, 5);

    const drivers = await this.prisma.driver.findMany({
      where: {
        id: { in: nearbyIds, notIn: excludeIds },
        isOnline: true,
        isApproved: true,
        dailyCancel: { lt: this.MAX_DAILY_CANCELS },
      },
      orderBy: { rating: 'desc' },
      take: 1,
    });

    return drivers[0] || null;
  }

  /**
   * Kabul sonrası hareket kontrolü (60 sn)
   */
  @Cron('*/10 * * * * *')
  async checkAcceptedRidesMovement(): Promise<void> {
    const acceptedRides = await this.prisma.taxiRide.findMany({
      where: {
        status: RideStatus.DRIVER_ACCEPTED,
        updatedAt: {
          lte: new Date(Date.now() - 55000), // 55+ saniye
        },
      },
      include: { driver: true },
    });

    for (const ride of acceptedRides) {
      if (!ride.driver) continue;

      // Son konum güncellemesini kontrol et
      const lastLocationUpdate = ride.driver.lastLocation;
      
      if (!lastLocationUpdate || Date.now() - new Date(lastLocationUpdate).getTime() > 60000) {
        // 60 saniyedir hareket yok - iptal
        await this.prisma.taxiRide.update({
          where: { id: ride.id },
          data: { status: RideStatus.CANCELLED },
        });

        await this.prisma.rideTimeline.create({
          data: {
            rideId: ride.id,
            status: RideStatus.CANCELLED,
          },
        });

        // Şoförü offline yap
        await this.prisma.driver.update({
          where: { id: ride.driverId! },
          data: { isOnline: false },
        });

        // Kullanıcıya bildirim
        await this.notifications.sendPush({
          userId: ride.userId,
          title: 'Yolculuk İptal Edildi',
          body: 'Şoför harekete geçmedi. Yeni taksi arayabilirsiniz.',
          data: { type: 'RIDE_CANCELLED', rideId: ride.id },
        });

        this.logger.log(`Ride ${ride.id} cancelled due to driver inactivity`);
      }
    }
  }

  /**
   * Her gece yarısı: Günlük iptal sayaçlarını sıfırla
   */
  @Cron('0 0 * * *')
  async resetDailyCancels(): Promise<void> {
    await this.prisma.driver.updateMany({
      data: { dailyCancel: 0 },
    });

    this.logger.log('Daily cancel counts reset');
  }

  /**
   * Her saat: 24 saattir pasif şoförleri devre dışı bırak
   */
  @Cron('0 * * * *')
  async checkInactiveDrivers(): Promise<void> {
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const inactiveDrivers = await this.prisma.driver.findMany({
      where: {
        isOnline: true,
        lastLocation: { lt: oneDayAgo },
      },
      include: { user: true },
    });

    for (const driver of inactiveDrivers) {
      await this.prisma.driver.update({
        where: { id: driver.id },
        data: { isOnline: false },
      });

      await this.notifications.sendPush({
        userId: driver.userId,
        title: 'Hesabınız Pasife Alındı',
        body: '24 saattir aktif değilsiniz. Tekrar çağrı almak için uygulamadan online olun.',
        data: { type: 'DRIVER_DEACTIVATED', driverId: driver.id },
      });
    }

    this.logger.log(`Deactivated ${inactiveDrivers.length} inactive drivers`);
  }
}
