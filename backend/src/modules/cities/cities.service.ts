import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class CitiesService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    return this.prisma.city.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
  }

  async findById(id: string) {
    return this.prisma.city.findUnique({
      where: { id },
      include: { districts: { where: { isActive: true }, orderBy: { name: 'asc' } } },
    });
  }

  async getDistricts(cityId: string) {
    return this.prisma.district.findMany({
      where: { cityId, isActive: true },
      orderBy: { name: 'asc' },
    });
  }
}
