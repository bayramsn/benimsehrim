import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';
import { StoresService } from './stores.service';

@ApiTags('Stores')
@Controller('stores')
export class StoresController {
  constructor(private readonly storesService: StoresService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Kendi mağazamı getir' })
  async getMyStore(@CurrentUser() user: any) {
    return this.storesService.getMyStore(user.id);
  }

  @Get('me/dashboard')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Satıcı paneli istatistikleri' })
  async getDashboardStats(@CurrentUser() user: any) {
    return this.storesService.getDashboardStats(user.id);
  }

  @Get()
  @ApiOperation({ summary: 'Mağazaları listele' })
  async findAll(@Query() query: { cityId?: string; categoryId?: string; isOpen?: string; page?: string; limit?: string }) {
    return this.storesService.findAll({
      cityId: query.cityId,
      categoryId: query.categoryId,
      isOpen: query.isOpen === 'true',
      page: parseInt(query.page || '1'),
      limit: parseInt(query.limit || '20'),
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Mağaza detayı' })
  async findById(@Param('id') id: string) {
    return this.storesService.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mağaza oluştur (Esnaf)' })
  async create(@CurrentUser() user: any, @Body() body: any) {
    return this.storesService.create(user.id, body);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mağaza güncelle (Esnaf)' })
  async update(@CurrentUser() user: any, @Param('id') id: string, @Body() body: any) {
    return this.storesService.update(id, user.id, body);
  }

  @Put(':id/status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mağaza aç/kapat (Esnaf)' })
  async setStatus(@CurrentUser() user: any, @Param('id') id: string, @Body() body: { isOpen: boolean }) {
    return this.storesService.setOpenStatus(id, user.id, body.isOpen);
  }

  @Put(':id/busy')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mağaza yoğunluk durumu (Hazırım/Meşgul)' })
  async setBusyStatus(@CurrentUser() user: any, @Param('id') id: string, @Body() body: { isBusy: boolean }) {
    return this.storesService.updateBusyStatus(id, user.id, body.isBusy);
  }
}
