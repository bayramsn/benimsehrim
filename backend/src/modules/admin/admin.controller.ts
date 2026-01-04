import { Controller, Get, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import { AdminService } from './admin.service';
import { ReviewsService } from '../reviews/reviews.service';

@ApiTags('Admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth()
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly reviewsService: ReviewsService,
  ) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Dashboard verileri' })
  async getDashboard() {
    return this.adminService.getDashboard();
  }

  @Get('vendors')
  @ApiOperation({ summary: 'Esnaf listesi' })
  async getVendors(@Query('status') status?: 'pending' | 'approved' | 'rejected') {
    return this.adminService.getVendors(status);
  }

  @Put('vendors/:id/approve')
  @ApiOperation({ summary: 'Esnaf onayla/reddet' })
  async approveVendor(@Param('id') id: string, @Body() body: { approve: boolean }) {
    return this.adminService.approveVendor(id, body.approve);
  }

  @Get('drivers')
  @ApiOperation({ summary: 'Şoför listesi' })
  async getDrivers(@Query('status') status?: 'pending' | 'approved') {
    return this.adminService.getDrivers(status);
  }

  @Put('drivers/:id/approve')
  @ApiOperation({ summary: 'Şoför onayla/reddet' })
  async approveDriver(@Param('id') id: string, @Body() body: { approve: boolean }) {
    return this.adminService.approveDriver(id, body.approve);
  }

  @Get('couriers')
  @ApiOperation({ summary: 'Kurye listesi' })
  async getCouriers(@Query('status') status?: 'pending' | 'approved') {
    return this.adminService.getCouriers(status);
  }

  @Put('couriers/:id/approve')
  @ApiOperation({ summary: 'Kurye onayla/reddet' })
  async approveCourier(@Param('id') id: string, @Body() body: { approve: boolean }) {
    return this.adminService.approveCourier(id, body.approve);
  }

  @Get('reviews/pending')
  @ApiOperation({ summary: 'Bekleyen yorumlar' })
  async getPendingReviews() {
    return this.adminService.getPendingReviews();
  }

  @Put('reviews/:id/approve')
  @ApiOperation({ summary: 'Yorum onayla' })
  async approveReview(@Param('id') id: string) {
    return this.reviewsService.approve(id);
  }

  @Put('reviews/:id/reject')
  @ApiOperation({ summary: 'Yorum reddet' })
  async rejectReview(@Param('id') id: string) {
    return this.reviewsService.reject(id);
  }

  @Get('operations/stats')
  @ApiOperation({ summary: 'Operasyon istatistikleri' })
  async getOperationStats() {
    return this.adminService.getOperationStats();
  }

  @Get('crisis/logs')
  @ApiOperation({ summary: 'Kriz kayıtları (Silent Alarm)' })
  async getCrisisLogs() {
    return this.adminService.getCrisisLogs();
  }

  @Put('crisis/:id/resolve')
  @ApiOperation({ summary: 'Kriz çözüldü olarak işaretle' })
  async resolveCrisisLog(@Param('id') id: string) {
    return this.adminService.resolveCrisisLog(id);
  }
}
