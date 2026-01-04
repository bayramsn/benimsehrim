import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';
import { TaxiService } from './taxi.service';

@ApiTags('Taxi')
@Controller('taxi')
export class TaxiController {
  constructor(private readonly taxiService: TaxiService) {}

  @Post('estimate')
  @ApiOperation({ summary: 'Tahmini ücret hesapla' })
  async estimate(@Body() body: { pickupLat: number; pickupLng: number; dropLat: number; dropLng: number }) {
    return this.taxiService.estimate(body.pickupLat, body.pickupLng, body.dropLat, body.dropLng);
  }

  @Get('nearby')
  @ApiOperation({ summary: 'Yakındaki taksileri göster' })
  async getNearby(@Query() query: { lat: string; lng: string; radius?: string }) {
    return this.taxiService.getNearbyDrivers(parseFloat(query.lat), parseFloat(query.lng), parseFloat(query.radius || '3'));
  }

  @Post('request')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Taksi çağır' })
  async request(@CurrentUser() user: any, @Body() body: any) {
    return this.taxiService.requestRide(user.id, body);
  }

  @Get('rides')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Yolculuklarımı getir' })
  async getMyRides(@CurrentUser() user: any) {
    return this.taxiService.findByUser(user.id);
  }

  @Get('rides/:id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Yolculuk detayı' })
  async getRide(@Param('id') id: string) {
    return this.taxiService.findById(id);
  }

  @Put('driver/status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.TAXI_DRIVER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Şoför online/offline durumu' })
  async updateDriverStatus(@CurrentUser() user: any, @Body() body: { isOnline: boolean; lat?: number; lng?: number }) {
    return this.taxiService.updateDriverStatus(user.id, body.isOnline, body.lat, body.lng);
  }

  @Put('driver/busy')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.TAXI_DRIVER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Şoför hazır/meşgul durumu' })
  async setBusyStatus(@CurrentUser() user: any, @Body() body: { isBusy: boolean }) {
    return this.taxiService.updateBusyStatus(user.id, body.isBusy);
  }

  @Put('driver/rest')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.TAXI_DRIVER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mola modu' })
  async setRestMode(@CurrentUser() user: any, @Body() body: { duration: number }) {
    return this.taxiService.toggleRestMode(user.id, body.duration);
  }

  @Put('driver/rides/:id/respond')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.TAXI_DRIVER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Çağrıya yanıt ver' })
  async respondToCall(@CurrentUser() user: any, @Param('id') id: string, @Body() body: { accept: boolean }) {
    const driver = await this.taxiService['prisma'].driver.findUnique({ where: { userId: user.id } });
    if (!driver) {
      throw new Error('Driver not found');
    }
    return this.taxiService.respondToCall(driver.id, id, body.accept);
  }
}
