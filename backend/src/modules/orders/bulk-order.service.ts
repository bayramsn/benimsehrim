import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

export interface BulkOrderItem {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

export interface BulkOrderRequest {
  userId: string;
  storeId: string;
  eventType: 'WEDDING' | 'FUNERAL' | 'BIRTHDAY' | 'CORPORATE' | 'OTHER';
  eventDate: Date;
  guestCount: number;
  items: BulkOrderItem[];
  notes?: string;
  contactPhone: string;
  deliveryAddress: string;
}

export interface BulkOrderQuote {
  id: string;
  originalTotal: number;
  discountPercentage: number;
  discountedTotal: number;
  deliveryFee: number;
  grandTotal: number;
  validUntil: Date;
}

@Injectable()
export class BulkOrderService {
  private readonly logger = new Logger(BulkOrderService.name);

  // Discount tiers based on quantity
  private readonly DISCOUNT_TIERS = [
    { minQuantity: 50, discount: 5 },
    { minQuantity: 100, discount: 10 },
    { minQuantity: 200, discount: 15 },
    { minQuantity: 500, discount: 20 },
  ];

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Toplu sipariş talebi oluştur
   */
  async createRequest(request: BulkOrderRequest): Promise<{ requestId: string; quote: BulkOrderQuote }> {
    const totalQuantity = request.items.reduce((sum, item) => sum + item.quantity, 0);
    const originalTotal = request.items.reduce((sum, item) => sum + item.totalPrice, 0);

    // Calculate discount
    const discountPercentage = this.calculateDiscount(totalQuantity);
    const discountAmount = originalTotal * (discountPercentage / 100);
    const discountedTotal = originalTotal - discountAmount;

    // Calculate delivery fee (free for large orders)
    const deliveryFee = totalQuantity >= 100 ? 0 : 50;
    const grandTotal = discountedTotal + deliveryFee;

    // Quote valid for 48 hours
    const validUntil = new Date();
    validUntil.setHours(validUntil.getHours() + 48);

    // Create bulk order request
    const bulkOrder = await this.prisma.bulkOrder.create({
      data: {
        userId: request.userId,
        storeId: request.storeId,
        eventType: request.eventType,
        eventDate: request.eventDate,
        guestCount: request.guestCount,
        items: request.items as any,
        notes: request.notes,
        contactPhone: request.contactPhone,
        deliveryAddress: request.deliveryAddress,
        originalTotal,
        discountPercentage,
        discountedTotal,
        deliveryFee,
        grandTotal,
        quoteValidUntil: validUntil,
        status: 'PENDING',
      },
    });

    // Notify store owner
    await this.notifyStore(bulkOrder);

    this.logger.log(`Bulk order request: ${bulkOrder.id}, ${totalQuantity} items`);

    return {
      requestId: bulkOrder.id,
      quote: {
        id: bulkOrder.id,
        originalTotal,
        discountPercentage,
        discountedTotal,
        deliveryFee,
        grandTotal,
        validUntil,
      },
    };
  }

  /**
   * Teklif hesapla (oluşturmadan önce önizleme)
   */
  async calculateQuote(
    items: { productId: string; quantity: number }[],
    storeId: string
  ): Promise<{
    items: BulkOrderItem[];
    originalTotal: number;
    discountPercentage: number;
    discountedTotal: number;
    savings: number;
  }> {
    // Get product prices
    const productIds = items.map(i => i.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds }, storeId },
      select: { id: true, name: true, price: true },
    });

    const productMap = new Map(products.map(p => [p.id, p]));

    const bulkItems: BulkOrderItem[] = items.map(item => {
      const product = productMap.get(item.productId);
      if (!product) throw new Error(`Ürün bulunamadı: ${item.productId}`);

      return {
        productId: item.productId,
        productName: product.name,
        quantity: item.quantity,
        unitPrice: product.price,
        totalPrice: product.price * item.quantity,
      };
    });

    const totalQuantity = bulkItems.reduce((sum, item) => sum + item.quantity, 0);
    const originalTotal = bulkItems.reduce((sum, item) => sum + item.totalPrice, 0);
    const discountPercentage = this.calculateDiscount(totalQuantity);
    const discountedTotal = originalTotal * (1 - discountPercentage / 100);
    const savings = originalTotal - discountedTotal;

    return {
      items: bulkItems,
      originalTotal,
      discountPercentage,
      discountedTotal,
      savings,
    };
  }

  /**
   * Mağaza tarafından talebi onayla
   */
  async approveRequest(requestId: string, storeId: string): Promise<boolean> {
    const request = await this.prisma.bulkOrder.findFirst({
      where: { id: requestId, storeId, status: 'PENDING' },
    });

    if (!request) {
      throw new Error('Talep bulunamadı');
    }

    await this.prisma.bulkOrder.update({
      where: { id: requestId },
      data: { status: 'APPROVED', approvedAt: new Date() },
    });

    // Notify customer
    await this.notificationsService.sendPush({
      userId: request.userId,
      title: '✅ Toplu Sipariş Onaylandı!',
      body: `Toplu siparişiniz onaylandı. Ödeme yaparak siparişi tamamlayabilirsiniz.`,
      data: { type: 'BULK_ORDER_APPROVED', requestId },
    });

    return true;
  }

  /**
   * Talebi reddet
   */
  async rejectRequest(requestId: string, storeId: string, reason: string): Promise<boolean> {
    const request = await this.prisma.bulkOrder.findFirst({
      where: { id: requestId, storeId, status: 'PENDING' },
    });

    if (!request) {
      throw new Error('Talep bulunamadı');
    }

    await this.prisma.bulkOrder.update({
      where: { id: requestId },
      data: { status: 'REJECTED', rejectionReason: reason },
    });

    // Notify customer
    await this.notificationsService.sendPush({
      userId: request.userId,
      title: '❌ Toplu Sipariş Reddedildi',
      body: reason || 'Talebiniz reddedildi.',
      data: { type: 'BULK_ORDER_REJECTED', requestId },
    });

    return true;
  }

  /**
   * Kullanıcının taleplerini getir
   */
  async getUserRequests(userId: string): Promise<any[]> {
    const requests = await this.prisma.bulkOrder.findMany({
      where: { userId },
      include: { store: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return requests.map(r => ({
      id: r.id,
      storeName: r.store.name,
      eventType: r.eventType,
      eventDate: r.eventDate,
      guestCount: r.guestCount,
      grandTotal: r.grandTotal,
      status: r.status,
      createdAt: r.createdAt,
    }));
  }

  /**
   * Mağazanın taleplerini getir
   */
  async getStoreRequests(storeId: string, status?: string): Promise<any[]> {
    const where: any = { storeId };
    if (status) where.status = status;

    const requests = await this.prisma.bulkOrder.findMany({
      where,
      include: { user: { select: { name: true, phone: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return requests.map(r => ({
      id: r.id,
      customerName: r.user.name || 'Müşteri',
      customerPhone: r.contactPhone,
      eventType: r.eventType,
      eventDate: r.eventDate,
      guestCount: r.guestCount,
      itemCount: (r.items as any[])?.length || 0,
      grandTotal: r.grandTotal,
      status: r.status,
      createdAt: r.createdAt,
    }));
  }

  private calculateDiscount(quantity: number): number {
    for (const tier of [...this.DISCOUNT_TIERS].reverse()) {
      if (quantity >= tier.minQuantity) {
        return tier.discount;
      }
    }
    return 0;
  }

  private async notifyStore(bulkOrder: any): Promise<void> {
    const store = await this.prisma.store.findUnique({
      where: { id: bulkOrder.storeId },
      select: { userId: true },
    });

    if (store) {
      await this.notificationsService.sendPush({
        userId: store.userId,
        title: '🎉 Yeni Toplu Sipariş Talebi!',
        body: `${bulkOrder.guestCount} kişilik ${bulkOrder.eventType} için talep geldi.`,
        data: { type: 'BULK_ORDER_REQUEST', requestId: bulkOrder.id },
      });
    }
  }
}
