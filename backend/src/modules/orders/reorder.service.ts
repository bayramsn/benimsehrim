import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

export interface ReorderItem {
  productId: string;
  productName: string;
  quantity: number;
  price: number;
  available: boolean;
  priceChanged: boolean;
  oldPrice?: number;
}

export interface ReorderPreview {
  orderId: string;
  storeName: string;
  storeId: string;
  storeOpen: boolean;
  items: ReorderItem[];
  originalTotal: number;
  newTotal: number;
  unavailableCount: number;
  priceChangedCount: number;
  canReorder: boolean;
  message?: string;
}

@Injectable()
export class ReorderService {
  private readonly logger = new Logger(ReorderService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Son siparişleri getir (hızlı tekrar sipariş için)
   */
  async getRecentOrders(userId: string, limit = 5) {
    const orders = await this.prisma.order.findMany({
      where: { 
        userId, 
        status: 'DELIVERED',
      },
      include: {
        store: { select: { id: true, name: true, isOpen: true } },
        items: {
          include: {
            product: { select: { id: true, name: true, price: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    return orders.map(order => ({
      id: order.id,
      orderNo: order.orderNo,
      store: order.store,
      itemCount: order.items.length,
      total: order.total,
      createdAt: order.createdAt,
      canQuickReorder: order.store.isOpen,
    }));
  }

  /**
   * Tekrar sipariş önizleme
   */
  async previewReorder(userId: string, orderId: string): Promise<ReorderPreview> {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, userId },
      include: {
        store: { select: { id: true, name: true, isOpen: true } },
        items: {
          include: {
            product: { select: { id: true, name: true, price: true } },
          },
        },
      },
    });

    if (!order) {
      throw new Error('Sipariş bulunamadı');
    }

    const items: ReorderItem[] = order.items.map((item) => {
      const currentPrice = item.product?.price || item.unitPrice;
      const available = item.product !== null;
      const priceChanged = Math.abs(currentPrice - item.unitPrice) > 0.01;

      return {
        productId: item.productId,
        productName: item.product?.name || 'Ürün',
        quantity: item.quantity,
        price: currentPrice,
        available,
        priceChanged,
        oldPrice: priceChanged ? item.unitPrice : undefined,
      };
    });

    const unavailableCount = items.filter(i => !i.available).length;
    const priceChangedCount = items.filter(i => i.priceChanged).length;
    const newTotal = items.filter(i => i.available).reduce((sum, i) => sum + i.price * i.quantity, 0);

    let message: string | undefined;
    if (!order.store.isOpen) {
      message = 'Mağaza şu anda kapalı';
    } else if (unavailableCount > 0) {
      message = `${unavailableCount} ürün şu anda mevcut değil`;
    } else if (priceChangedCount > 0) {
      message = `${priceChangedCount} ürünün fiyatı değişti`;
    }

    return {
      orderId: order.id,
      storeName: order.store.name,
      storeId: order.store.id,
      storeOpen: order.store.isOpen,
      items,
      originalTotal: order.total,
      newTotal,
      unavailableCount,
      priceChangedCount,
      canReorder: order.store.isOpen && items.some(i => i.available),
      message,
    };
  }

  /**
   * Tekrar sipariş ver - sepet verilerini döndür
   */
  async reorder(userId: string, orderId: string): Promise<{ success: boolean; cartItems?: ReorderItem[]; storeId?: string; message: string }> {
    const preview = await this.previewReorder(userId, orderId);

    if (!preview.canReorder) {
      return { success: false, message: preview.message || 'Sipariş tekrarlanamaz' };
    }

    const itemsToAdd = preview.items.filter(i => i.available);

    if (itemsToAdd.length === 0) {
      return { success: false, message: 'Eklenebilecek ürün yok' };
    }

    const skippedCount = preview.items.length - itemsToAdd.length;
    const message = skippedCount > 0
      ? `${itemsToAdd.length} ürün sepete eklendi (${skippedCount} ürün atlandı)`
      : `${itemsToAdd.length} ürün sepete eklendi`;

    this.logger.log(`Reorder: ${userId} -> ${orderId}, ${itemsToAdd.length} items`);

    // Return cart items for frontend to add to cart
    return { 
      success: true, 
      cartItems: itemsToAdd,
      storeId: preview.storeId,
      message 
    };
  }

  /**
   * Favori siparişler (sık tekrarlananlar)
   */
  async getFavoriteOrders(userId: string) {
    // En çok tekrarlanan mağazalar
    const orders = await this.prisma.order.findMany({
      where: { userId, status: 'DELIVERED' },
      include: {
        store: { select: { id: true, name: true } },
        items: { include: { product: true } },
      },
    });

    // Mağaza bazlı gruplama
    const storeGroups = new Map<string, { 
      store: { id: string; name: string };
      orderCount: number; 
      lastOrder: Date;
      mostOrderedItems: Map<string, { product: any; count: number }>;
    }>();

    for (const order of orders) {
      const existing = storeGroups.get(order.storeId) || {
        store: order.store,
        orderCount: 0,
        lastOrder: order.createdAt,
        mostOrderedItems: new Map(),
      };

      existing.orderCount++;
      if (order.createdAt > existing.lastOrder) {
        existing.lastOrder = order.createdAt;
      }

      for (const item of order.items) {
        const itemData = existing.mostOrderedItems.get(item.productId) || {
          product: item.product,
          count: 0,
        };
        itemData.count += item.quantity;
        existing.mostOrderedItems.set(item.productId, itemData);
      }

      storeGroups.set(order.storeId, existing);
    }

    // En çok sipariş verilen mağazalar
    return Array.from(storeGroups.values())
      .sort((a, b) => b.orderCount - a.orderCount)
      .slice(0, 5)
      .map(group => ({
        store: group.store,
        orderCount: group.orderCount,
        lastOrder: group.lastOrder,
        topItems: Array.from(group.mostOrderedItems.values())
          .sort((a, b) => b.count - a.count)
          .slice(0, 3)
          .map(i => ({ name: i.product?.name, count: i.count })),
      }));
  }
}
