import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { OrderAutomationService } from './order-automation.service';
import { OrderStatus, PaymentType } from '@prisma/client';

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private automation: OrderAutomationService,
  ) {}

  async create(userId: string, data: {
    storeId: string;
    items: { productId: string; quantity: number; campaignId?: string }[];
    addressId: string;
    addressNote?: string;
    paymentType: PaymentType;
  }) {
    // Mağaza kontrolü
    const store = await this.prisma.store.findUnique({ where: { id: data.storeId } });
    if (!store || !store.isOpen || !store.isApproved) {
      throw new BadRequestException('Mağaza kapalı veya aktif değil');
    }

    // Ürünleri ve fiyatları hesapla
    let subtotal = 0;
    let discount = 0;
    const orderItems = [];

    for (const item of data.items) {
      const product = await this.prisma.product.findUnique({ where: { id: item.productId }, include: { campaigns: { where: { isActive: true } } } });
      if (!product || !product.isActive || product.stock < item.quantity) {
        throw new BadRequestException(`Ürün stokta yok: ${product?.name || item.productId}`);
      }

      let unitPrice = product.price;
      let itemDiscount = 0;

      // Kampanya kontrolü
      if (item.campaignId) {
        const campaign = product.campaigns.find(c => c.id === item.campaignId);
        if (campaign) {
          if (campaign.type === 'PERCENTAGE') {
            itemDiscount = (product.price * campaign.value / 100) * item.quantity;
            unitPrice = product.price * (1 - campaign.value / 100);
          } else if (campaign.type === 'FIXED_AMOUNT') {
            itemDiscount = campaign.value * item.quantity;
            unitPrice = product.price - campaign.value;
          }
        }
      }

      const totalPrice = unitPrice * item.quantity;
      subtotal += product.price * item.quantity;
      discount += itemDiscount;

      orderItems.push({
        productId: item.productId,
        campaignId: item.campaignId,
        quantity: item.quantity,
        unitPrice: product.price,
        totalPrice,
      });

      // Stok güncelle
      await this.prisma.product.update({ where: { id: item.productId }, data: { stock: { decrement: item.quantity } } });
    }

    // Minimum sipariş kontrolü
    if (subtotal - discount < store.minOrder) {
      throw new BadRequestException(`Minimum sipariş tutarı: ${store.minOrder}₺`);
    }

    const total = subtotal - discount + store.deliveryFee;

    // Sipariş oluştur
    const order = await this.prisma.order.create({
      data: {
        orderNo: await this.generateOrderNo(),
        userId,
        storeId: data.storeId,
        addressId: data.addressId,
        addressNote: data.addressNote,
        paymentType: data.paymentType,
        subtotal,
        discount,
        deliveryFee: store.deliveryFee,
        total,
        items: { create: orderItems },
      },
      include: { items: { include: { product: true } }, store: true },
    });

    // Timeline kaydı
    await this.prisma.orderTimeline.create({
      data: { orderId: order.id, status: OrderStatus.PENDING },
    });

    // Esnafa bildirim gönder
    await this.automation.notifyNewOrder(order.id);

    return order;
  }

  async findByUser(userId: string, status?: OrderStatus) {
    const where: any = { userId };
    if (status) where.status = status;
    return this.prisma.order.findMany({
      where,
      include: { store: true, items: { include: { product: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string) {
    return this.prisma.order.findUnique({
      where: { id },
      include: { store: true, items: { include: { product: true } }, timeline: true, delivery: { include: { courier: true } }, address: true },
    });
  }

  async updateStatus(id: string, vendorUserId: string, status: OrderStatus, note?: string) {
    const order = await this.prisma.order.findFirst({
      where: { id, store: { userId: vendorUserId } },
    });

    if (!order) throw new NotFoundException('Sipariş bulunamadı');

    const updateData: any = { status };
    if (status === OrderStatus.ACCEPTED) updateData.acceptedAt = new Date();
    if (status === OrderStatus.DELIVERED) updateData.deliveredAt = new Date();

    await this.prisma.order.update({ where: { id }, data: updateData });
    await this.prisma.orderTimeline.create({ data: { orderId: id, status, note } });

    return { success: true };
  }

  private async generateOrderNo(): Promise<string> {
    const date = new Date();
    const dateStr = date.toISOString().slice(2, 10).replace(/-/g, '');
    const random = Math.floor(Math.random() * 1000000).toString().padStart(6, '0');
    return `BS${dateStr}${random}`;
  }
}
