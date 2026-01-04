import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      include: { city: true, district: true, addresses: true, driver: true, courier: true },
    });
  }

  async findByPhone(phone: string) {
    return this.prisma.user.findUnique({ where: { phone } });
  }

  async update(id: string, data: { name?: string; email?: string; cityId?: string; districtId?: string }) {
    return this.prisma.user.update({ where: { id }, data });
  }

  async getAddresses(userId: string) {
    return this.prisma.address.findMany({ where: { userId }, orderBy: { isDefault: 'desc' } });
  }

  async addAddress(userId: string, data: { title: string; address: string; latitude: number; longitude: number; note?: string; isDefault?: boolean }) {
    if (data.isDefault) {
      await this.prisma.address.updateMany({ where: { userId }, data: { isDefault: false } });
    }
    return this.prisma.address.create({ data: { userId, ...data } });
  }

  async updateAddress(addressId: string, userId: string, data: any) {
    return this.prisma.address.updateMany({ where: { id: addressId, userId }, data });
  }

  async deleteAddress(addressId: string, userId: string) {
    return this.prisma.address.deleteMany({ where: { id: addressId, userId } });
  }
}
