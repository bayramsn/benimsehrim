import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class StoresService {
  constructor(private prisma: PrismaService) {}

  async findAll(params: { cityId?: string; categoryId?: string; isOpen?: boolean; page?: number; limit?: number }) {
    const { cityId, categoryId, isOpen, page = 1, limit = 20 } = params;
    
    const where: any = { isApproved: true };
    if (cityId) where.cityId = cityId;
    if (isOpen !== undefined) where.isOpen = isOpen;
    if (categoryId) where.categories = { some: { id: categoryId } };

    const [stores, total] = await Promise.all([
      this.prisma.store.findMany({
        where,
        include: { categories: true },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { rating: 'desc' },
      }),
      this.prisma.store.count({ where }),
    ]);

    return { data: stores, meta: { total, page, limit } };
  }

  async findById(id: string) {
    return this.prisma.store.findUnique({
      where: { id },
      include: { categories: true, products: { where: { isActive: true } }, campaigns: { where: { isActive: true } } },
    });
  }

  async create(userId: string, data: any) {
    return this.prisma.store.create({ data: { userId, ...data } });
  }

  async update(id: string, userId: string, data: any) {
    return this.prisma.store.updateMany({ where: { id, userId }, data });
  }

  async setOpenStatus(id: string, userId: string, isOpen: boolean) {
    return this.prisma.store.updateMany({ where: { id, userId }, data: { isOpen } });
  }

  async getMyStore(userId: string) {
    return this.prisma.store.findFirst({
      where: { userId },
      include: { categories: true }
    });
  }

  async updateBusyStatus(id: string, userId: string, isBusy: boolean) {
    // Stores tablosunda isBusy alanını güncelle
    // Not: Veritabanı şeması güncellenmediyse bu alan olmayabilir, kontrol edilmeli.
    // Şema güncellemesi yapıldığı varsayılıyor.
    return this.prisma.store.update({ // updateMany yerine update kullanıp relation dönelim
      where: { id },
      data: { isBusy } // Şemada isBusy varsa
    });
  }

  async getDashboardStats(userId: string) {
    const store = await this.prisma.store.findFirst({ where: { userId } });
    if (!store) return null;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [todayOrdersCount, todayRevenueAgg, pendingOrdersCount, recentOrders] = await Promise.all([
      // Today's Orders Count
      this.prisma.order.count({
        where: {
          storeId: store.id,
          createdAt: { gte: today }
        }
      }),
      // Today's Revenue
      this.prisma.order.aggregate({
        where: {
          storeId: store.id,
          createdAt: { gte: today },
          status: { not: 'CANCELLED' } 
        },
        _sum: { total: true }
      }),
      // Pending Orders
      this.prisma.order.count({
        where: {
          storeId: store.id,
          status: 'PENDING'
        }
      }),
      // Recent Orders (Last 5)
      this.prisma.order.findMany({
        where: { storeId: store.id },
        orderBy: { createdAt: 'desc' },
        take: 5,
        include: { user: { select: { name: true } } }
      })
    ]);

    return {
      storeId: store.id,
      storeName: store.name,
      isOpen: store.isOpen,
      isBusy: store.isBusy, // Yeni alan
      usageScore: store.usageScore, // Yeni alan
      todayOrders: todayOrdersCount,
      todayRevenue: todayRevenueAgg._sum.total || 0,
      pendingOrders: pendingOrdersCount,
      recentOrders: recentOrders.map(o => ({
        id: o.id,
        orderNo: o.orderNo,
        customerName: o.user.name,
        total: o.total,
        status: o.status,
        createdAt: o.createdAt
      }))
    };
  }
}

