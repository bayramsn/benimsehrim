import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

export interface DynamicPrice {
  originalPrice: number;
  currentPrice: number;
  discount: number;
  discountPercentage: number;
  reason?: string;
  validUntil?: Date;
}

export interface PricingRule {
  id: string;
  type: 'TIME_BASED' | 'DEMAND_BASED' | 'WEATHER_BASED' | 'STOCK_BASED' | 'LOYALTY';
  name: string;
  discountPercentage: number;
  conditions: any;
  isActive: boolean;
}

@Injectable()
export class DynamicPricingService {
  private readonly logger = new Logger(DynamicPricingService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Ürün için dinamik fiyat hesapla
   */
  async calculatePrice(
    productId: string,
    userId?: string,
    options: { quantity?: number; date?: Date } = {}
  ): Promise<DynamicPrice> {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      include: { store: { select: { id: true } } },
    });

    if (!product) {
      throw new Error('Ürün bulunamadı');
    }

    const originalPrice = product.price;
    let discount = 0;
    let reason: string | undefined;

    // Apply pricing rules
    const rules = await this.getApplicableRules(product, userId, options);

    for (const rule of rules) {
      const ruleDiscount = await this.evaluateRule(rule, product, userId, options);
      if (ruleDiscount > discount) {
        discount = ruleDiscount;
        reason = rule.name;
      }
    }

    const currentPrice = Math.round(originalPrice * (1 - discount / 100) * 100) / 100;

    return {
      originalPrice,
      currentPrice,
      discount: originalPrice - currentPrice,
      discountPercentage: discount,
      reason,
    };
  }

  /**
   * Saat bazlı fiyatlandırma kuralı oluştur
   */
  async createTimeRule(
    storeId: string,
    data: {
      name: string;
      startHour: number;
      endHour: number;
      discountPercentage: number;
      daysOfWeek?: number[]; // 0=Sunday, 1=Monday, etc.
    }
  ): Promise<PricingRule> {
    const rule = await this.prisma.pricingRule.create({
      data: {
        storeId,
        type: 'TIME_BASED',
        name: data.name,
        discountPercentage: data.discountPercentage,
        conditions: {
          startHour: data.startHour,
          endHour: data.endHour,
          daysOfWeek: data.daysOfWeek || [0, 1, 2, 3, 4, 5, 6],
        },
        isActive: true,
      },
    });

    return this.mapRule(rule);
  }

  /**
   * Talep bazlı fiyatlandırma kuralı
   * Yoğun saatlerde fiyat artışı veya sakin saatlerde indirim
   */
  async createDemandRule(
    storeId: string,
    data: {
      name: string;
      lowDemandDiscount: number;  // Düşük talepte indirim
      highDemandSurcharge: number; // Yüksek talepte ek ücret
      demandThresholdLow: number;  // Saatlik sipariş eşiği
      demandThresholdHigh: number;
    }
  ): Promise<PricingRule> {
    const rule = await this.prisma.pricingRule.create({
      data: {
        storeId,
        type: 'DEMAND_BASED',
        name: data.name,
        discountPercentage: data.lowDemandDiscount,
        conditions: {
          lowDemandDiscount: data.lowDemandDiscount,
          highDemandSurcharge: data.highDemandSurcharge,
          demandThresholdLow: data.demandThresholdLow,
          demandThresholdHigh: data.demandThresholdHigh,
        },
        isActive: true,
      },
    });

    return this.mapRule(rule);
  }

  /**
   * Stok bazlı fiyatlandırma (son ürünler için indirim)
   */
  async createStockRule(
    storeId: string,
    data: {
      name: string;
      lowStockThreshold: number;
      discountPercentage: number;
    }
  ): Promise<PricingRule> {
    const rule = await this.prisma.pricingRule.create({
      data: {
        storeId,
        type: 'STOCK_BASED',
        name: data.name,
        discountPercentage: data.discountPercentage,
        conditions: {
          lowStockThreshold: data.lowStockThreshold,
        },
        isActive: true,
      },
    });

    return this.mapRule(rule);
  }

  /**
   * Sadakat bazlı fiyatlandırma (VIP müşterilere özel)
   */
  async createLoyaltyRule(
    storeId: string,
    data: {
      name: string;
      minOrders: number;
      discountPercentage: number;
    }
  ): Promise<PricingRule> {
    const rule = await this.prisma.pricingRule.create({
      data: {
        storeId,
        type: 'LOYALTY',
        name: data.name,
        discountPercentage: data.discountPercentage,
        conditions: {
          minOrders: data.minOrders,
        },
        isActive: true,
      },
    });

    return this.mapRule(rule);
  }

  /**
   * Mevcut talebi hesapla
   */
  async getCurrentDemand(storeId: string): Promise<{
    level: 'low' | 'normal' | 'high';
    ordersLastHour: number;
  }> {
    const oneHourAgo = new Date();
    oneHourAgo.setHours(oneHourAgo.getHours() - 1);

    const ordersLastHour = await this.prisma.order.count({
      where: {
        storeId,
        createdAt: { gte: oneHourAgo },
      },
    });

    // Simple heuristic: <5 low, 5-20 normal, >20 high
    let level: 'low' | 'normal' | 'high' = 'normal';
    if (ordersLastHour < 5) level = 'low';
    else if (ordersLastHour > 20) level = 'high';

    return { level, ordersLastHour };
  }

  /**
   * Mağazanın fiyatlandırma kurallarını getir
   */
  async getStoreRules(storeId: string): Promise<PricingRule[]> {
    const rules = await this.prisma.pricingRule.findMany({
      where: { storeId },
      orderBy: { createdAt: 'desc' },
    });

    return rules.map(this.mapRule);
  }

  /**
   * Kuralı aktif/pasif yap
   */
  async toggleRule(ruleId: string, storeId: string, isActive: boolean): Promise<boolean> {
    const result = await this.prisma.pricingRule.updateMany({
      where: { id: ruleId, storeId },
      data: { isActive },
    });

    return result.count > 0;
  }

  private async getApplicableRules(product: any, userId?: string, options: any = {}): Promise<any[]> {
    return this.prisma.pricingRule.findMany({
      where: {
        storeId: product.store.id,
        isActive: true,
      },
    });
  }

  private async evaluateRule(rule: any, product: any, userId?: string, options: any = {}): Promise<number> {
    const conditions = rule.conditions || {};
    const now = options.date || new Date();

    switch (rule.type) {
      case 'TIME_BASED': {
        const hour = now.getHours();
        const day = now.getDay();
        
        if (conditions.daysOfWeek && !conditions.daysOfWeek.includes(day)) {
          return 0;
        }

        if (hour >= conditions.startHour && hour < conditions.endHour) {
          return rule.discountPercentage;
        }
        return 0;
      }

      case 'DEMAND_BASED': {
        const demand = await this.getCurrentDemand(product.store.id);
        if (demand.level === 'low') {
          return conditions.lowDemandDiscount || 0;
        }
        // Note: Surcharge would be negative discount
        if (demand.level === 'high') {
          return -(conditions.highDemandSurcharge || 0);
        }
        return 0;
      }

      case 'STOCK_BASED': {
        const stock = product.stock || 0;
        if (stock > 0 && stock <= conditions.lowStockThreshold) {
          return rule.discountPercentage;
        }
        return 0;
      }

      case 'LOYALTY': {
        if (!userId) return 0;
        
        const orderCount = await this.prisma.order.count({
          where: { userId, storeId: product.store.id, status: 'DELIVERED' },
        });

        if (orderCount >= conditions.minOrders) {
          return rule.discountPercentage;
        }
        return 0;
      }

      default:
        return 0;
    }
  }

  private mapRule(rule: any): PricingRule {
    return {
      id: rule.id,
      type: rule.type,
      name: rule.name,
      discountPercentage: rule.discountPercentage,
      conditions: rule.conditions,
      isActive: rule.isActive,
    };
  }
}
