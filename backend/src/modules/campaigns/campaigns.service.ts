import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { CampaignType } from '@prisma/client';

@Injectable()
export class CampaignsService {
  constructor(private prisma: PrismaService) {}

  async findActive(params?: { storeId?: string; type?: CampaignType }) {
    const where: any = { isActive: true, endDate: { gte: new Date() } };
    if (params?.storeId) where.storeId = params.storeId;
    if (params?.type) where.type = params.type;

    return this.prisma.campaign.findMany({
      where,
      include: { store: true, product: true },
      orderBy: { endDate: 'asc' },
    });
  }

  async create(storeId: string, data: {
    productId?: string;
    type: CampaignType;
    value: number;
    startDate: Date;
    endDate: Date;
    stockLimit?: number;
    happyHourStart?: string;
    happyHourEnd?: string;
  }) {
    return this.prisma.campaign.create({
      data: { storeId, ...data },
    });
  }

  async update(id: string, storeId: string, data: any) {
    return this.prisma.campaign.updateMany({ where: { id, storeId }, data });
  }

  async deactivate(id: string, storeId: string) {
    return this.prisma.campaign.updateMany({ where: { id, storeId }, data: { isActive: false } });
  }

  async checkExpiredCampaigns() {
    // Süresi dolan kampanyaları pasife al
    return this.prisma.campaign.updateMany({
      where: { isActive: true, endDate: { lt: new Date() } },
      data: { isActive: false },
    });
  }
}
