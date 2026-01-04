import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  async findByStore(storeId: string) {
    return this.prisma.product.findMany({ where: { storeId, isActive: true }, orderBy: { createdAt: 'desc' } });
  }

  async findById(id: string) {
    return this.prisma.product.findUnique({ where: { id }, include: { campaigns: { where: { isActive: true } } } });
  }

  async create(storeId: string, data: { name: string; description?: string; categoryId?: string; price: number; stock: number; unit?: string; images: string[] }) {
    // Minimum 2 fotoğraf zorunlu
    if (!data.images || data.images.length < 2) {
      throw new BadRequestException('En az 2 fotoğraf yüklemelisiniz');
    }
    return this.prisma.product.create({ data: { storeId, ...data } });
  }

  async update(id: string, storeId: string, data: any) {
    return this.prisma.product.updateMany({ where: { id, storeId }, data });
  }

  async updateStock(id: string, storeId: string, stock: number) {
    const product = await this.prisma.product.updateMany({ where: { id, storeId }, data: { stock, isActive: stock > 0 } });
    return product;
  }

  async delete(id: string, storeId: string) {
    return this.prisma.product.deleteMany({ where: { id, storeId } });
  }
}
