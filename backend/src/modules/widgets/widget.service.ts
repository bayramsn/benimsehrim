import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

export interface WidgetData {
  type: 'order_tracking' | 'quick_reorder' | 'daily_deals' | 'nearby_stores' | 'points_balance';
  data: any;
  updatedAt: Date;
}

export interface OrderTrackingWidget {
  hasActiveOrder: boolean;
  order?: {
    id: string;
    orderNo: string;
    storeName: string;
    status: string;
    statusText: string;
    estimatedTime?: string;
    progress: number; // 0-100
  };
}

export interface QuickReorderWidget {
  recentOrders: {
    id: string;
    storeName: string;
    itemCount: number;
    total: number;
    thumbnail?: string;
  }[];
}

export interface DailyDealsWidget {
  deals: {
    id: string;
    productName: string;
    originalPrice: number;
    discountedPrice: number;
    discountPercentage: number;
    storeName: string;
    expiresIn: string;
  }[];
}

export interface PointsBalanceWidget {
  points: number;
  cashValue: number;
  nextReward?: {
    name: string;
    pointsNeeded: number;
  };
}

@Injectable()
export class WidgetService {
  private readonly logger = new Logger(WidgetService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Kullanıcı için tüm widget verilerini getir
   */
  async getAllWidgets(userId: string): Promise<WidgetData[]> {
    const [orderTracking, quickReorder, dailyDeals, pointsBalance] = await Promise.all([
      this.getOrderTrackingWidget(userId),
      this.getQuickReorderWidget(userId),
      this.getDailyDealsWidget(userId),
      this.getPointsBalanceWidget(userId),
    ]);

    return [
      { type: 'order_tracking', data: orderTracking, updatedAt: new Date() },
      { type: 'quick_reorder', data: quickReorder, updatedAt: new Date() },
      { type: 'daily_deals', data: dailyDeals, updatedAt: new Date() },
      { type: 'points_balance', data: pointsBalance, updatedAt: new Date() },
    ];
  }

  /**
   * Sipariş takip widget'ı
   */
  async getOrderTrackingWidget(userId: string): Promise<OrderTrackingWidget> {
    const activeOrder = await this.prisma.order.findFirst({
      where: {
        userId,
        status: { notIn: ['DELIVERED', 'CANCELLED'] },
      },
      include: { store: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    });

    if (!activeOrder) {
      return { hasActiveOrder: false };
    }

    const statusProgress: Record<string, { text: string; progress: number }> = {
      PENDING: { text: 'Onay Bekleniyor', progress: 10 },
      ACCEPTED: { text: 'Hazırlanıyor', progress: 30 },
      PREPARING: { text: 'Hazırlanıyor', progress: 50 },
      READY: { text: 'Kurye Bekliyor', progress: 70 },
      ON_THE_WAY: { text: 'Yolda', progress: 90 },
    };

    const statusInfo = statusProgress[activeOrder.status] || { text: activeOrder.status, progress: 0 };

    return {
      hasActiveOrder: true,
      order: {
        id: activeOrder.id,
        orderNo: activeOrder.orderNo,
        storeName: activeOrder.store.name,
        status: activeOrder.status,
        statusText: statusInfo.text,
        progress: statusInfo.progress,
        estimatedTime: this.calculateETA(activeOrder.status),
      },
    };
  }

  /**
   * Hızlı tekrar sipariş widget'ı
   */
  async getQuickReorderWidget(userId: string): Promise<QuickReorderWidget> {
    const recentOrders = await this.prisma.order.findMany({
      where: { userId, status: 'DELIVERED' },
      include: {
        store: { select: { name: true } },
        items: { select: { id: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 3,
    });

    return {
      recentOrders: recentOrders.map(order => ({
        id: order.id,
        storeName: order.store.name,
        itemCount: order.items.length,
        total: order.total,
      })),
    };
  }

  /**
   * Günlük fırsatlar widget'ı
   */
  async getDailyDealsWidget(userId: string): Promise<DailyDealsWidget> {
    const now = new Date();

    const campaigns = await this.prisma.campaign.findMany({
      where: {
        isActive: true,
        startDate: { lte: now },
        endDate: { gte: now },
        type: 'PERCENTAGE',
      },
      include: {
        store: { select: { name: true } },
        product: { select: { name: true, price: true } },
      },
      take: 5,
    });

    return {
      deals: campaigns.map(campaign => {
        const product = campaign.product;
        const discountPercentage = campaign.value || 0;
        const originalPrice = product?.price || 0;
        const discountedPrice = originalPrice * (1 - discountPercentage / 100);

        return {
          id: campaign.id,
          productName: product?.name || 'Kampanya',
          originalPrice,
          discountedPrice: Math.round(discountedPrice * 100) / 100,
          discountPercentage,
          storeName: campaign.store.name,
          expiresIn: this.getTimeRemaining(campaign.endDate),
        };
      }),
    };
  }

  /**
   * Puan bakiyesi widget'ı
   */
  async getPointsBalanceWidget(userId: string): Promise<PointsBalanceWidget> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { points: true },
    });

    const points = user?.points || 0;
    const cashValue = points / 100; // 100 puan = 1₺

    // Next reward calculation
    const rewardTiers = [
      { name: '5₺ İndirim', points: 500 },
      { name: '10₺ İndirim', points: 1000 },
      { name: 'Ücretsiz Teslimat', points: 1500 },
      { name: '25₺ İndirim', points: 2500 },
    ];

    const nextReward = rewardTiers.find(r => r.points > points);

    return {
      points,
      cashValue,
      nextReward: nextReward ? {
        name: nextReward.name,
        pointsNeeded: nextReward.points - points,
      } : undefined,
    };
  }

  /**
   * Yakındaki mağazalar widget'ı
   */
  async getNearbyStoresWidget(
    latitude: number,
    longitude: number,
    limit = 5
  ): Promise<{ stores: { id: string; name: string; distance: string; isOpen: boolean }[] }> {
    // Simple query - in production would use PostGIS
    const stores = await this.prisma.store.findMany({
      where: { isApproved: true },
      select: {
        id: true,
        name: true,
        isOpen: true,
        latitude: true,
        longitude: true,
      },
      take: limit * 2, // Get extra to filter by distance
    });

    // Calculate distances and sort
    const withDistance = stores
      .map(store => ({
        ...store,
        distance: this.calculateDistance(
          latitude, longitude,
          store.latitude || 0, store.longitude || 0
        ),
      }))
      .sort((a, b) => a.distance - b.distance)
      .slice(0, limit);

    return {
      stores: withDistance.map(store => ({
        id: store.id,
        name: store.name,
        distance: store.distance < 1 ? `${Math.round(store.distance * 1000)}m` : `${store.distance.toFixed(1)}km`,
        isOpen: store.isOpen,
      })),
    };
  }

  private calculateETA(status: string): string {
    switch (status) {
      case 'PENDING':
        return '30-45 dk';
      case 'ACCEPTED':
      case 'PREPARING':
        return '20-35 dk';
      case 'READY':
        return '15-25 dk';
      case 'ON_THE_WAY':
        return '5-15 dk';
      default:
        return '';
    }
  }

  private getTimeRemaining(endDate: Date): string {
    const remaining = endDate.getTime() - Date.now();
    const hours = Math.floor(remaining / (1000 * 60 * 60));
    
    if (hours < 1) {
      const minutes = Math.floor(remaining / (1000 * 60));
      return `${minutes} dk`;
    }
    if (hours < 24) {
      return `${hours} saat`;
    }
    const days = Math.floor(hours / 24);
    return `${days} gün`;
  }

  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // km
    const dLat = this.toRad(lat2 - lat1);
    const dLon = this.toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) * Math.cos(this.toRad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRad(deg: number): number {
    return deg * (Math.PI / 180);
  }
}
