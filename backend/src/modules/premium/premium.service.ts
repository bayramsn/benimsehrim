import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

export interface PremiumPlan {
  id: string;
  name: string;
  price: number;
  duration: number; // days
  features: string[];
}

export interface PremiumStatus {
  isPremium: boolean;
  plan?: string;
  expiresAt?: Date;
  features: string[];
  daysRemaining?: number;
}

export const PREMIUM_PLANS: PremiumPlan[] = [
  {
    id: 'monthly',
    name: 'ŞehrimPLUS Aylık',
    price: 29.99,
    duration: 30,
    features: [
      'unlimited_delivery', // Sınırsız ücretsiz teslimat
      'priority_support',   // Öncelikli destek
      'early_access',       // Kampanyalara erken erişim
      'chatbot_access',     // AI Chatbot erişimi
      'exclusive_deals',    // Özel indirimler
      'no_min_order',       // Minimum sipariş yok
    ],
  },
  {
    id: 'yearly',
    name: 'ŞehrimPLUS Yıllık',
    price: 249.99, // 2 ay bedava
    duration: 365,
    features: [
      'unlimited_delivery',
      'priority_support',
      'early_access',
      'chatbot_access',
      'exclusive_deals',
      'no_min_order',
      'cashback_5',         // %5 cashback
      'vip_badge',          // VIP rozeti
    ],
  },
];

@Injectable()
export class PremiumService {
  private readonly logger = new Logger(PremiumService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Kullanıcının premium durumunu kontrol et
   */
  async getPremiumStatus(userId: string): Promise<PremiumStatus> {
    const subscription = await this.prisma.premiumSubscription.findFirst({
      where: {
        userId,
        status: 'ACTIVE',
        expiresAt: { gt: new Date() },
      },
    });

    if (!subscription) {
      return {
        isPremium: false,
        features: [],
      };
    }

    const plan = PREMIUM_PLANS.find(p => p.id === subscription.planId);
    const daysRemaining = Math.ceil(
      (subscription.expiresAt.getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );

    return {
      isPremium: true,
      plan: plan?.name || subscription.planId,
      expiresAt: subscription.expiresAt,
      features: plan?.features || [],
      daysRemaining,
    };
  }

  /**
   * Premium özelliğe erişim kontrolü
   */
  async hasFeature(userId: string, feature: string): Promise<boolean> {
    const status = await this.getPremiumStatus(userId);
    return status.features.includes(feature);
  }

  /**
   * Premium üyelik satın al
   */
  async subscribe(
    userId: string,
    planId: string,
    paymentMethod: string
  ): Promise<{ success: boolean; message: string; expiresAt?: Date }> {
    const plan = PREMIUM_PLANS.find(p => p.id === planId);
    if (!plan) {
      return { success: false, message: 'Geçersiz plan' };
    }

    // Check existing subscription
    const existing = await this.prisma.premiumSubscription.findFirst({
      where: { userId, status: 'ACTIVE', expiresAt: { gt: new Date() } },
    });

    const startDate = existing?.expiresAt || new Date();
    const expiresAt = new Date(startDate);
    expiresAt.setDate(expiresAt.getDate() + plan.duration);

    // Create or extend subscription
    await this.prisma.premiumSubscription.create({
      data: {
        userId,
        planId,
        price: plan.price,
        status: 'ACTIVE',
        paymentMethod,
        startedAt: new Date(),
        expiresAt,
      },
    });

    // Add premium badge
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        badges: {
          push: 'premium_member',
        },
      },
    });

    this.logger.log(`Premium subscription: ${userId} -> ${planId}`);

    return {
      success: true,
      message: `ŞehrimPLUS başarıyla aktifleştirildi!`,
      expiresAt,
    };
  }

  /**
   * Üyelik iptali
   */
  async cancel(userId: string): Promise<{ success: boolean; message: string }> {
    const subscription = await this.prisma.premiumSubscription.findFirst({
      where: { userId, status: 'ACTIVE' },
    });

    if (!subscription) {
      return { success: false, message: 'Aktif üyelik bulunamadı' };
    }

    await this.prisma.premiumSubscription.update({
      where: { id: subscription.id },
      data: { status: 'CANCELLED' },
    });

    return {
      success: true,
      message: `Üyeliğiniz ${subscription.expiresAt.toLocaleDateString('tr-TR')} tarihine kadar aktif kalacak.`,
    };
  }

  /**
   * Teslimat ücreti hesapla (premium için 0)
   */
  async calculateDeliveryFee(userId: string, baseFee: number): Promise<number> {
    const hasFreeDelivery = await this.hasFeature(userId, 'unlimited_delivery');
    return hasFreeDelivery ? 0 : baseFee;
  }

  /**
   * Erken erişim kampanyalarını getir
   */
  async getEarlyAccessCampaigns(userId: string): Promise<any[]> {
    const hasEarlyAccess = await this.hasFeature(userId, 'early_access');
    
    if (!hasEarlyAccess) {
      return [];
    }

    // Campaigns starting in next 24 hours
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);

    return this.prisma.campaign.findMany({
      where: {
        startDate: { gt: new Date(), lt: tomorrow },
        isActive: true,
      },
      include: {
        store: { select: { name: true } },
      },
    });
  }

  /**
   * Tüm planları listele
   */
  getPlans(): PremiumPlan[] {
    return PREMIUM_PLANS;
  }
}
