import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { OrderStatus, RideStatus } from '@prisma/client';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  async getCrisisLogs() {
    return this.prisma.crisisLog.findMany({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' }
    });
  }

  async resolveCrisisLog(id: string) {
    return this.prisma.crisisLog.update({
      where: { id },
      data: { isActive: false, resolvedAt: new Date() }
    });
  }

  async getDashboard() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      todayOrders,
      todayRides,
      todayRevenue,
      newUsers,
      pendingStores,
      pendingDrivers,
      pendingCouriers,
      lowRatedVendors,
      highCancelDrivers,
      activeCrisis // New
    ] = await Promise.all([
      this.prisma.order.count({ where: { createdAt: { gte: today } } }),
      this.prisma.taxiRide.count({ where: { createdAt: { gte: today } } }),
      this.prisma.order.aggregate({ where: { createdAt: { gte: today }, status: OrderStatus.DELIVERED }, _sum: { total: true } }),
      this.prisma.user.count({ where: { createdAt: { gte: today } } }),
      this.prisma.store.count({ where: { isApproved: false } }),
      this.prisma.driver.count({ where: { isApproved: false } }),
      this.prisma.courier.count({ where: { isApproved: false } }),
      this.prisma.store.count({ where: { rating: { lt: 3 } } }),
      this.prisma.driver.count({ where: { dailyCancel: { gte: 3 } } }),
      this.prisma.crisisLog.count({ where: { isActive: true } }) // New
    ]);

    const pendingApprovals = pendingStores + pendingDrivers + pendingCouriers;

    return {
      today: {
        orders: todayOrders,
        rides: todayRides,
        revenue: todayRevenue._sum.total || 0,
        newUsers,
      },
      alerts: {
        pendingApprovals,
        lowRatedVendors,
        highCancelDrivers,
        activeCrisis // Expose
      },
    };
  }


  async getVendors(status?: 'pending' | 'approved' | 'rejected') {
    const where: any = {};
    if (status === 'pending') where.isApproved = false;
    if (status === 'approved') where.isApproved = true;

    return this.prisma.store.findMany({
      where,
      include: { user: { select: { name: true, phone: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async approveVendor(storeId: string, approve: boolean) {
    return this.prisma.store.update({ where: { id: storeId }, data: { isApproved: approve } });
  }

  async getDrivers(status?: 'pending' | 'approved') {
    const where: any = {};
    if (status === 'pending') where.isApproved = false;
    if (status === 'approved') where.isApproved = true;

    return this.prisma.driver.findMany({
      where,
      include: { user: { select: { name: true, phone: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async approveDriver(driverId: string, approve: boolean) {
    return this.prisma.driver.update({ where: { id: driverId }, data: { isApproved: approve } });
  }

  async getCouriers(status?: 'pending' | 'approved') {
    const where: any = {};
    if (status === 'pending') where.isApproved = false;
    if (status === 'approved') where.isApproved = true;

    return this.prisma.courier.findMany({
      where,
      include: { user: { select: { name: true, phone: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async approveCourier(courierId: string, approve: boolean) {
    return this.prisma.courier.update({ where: { id: courierId }, data: { isApproved: approve } });
  }

  async getPendingReviews() {
    return this.prisma.review.findMany({
      where: { isApproved: false },
      include: { user: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getOperationStats() {
    const [topMissedOrders, topCancelDrivers, lateDeliveries] = await Promise.all([
      // En çok sipariş kaçıran esnaflar
      this.prisma.order.groupBy({
        by: ['storeId'],
        where: { status: OrderStatus.CANCELLED },
        _count: true,
        orderBy: { _count: { storeId: 'desc' } },
        take: 10,
      }),
      // En çok çağrı reddeden şoförler
      this.prisma.driver.findMany({
        where: { dailyCancel: { gt: 0 } },
        orderBy: { dailyCancel: 'desc' },
        take: 10,
        include: { user: { select: { name: true } } },
      }),
      // Geciken teslimatlar
      this.prisma.delivery.findMany({
        where: { status: { notIn: ['DELIVERED', 'CANCELLED'] }, createdAt: { lt: new Date(Date.now() - 60 * 60 * 1000) } },
        include: { courier: { include: { user: { select: { name: true } } } } },
      }),
    ]);

    return { topMissedOrders, topCancelDrivers, lateDeliveries };
  }
}
