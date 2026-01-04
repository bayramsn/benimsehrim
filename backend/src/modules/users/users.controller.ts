import { Controller, Get, Put, Post, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UsersService } from './users.service';

@ApiTags('Users')
@Controller('users')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Mevcut kullanıcı bilgileri' })
  async getMe(@CurrentUser() user: any) {
    return this.usersService.findById(user.id);
  }

  @Put('me')
  @ApiOperation({ summary: 'Kullanıcı güncelle' })
  async updateMe(@CurrentUser() user: any, @Body() body: any) {
    return this.usersService.update(user.id, body);
  }

  @Get('addresses')
  @ApiOperation({ summary: 'Adreslerimi getir' })
  async getAddresses(@CurrentUser() user: any) {
    return this.usersService.getAddresses(user.id);
  }

  @Post('addresses')
  @ApiOperation({ summary: 'Adres ekle' })
  async addAddress(@CurrentUser() user: any, @Body() body: any) {
    return this.usersService.addAddress(user.id, body);
  }

  @Put('addresses/:id')
  @ApiOperation({ summary: 'Adres güncelle' })
  async updateAddress(@CurrentUser() user: any, @Param('id') id: string, @Body() body: any) {
    return this.usersService.updateAddress(id, user.id, body);
  }

  @Delete('addresses/:id')
  @ApiOperation({ summary: 'Adres sil' })
  async deleteAddress(@CurrentUser() user: any, @Param('id') id: string) {
    await this.usersService.deleteAddress(id, user.id);
    return { success: true };
  }
}
