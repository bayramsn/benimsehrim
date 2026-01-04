import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole, CampaignType } from '@prisma/client';
import { CampaignsService } from './campaigns.service';

@ApiTags('Campaigns')
@Controller('campaigns')
export class CampaignsController {
  constructor(private readonly campaignsService: CampaignsService) {}

  @Get()
  @ApiOperation({ summary: 'Aktif kampanyaları listele' })
  async findActive(@Query() query: { storeId?: string; type?: CampaignType }) {
    return this.campaignsService.findActive(query);
  }

  @Post('store/:storeId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Kampanya oluştur (Esnaf)' })
  async create(@Param('storeId') storeId: string, @Body() body: any) {
    return this.campaignsService.create(storeId, body);
  }

  @Put(':id/store/:storeId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Kampanya güncelle' })
  async update(@Param('id') id: string, @Param('storeId') storeId: string, @Body() body: any) {
    return this.campaignsService.update(id, storeId, body);
  }

  @Delete(':id/store/:storeId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Kampanya sonlandır' })
  async deactivate(@Param('id') id: string, @Param('storeId') storeId: string) {
    await this.campaignsService.deactivate(id, storeId);
    return { success: true };
  }
}
