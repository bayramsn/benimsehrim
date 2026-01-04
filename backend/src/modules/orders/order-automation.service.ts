import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../common/prisma/prisma.service';
import { RedisService } from '../../common/redis/redis.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OrderStatus } from '@prisma/client';

/**
 * Order Automation Service
 * 
 * Operasyonel Kurallar:
 * - Sipariş geldiğinde: Push (0s) → SMS (60s) → WhatsApp (120s) → İptal/Yönlendir (180s)
 * - Stok 0 → Ürün otomatik pasif
 * - 7 gün satılmayan ürün → uyarı
 * - Gün boyu sipariş yoksa → "Açık mısın?" bildirimi
 */
@Injectable()
export class OrderAutomationService {
  private readonly logger = new Logger(OrderAutomationService.name);

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private notifications: NotificationsService,
  ) {}

  /**
   * Yeni sipariş bildirimi gönder
   */
  async notifyNewOrder(orderId: string): Promise<void> {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        store: { include: { user: true } },
        items: { include: { product: true } },
      },
    });

    if (!order) return;

    const vendorUserId = order.store.userId;

    // 1. İlk Push bildirimi gönder
    await this.notifications.sendPush({
      userId: vendorUserId,
      title: '🔔 Yeni Sipariş!',
      body: `${order.orderNo} - ${order.total.toFixed(2)}₺`,
      data: { type: 'NEW_ORDER', orderId: order.id },
    });

    // Bildirim kaydı
    await this.prisma.orderNotification.create({
      data: { orderId, type: 'PUSH' },
    });

    await this.prisma.order.update({
      where: { id: orderId },
      data: { notifCount: 1 },
    });

    // 2. Zamanlanmış bildirimleri kuyruğa al
    await this.scheduleOrderReminders(orderId, vendorUserId);
  }

  /**
   * Sipariş hatırlatma zamanlaması
   */
  private async scheduleOrderReminders(orderId: string, vendorUserId: string): Promise<void> {
    // Redis'e zamanlanmış görevler ekle
    const now = Date.now();
    
    // 60 saniye sonra SMS
    await this.redis.set(
      `order_reminder:sms:${orderId}`,
      JSON.stringify({ orderId, vendorUserId, type: 'SMS' }),
      70, // 70 saniye TTL (10s buffer)
    );
    
    // 120 saniye sonra WhatsApp
    await this.redis.set(
      `order_reminder:whatsapp:${orderId}`,
      JSON.stringify({ orderId, vendorUserId, type: 'WHATSAPP' }),
      130,
    );
    
    // 180 saniye sonra otomatik işlem
    await this.redis.set(
      `order_reminder:auto:${orderId}`,
      JSON.stringify({ orderId, vendorUserId, type: 'AUTO' }),
      190,
    );
  }

  /**
   * Her 10 saniyede bir bekleyen siparişleri kontrol et
   */
  @Cron('*/10 * * * * *')
  async checkPendingOrders(): Promise<void> {
    const pendingOrders = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.PENDING,
        createdAt: {
          lte: new Date(Date.now() - 55000), // 55 saniyeden eski
        },
      },
      include: {
        store: { include: { user: true } },
      },
    });

    for (const order of pendingOrders) {
      await this.processOrderReminder(order);
    }
  }

  /**
   * Sipariş hatırlatma işlemi
   */
  private async processOrderReminder(order: any): Promise<void> {
    const elapsed = Date.now() - new Date(order.createdAt).getTime();
    const vendorUserId = order.store.userId;
    const vendorPhone = order.store.user.phone;

    // 60-120 saniye arası: SMS gönder (henüz gönderilmediyse)
    if (elapsed >= 60000 && elapsed < 120000 && order.notifCount < 2) {
      await this.notifications.sendSms(
        vendorUserId,
        `🔔 Benim Şehrim: Yeni sipariş bekliyor! Sipariş No: ${order.orderNo}. Lütfen uygulamayı kontrol edin.`,
      );
      
      await this.prisma.orderNotification.create({
        data: { orderId: order.id, type: 'SMS' },
      });
      
      await this.prisma.order.update({
        where: { id: order.id },
        data: { notifCount: 2 },
      });
      
      this.logger.log(`SMS sent for order ${order.orderNo}`);
    }

    // 120-180 saniye arası: WhatsApp gönder
    if (elapsed >= 120000 && elapsed < 180000 && order.notifCount < 3) {
      await this.notifications.sendWhatsApp(
        vendorUserId,
        `⚠️ ACİL: ${order.orderNo} numaralı sipariş 2 dakikadır bekliyor! 1 dakika içinde yanıt vermezseniz iptal edilecek.`,
      );
      
      await this.prisma.orderNotification.create({
        data: { orderId: order.id, type: 'WHATSAPP' },
      });
      
      await this.prisma.order.update({
        where: { id: order.id },
        data: { notifCount: 3 },
      });
      
      this.logger.log(`WhatsApp sent for order ${order.orderNo}`);
    }

    // 180 saniye sonra: Otomatik iptal veya yönlendirme
    if (elapsed >= 180000 && order.status === OrderStatus.PENDING) {
      await this.autoHandleUnresponsiveOrder(order);
    }
  }

  /**
   * Cevapsız siparişi otomatik işle
   */
  private async autoHandleUnresponsiveOrder(order: any): Promise<void> {
    // Önce başka esnaf ara (aynı kategoride)
    const alternativeStore = await this.findAlternativeStore(order);

    if (alternativeStore) {
      // Başka esnafa yönlendir
      await this.prisma.order.update({
        where: { id: order.id },
        data: { 
          storeId: alternativeStore.id,
          notifCount: 0,
        },
      });
      
      // Yeni esnafa bildirim
      await this.notifyNewOrder(order.id);
      
      this.logger.log(`Order ${order.orderNo} redirected to ${alternativeStore.name}`);
    } else {
      // Sipariş iptal
      await this.prisma.order.update({
        where: { id: order.id },
        data: { status: OrderStatus.CANCELLED },
      });
      
      await this.prisma.orderTimeline.create({
        data: {
          orderId: order.id,
          status: OrderStatus.CANCELLED,
          note: 'Esnaf tarafından cevaplanmadı - otomatik iptal',
        },
      });
      
      // Kullanıcıya bildirim
      await this.notifications.sendPush({
        userId: order.userId,
        title: 'Sipariş İptal Edildi',
        body: 'Mağaza siparişinize yanıt vermedi. Ödemeniz varsa iade edilecektir.',
        data: { type: 'ORDER_CANCELLED', orderId: order.id },
      });
      
      this.logger.log(`Order ${order.orderNo} auto-cancelled`);
    }
  }

  /**
   * Alternatif mağaza bul
   */
  private async findAlternativeStore(order: any): Promise<any | null> {
    // Basit implementasyon - aynı şehirde açık olan başka mağaza
    const alternative = await this.prisma.store.findFirst({
      where: {
        cityId: order.store.cityId,
        id: { not: order.storeId },
        isOpen: true,
        isApproved: true,
      },
      orderBy: { rating: 'desc' },
    });

    return alternative;
  }

  /**
   * Her gün gece yarısı: Satılmayan ürünleri kontrol et
   */
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async checkStaleProducts(): Promise<void> {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const staleProducts = await this.prisma.product.findMany({
      where: {
        isActive: true,
        OR: [
          { lastSoldAt: { lt: sevenDaysAgo } },
          { lastSoldAt: null, createdAt: { lt: sevenDaysAgo } },
        ],
      },
      include: {
        store: { include: { user: true } },
      },
    });

    // Grup by store
    const storeProducts = new Map<string, any[]>();
    for (const product of staleProducts) {
      const storeId = product.storeId;
      if (!storeProducts.has(storeId)) {
        storeProducts.set(storeId, []);
      }
      storeProducts.get(storeId)!.push(product);
    }

    // Her mağazaya bildirim gönder
    for (const [storeId, products] of storeProducts) {
      const store = products[0].store;
      await this.notifications.sendPush({
        userId: store.userId,
        title: '📦 Ürün Gözden Geçirme',
        body: `${products.length} ürün 7 gündür satılmadı. Fiyat veya stok güncellemesi düşünün.`,
        data: { type: 'STALE_PRODUCTS', productIds: products.map((p) => p.id) },
      });
    }

    this.logger.log(`Checked ${staleProducts.length} stale products`);
  }

  /**
   * Her gün akşam 6'da: Gün boyu sipariş almayan mağazaları kontrol et
   */
  @Cron('0 18 * * *')
  async checkNoOrderStores(): Promise<void> {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    // Bugün sipariş almamış açık mağazalar
    const openStoresWithNoOrders = await this.prisma.store.findMany({
      where: {
        isOpen: true,
        isApproved: true,
        orders: {
          none: {
            createdAt: { gte: todayStart },
          },
        },
      },
      include: { user: true },
    });

    for (const store of openStoresWithNoOrders) {
      await this.notifications.sendPush({
        userId: store.userId,
        title: '🤔 Açık mısınız?',
        body: 'Bugün hiç sipariş almadınız. Mağazanızın açık olduğundan emin olun.',
        data: { type: 'NO_ORDERS_TODAY', storeId: store.id },
      });
    }

    this.logger.log(`Notified ${openStoresWithNoOrders.length} stores with no orders`);
  }
}
