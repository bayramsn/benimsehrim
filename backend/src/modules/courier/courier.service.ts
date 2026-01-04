import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { RedisService } from '../../common/redis/redis.service';
import { DeliveryStatus } from '@prisma/client';

@Injectable()
export class CourierService {
  constructor(private prisma: PrismaService, private redis: RedisService) {}

  async getDeliveries(userId: string) {
    const courier = await this.prisma.courier.findUnique({ where: { userId } });
    if (!courier) return [];

    return this.prisma.delivery.findMany({
      where: { courierId: courier.id, status: { in: [DeliveryStatus.ASSIGNED, DeliveryStatus.ACCEPTED, DeliveryStatus.PICKED_UP, DeliveryStatus.ARRIVING] } },
      include: { order: { include: { store: true, items: { include: { product: true } } } } },
      orderBy: { createdAt: 'asc' },
    });
  }

  async updateDeliveryStatus(userId: string, deliveryId: string, status: DeliveryStatus, lat?: number, lng?: number) {
    const courier = await this.prisma.courier.findUnique({ where: { userId } });
    if (!courier) return { success: false };

    await this.prisma.delivery.updateMany({
      where: { id: deliveryId, courierId: courier.id },
      data: {
        status,
        ...(status === DeliveryStatus.PICKED_UP && { pickedAt: new Date() }),
        ...(status === DeliveryStatus.ARRIVING && { arrivedAt: new Date() }),
        ...(status === DeliveryStatus.DELIVERED && { deliveredAt: new Date() }),
      },
    });

    await this.prisma.deliveryTimeline.create({
      data: { deliveryId, status, latitude: lat, longitude: lng },
    });

    return { success: true };
  }

  async updateLocation(userId: string, lat: number, lng: number) {
    const courier = await this.prisma.courier.findUnique({ where: { userId } });
    if (!courier) return { success: false };

    await this.prisma.courier.update({
      where: { id: courier.id },
      data: { latitude: lat, longitude: lng, lastLocation: new Date() },
    });

    await this.redis.geoAdd('couriers:locations', lng, lat, courier.id);

    return { success: true };
  }

  async updateStatus(userId: string, isOnline: boolean) {
    const courier = await this.prisma.courier.findUnique({ where: { userId } });
    if (!courier) return { success: false };

    await this.prisma.courier.update({ where: { id: courier.id }, data: { isOnline } });

    if (!isOnline) {
      await this.redis.geoRemove('couriers:locations', courier.id);
    }

    return { success: true };
  }
}
