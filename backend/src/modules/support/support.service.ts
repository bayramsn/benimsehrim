import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { TicketType, TicketStatus } from '@prisma/client';

@Injectable()
export class SupportService {
  constructor(private prisma: PrismaService) {}

  async createTicket(userId: string, data: { type: TicketType; orderId?: string; rideId?: string; deliveryId?: string; subject: string; description?: string }) {
    return this.prisma.ticket.create({
      data: {
        ticketNo: await this.generateTicketNo(),
        userId,
        ...data,
      },
    });
  }

  async getMyTickets(userId: string) {
    return this.prisma.ticket.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getTicketById(id: string, userId: string) {
    return this.prisma.ticket.findFirst({
      where: { id, userId },
      include: { replies: { orderBy: { createdAt: 'asc' } } },
    });
  }

  async addReply(ticketId: string, userId: string, content: string, isAdmin = false) {
    return this.prisma.ticketReply.create({
      data: { ticketId, userId, content, isAdmin },
    });
  }

  async updateStatus(ticketId: string, status: TicketStatus) {
    return this.prisma.ticket.update({
      where: { id: ticketId },
      data: { status, ...(status === TicketStatus.RESOLVED && { resolvedAt: new Date() }) },
    });
  }

  private async generateTicketNo(): Promise<string> {
    const year = new Date().getFullYear();
    const count = await this.prisma.ticket.count();
    return `TKT-${year}-${(count + 1).toString().padStart(6, '0')}`;
  }
}
