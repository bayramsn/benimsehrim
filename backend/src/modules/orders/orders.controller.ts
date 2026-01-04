import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole, OrderStatus } from '@prisma/client';
import { OrdersService } from './orders.service';

@ApiTags('Orders')
@Controller('orders')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  @ApiOperation({ summary: 'Sipariş oluştur' })
  async create(@CurrentUser() user: any, @Body() body: any) {
    return this.ordersService.create(user.id, body);
  }

  @Get()
  @ApiOperation({ summary: 'Siparişlerimi getir' })
  async findMyOrders(@CurrentUser() user: any, @Query('status') status?: OrderStatus) {
    return this.ordersService.findByUser(user.id, status);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Sipariş detayı' })
  async findById(@Param('id') id: string) {
    return this.ordersService.findById(id);
  }

  @Put(':id/status')
  @UseGuards(RolesGuard)
  @Roles(UserRole.VENDOR)
  @ApiOperation({ summary: 'Sipariş durumu güncelle (Esnaf)' })
  async updateStatus(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { status: OrderStatus; note?: string },
  ) {
    return this.ordersService.updateStatus(id, user.id, body.status, body.note);
  }
}
