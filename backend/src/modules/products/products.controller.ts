import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import { ProductsService } from './products.service';

@ApiTags('Products')
@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get('store/:storeId')
  @ApiOperation({ summary: 'Mağaza ürünlerini getir' })
  async findByStore(@Param('storeId') storeId: string) {
    return this.productsService.findByStore(storeId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Ürün detayı' })
  async findById(@Param('id') id: string) {
    return this.productsService.findById(id);
  }

  @Post('store/:storeId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Ürün ekle (min 2 fotoğraf zorunlu)' })
  async create(@Param('storeId') storeId: string, @Body() body: any) {
    return this.productsService.create(storeId, body);
  }

  @Put(':id/store/:storeId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Ürün güncelle' })
  async update(@Param('id') id: string, @Param('storeId') storeId: string, @Body() body: any) {
    return this.productsService.update(id, storeId, body);
  }

  @Put(':id/store/:storeId/stock')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Stok güncelle' })
  async updateStock(@Param('id') id: string, @Param('storeId') storeId: string, @Body() body: { stock: number }) {
    return this.productsService.updateStock(id, storeId, body.stock);
  }

  @Delete(':id/store/:storeId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Ürün sil' })
  async delete(@Param('id') id: string, @Param('storeId') storeId: string) {
    await this.productsService.delete(id, storeId);
    return { success: true };
  }
}
