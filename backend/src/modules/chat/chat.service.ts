import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

// Basit küfür filtresi
const BANNED_WORDS = ['küfür1', 'küfür2']; // Gerçek bir liste eklenecek

@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  async getMessages(chatId: string, userId: string, limit = 50) {
    const chat = await this.prisma.chat.findFirst({
      where: { id: chatId, OR: [{ userId }, { partnerId: userId }] },
    });

    if (!chat) return { data: [], chat: null };

    const messages = await this.prisma.message.findMany({
      where: { chatId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: { sender: { select: { id: true, name: true } } },
    });

    return { data: messages.reverse(), chat };
  }

  async sendMessage(chatId: string, userId: string, content: string) {
    const chat = await this.prisma.chat.findFirst({
      where: { id: chatId, OR: [{ userId }, { partnerId: userId }], isActive: true },
    });

    if (!chat) throw new BadRequestException('Sohbet aktif değil');

    // Küfür filtresi
    const lowerContent = content.toLowerCase();
    if (BANNED_WORDS.some(word => lowerContent.includes(word))) {
      throw new BadRequestException('Uygunsuz içerik tespit edildi');
    }

    const message = await this.prisma.message.create({
      data: { chatId, senderId: userId, content },
      include: { sender: { select: { id: true, name: true } } },
    });

    return message;
  }

  async getChatByOrder(orderId: string, userId: string) {
    return this.prisma.chat.findFirst({
      where: { orderId, OR: [{ userId }, { partnerId: userId }] },
    });
  }

  async getChatByRide(rideId: string, userId: string) {
    return this.prisma.chat.findFirst({
      where: { rideId, OR: [{ userId }, { partnerId: userId }] },
    });
  }

  async createOrGetChat(type: 'ORDER' | 'RIDE', referenceId: string, userId: string, partnerId: string) {
    const existing = type === 'ORDER'
      ? await this.prisma.chat.findUnique({ where: { orderId: referenceId } })
      : await this.prisma.chat.findUnique({ where: { rideId: referenceId } });

    if (existing) return existing;

    return this.prisma.chat.create({
      data: {
        type,
        ...(type === 'ORDER' ? { orderId: referenceId } : { rideId: referenceId }),
        userId,
        partnerId,
      },
    });
  }

  async closeChat(chatId: string) {
    return this.prisma.chat.update({
      where: { id: chatId },
      data: { isActive: false, closedAt: new Date() },
    });
  }
}
