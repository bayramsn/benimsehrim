import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

export interface Recommendation {
  type: 'product' | 'store' | 'reorder' | 'trending';
  id: string;
  name: string;
  reason: string;
  image?: string;
  price?: number;
  discount?: number;
  score: number;
}

@Injectable()
export class RecommendationsService {
  private readonly logger = new Logger(RecommendationsService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Kullanıcı için kişiselleştirilmiş öneriler
   */
  async getRecommendations(userId: string, limit = 10): Promise<Recommendation[]> {
    const recommendations: Recommendation[] = [];

    // 1. Yeniden sipariş önerileri (en son sipariş edilen ürünler)
    const reorderRecs = await this.getReorderRecommendations(userId);
    recommendations.push(...reorderRecs);

    // 2. Benzer kullanıcıların aldıkları
    const collaborativeRecs = await this.getCollaborativeRecommendations(userId);
    recommendations.push(...collaborativeRecs);

    // 3. Trending ürünler
    const trendingRecs = await this.getTrendingProducts();
    recommendations.push(...trendingRecs);

    // 4. Kategoriye dayalı öneriler
    const categoryRecs = await this.getCategoryRecommendations(userId);
    recommendations.push(...categoryRecs);

    // Sort by score and deduplicate
    const unique = this.deduplicateRecommendations(recommendations);
    return unique.slice(0, limit);
  }

  /**
   * "Bunu alanlar şunu da aldı" önerileri
   */
  async getRelatedProducts(productId: string, limit = 5): Promise<Recommendation[]> {
    // Find orders containing this product
    const orders = await this.prisma.orderItem.findMany({
      where: { productId },
      select: { orderId: true },
      take: 100,
    });

    const orderIds = orders.map(o => o.orderId);

    // Find other products in these orders
    const relatedItems = await this.prisma.orderItem.findMany({
      where: {
        orderId: { in: orderIds },
        productId: { not: productId },
      },
      select: {
        productId: true,
        product: {
          select: { id: true, name: true, price: true },
        },
      },
    });

    // Count frequency
    const productCounts = new Map<string, { product: any; count: number }>();
    for (const item of relatedItems) {
      const existing = productCounts.get(item.productId);
      if (existing) {
        existing.count++;
      } else {
        productCounts.set(item.productId, { product: item.product, count: 1 });
      }
    }

    // Sort by frequency
    return Array.from(productCounts.values())
      .sort((a, b) => b.count - a.count)
      .slice(0, limit)
      .map(({ product, count }) => ({
        type: 'product' as const,
        id: product.id,
        name: product.name,
        reason: `%${Math.min(count * 10, 90)} kullanıcı bunu da aldı`,
        price: product.price,
        score: count * 10,
      }));
  }

  /**
   * Mağaza için önerilen ürünler
   */
  async getStoreRecommendations(storeId: string, userId?: string, limit = 5): Promise<Recommendation[]> {
    // Popular products from this store
    const popularProducts = await this.prisma.orderItem.groupBy({
      by: ['productId'],
      where: { order: { storeId } },
      _count: { productId: true },
      orderBy: { _count: { productId: 'desc' } },
      take: limit,
    });

    const productIds = popularProducts.map(p => p.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, name: true, price: true },
    });

    return products.map((product, index) => ({
      type: 'product' as const,
      id: product.id,
      name: product.name,
      reason: 'Bu mağazanın en çok satanı',
      price: product.price,
      score: 100 - index * 10,
    }));
  }

  private async getReorderRecommendations(userId: string): Promise<Recommendation[]> {
    const recentOrders = await this.prisma.order.findMany({
      where: { userId, status: 'DELIVERED' },
      include: {
        items: {
          include: { product: { select: { id: true, name: true, price: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 5,
    });

    const productMap = new Map<string, { product: any; count: number; lastOrder: Date }>();

    for (const order of recentOrders) {
      for (const item of order.items) {
        if (!item.product) continue;
        const existing = productMap.get(item.productId);
        if (existing) {
          existing.count++;
        } else {
          productMap.set(item.productId, {
            product: item.product,
            count: 1,
            lastOrder: order.createdAt,
          });
        }
      }
    }

    return Array.from(productMap.values())
      .sort((a, b) => b.count - a.count)
      .slice(0, 3)
      .map(({ product, count }) => ({
        type: 'reorder' as const,
        id: product.id,
        name: product.name,
        reason: `${count} kez sipariş ettiniz`,
        price: product.price,
        score: count * 20 + 50,
      }));
  }

  private async getCollaborativeRecommendations(userId: string): Promise<Recommendation[]> {
    // Find products ordered by current user
    const userProducts = await this.prisma.orderItem.findMany({
      where: { order: { userId } },
      select: { productId: true },
    });
    const userProductIds = new Set(userProducts.map(p => p.productId));

    if (userProductIds.size === 0) return [];

    // Find similar users (who ordered same products)
    const similarUsers = await this.prisma.orderItem.findMany({
      where: {
        productId: { in: Array.from(userProductIds) },
        order: { userId: { not: userId } },
      },
      select: { order: { select: { userId: true } } },
      take: 50,
    });

    const similarUserIds = [...new Set(similarUsers.map(s => s.order.userId))];

    // Find products these users bought that current user hasn't
    const recommendations = await this.prisma.orderItem.findMany({
      where: {
        order: { userId: { in: similarUserIds } },
        productId: { notIn: Array.from(userProductIds) },
      },
      select: {
        productId: true,
        product: { select: { id: true, name: true, price: true } },
      },
      take: 100,
    });

    // Count and sort
    const counts = new Map<string, { product: any; count: number }>();
    for (const rec of recommendations) {
      const existing = counts.get(rec.productId);
      if (existing) {
        existing.count++;
      } else {
        counts.set(rec.productId, { product: rec.product, count: 1 });
      }
    }

    return Array.from(counts.values())
      .sort((a, b) => b.count - a.count)
      .slice(0, 3)
      .map(({ product, count }) => ({
        type: 'product' as const,
        id: product.id,
        name: product.name,
        reason: 'Senin gibi kullanıcılar bunu aldı',
        price: product.price,
        score: count * 15,
      }));
  }

  private async getTrendingProducts(): Promise<Recommendation[]> {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    const trending = await this.prisma.orderItem.groupBy({
      by: ['productId'],
      where: { order: { createdAt: { gte: yesterday } } },
      _count: { productId: true },
      orderBy: { _count: { productId: 'desc' } },
      take: 3,
    });

    const productIds = trending.map(t => t.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, name: true, price: true },
    });

    return products.map(product => ({
      type: 'trending' as const,
      id: product.id,
      name: product.name,
      reason: '🔥 Bugün çok sipariş ediliyor',
      price: product.price,
      score: 80,
    }));
  }

  private async getCategoryRecommendations(userId: string): Promise<Recommendation[]> {
    // Find user's preferred categories
    const userOrders = await this.prisma.order.findMany({
      where: { userId },
      select: { store: { select: { categories: { select: { id: true } } } } },
      take: 10,
    });

    const categoryIds = new Set<string>();
    for (const order of userOrders) {
      for (const cat of order.store.categories) {
        categoryIds.add(cat.id);
      }
    }

    if (categoryIds.size === 0) return [];

    // Find top stores in these categories
    const stores = await this.prisma.store.findMany({
      where: {
        categories: { some: { id: { in: Array.from(categoryIds) } } },
        isApproved: true,
      },
      select: { id: true, name: true, rating: true },
      orderBy: { rating: 'desc' },
      take: 2,
    });

    return stores.map(store => ({
      type: 'store' as const,
      id: store.id,
      name: store.name,
      reason: 'Senin için önerilen mağaza',
      score: (store.rating || 0) * 10 + 30,
    }));
  }

  private deduplicateRecommendations(recs: Recommendation[]): Recommendation[] {
    const seen = new Set<string>();
    return recs.filter(rec => {
      const key = `${rec.type}-${rec.id}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    }).sort((a, b) => b.score - a.score);
  }
}
