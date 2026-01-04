import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { RedisService } from '../../common/redis/redis.service';
import { TaxiAutomationService } from './taxi-automation.service';
import { RideStatus } from '@prisma/client';

@Injectable()
export class TaxiService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private automation: TaxiAutomationService,
  ) {}

  async estimate(pickupLat: number, pickupLng: number, dropLat: number, dropLng: number) {
    // Mesafe hesaplama (basit Haversine formula)
    const R = 6371; // km
    const dLat = (dropLat - pickupLat) * Math.PI / 180;
    const dLng = (dropLng - pickupLng) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(pickupLat * Math.PI / 180) * Math.cos(dropLat * Math.PI / 180) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;

    // Tahmini süre ve ücret
    const duration = Math.ceil(distance * 3); // dakika
    const baseFare = 15;
    const perKmFare = 12;
    const fare = baseFare + (distance * perKmFare);

    // Yakındaki şoför sayısı
    const nearbyDrivers = await this.redis.geoRadius('drivers:locations', pickupLng, pickupLat, 3);

    return {
      distance: Math.round(distance * 10) / 10,
      duration,
      estimatedFare: { min: Math.floor(fare * 0.9), max: Math.ceil(fare * 1.1) },
      nearbyDrivers: nearbyDrivers.length,
    };
  }

  async requestRide(userId: string, data: { pickupLat: number; pickupLng: number; pickupAddress: string; dropLat: number; dropLng: number; dropAddress: string }) {
    const estimate = await this.estimate(data.pickupLat, data.pickupLng, data.dropLat, data.dropLng);

    const ride = await this.prisma.taxiRide.create({
      data: {
        userId,
        pickupLat: data.pickupLat,
        pickupLng: data.pickupLng,
        pickupAddress: data.pickupAddress,
        dropLat: data.dropLat,
        dropLng: data.dropLng,
        dropAddress: data.dropAddress,
        estDistance: estimate.distance,
        estDuration: estimate.duration,
        estFare: (estimate.estimatedFare.min + estimate.estimatedFare.max) / 2,
        status: RideStatus.SEARCHING,
      },
    });

    // Şoför arama başlat
    await this.automation.startRideSearch(ride.id);

    return ride;
  }

  async findByUser(userId: string) {
    return this.prisma.taxiRide.findMany({
      where: { userId },
      include: { driver: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string) {
    return this.prisma.taxiRide.findUnique({
      where: { id },
      include: { driver: { include: { user: true } }, timeline: true },
    });
  }

  async respondToCall(driverId: string, rideId: string, accept: boolean) {
    const call = await this.prisma.rideCall.findFirst({
      where: { rideId, driverId, status: 'PENDING' },
    });

    if (!call) return { success: false, message: 'Çağrı bulunamadı veya zaten yanıtlandı' };

    if (accept) {
      await this.prisma.rideCall.update({ where: { id: call.id }, data: { status: 'ACCEPTED', respondedAt: new Date() } });
      await this.prisma.taxiRide.update({ where: { id: rideId }, data: { driverId, status: RideStatus.DRIVER_ACCEPTED } });
      await this.prisma.rideTimeline.create({ data: { rideId, status: RideStatus.DRIVER_ACCEPTED } });
    } else {
      await this.prisma.rideCall.update({ where: { id: call.id }, data: { status: 'REJECTED', respondedAt: new Date() } });
    }

    return { success: true };
  }

  async updateDriverStatus(userId: string, isOnline: boolean, lat?: number, lng?: number) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) return { success: false };

    await this.prisma.driver.update({
      where: { id: driver.id },
      data: { isOnline, latitude: lat, longitude: lng, lastLocation: new Date() },
    });

    if (isOnline && lat && lng) {
      await this.redis.geoAdd('drivers:locations', lng, lat, driver.id);
    } else {
      await this.redis.geoRemove('drivers:locations', driver.id);
    }

    return { success: true };
  }

  async updateBusyStatus(userId: string, isBusy: boolean) {
    const driver = await this.prisma.driver.findFirst({ where: { userId } });
    if (!driver) throw new Error('Driver not found');

    return this.prisma.driver.update({
      where: { id: driver.id },
      data: { isBusy }
    });
  }

  async toggleRestMode(userId: string, durationMinutes: number) {
    const driver = await this.prisma.driver.findFirst({ where: { userId } });
    if (!driver) throw new Error('Driver not found');

    const restModeEndsAt = durationMinutes > 0 
      ? new Date(Date.now() + durationMinutes * 60000) 
      : null;

    return this.prisma.driver.update({
      where: { id: driver.id },
      data: { restModeEndsAt, isBusy: durationMinutes > 0 } // Moladaysa meşgul yap
    });
  }

  async getNearbyDrivers(lat: number, lng: number, radiusKm = 3) {
    const driverIds = await this.redis.geoRadius('drivers:locations', lng, lat, radiusKm);
    
    if (driverIds.length === 0) return [];

    const drivers = await this.prisma.driver.findMany({
      where: { id: { in: driverIds }, isOnline: true, isApproved: true },
      select: { id: true, latitude: true, longitude: true },
    });

    return drivers;
  }
}
