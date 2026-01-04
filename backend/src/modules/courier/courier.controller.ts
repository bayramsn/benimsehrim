import { Controller, Get, Put, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole, DeliveryStatus } from '@prisma/client';
import { CourierService } from './courier.service';

@ApiTags('Courier')
@Controller('courier')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.COURIER)
@ApiBearerAuth()
export class CourierController {
  constructor(private readonly courierService: CourierService) {}

  @Get('deliveries')
  @ApiOperation({ summary: 'Görev listesi (Kurye)' })
  async getDeliveries(@CurrentUser() user: any) {
    return this.courierService.getDeliveries(user.id);
  }

  @Put('deliveries/:id/status')
  @ApiOperation({ summary: 'Teslimat durumu güncelle' })
  async updateDeliveryStatus(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { status: DeliveryStatus; lat?: number; lng?: number },
  ) {
    return this.courierService.updateDeliveryStatus(user.id, id, body.status, body.lat, body.lng);
  }

  @Put('location')
  @ApiOperation({ summary: 'Konum güncelle' })
  async updateLocation(@CurrentUser() user: any, @Body() body: { lat: number; lng: number }) {
    return this.courierService.updateLocation(user.id, body.lat, body.lng);
  }

  @Put('status')
  @ApiOperation({ summary: 'Online/Offline durumu' })
  async updateStatus(@CurrentUser() user: any, @Body() body: { isOnline: boolean }) {
    return this.courierService.updateStatus(user.id, body.isOnline);
  }
}
