import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupportService } from './support.service';

@ApiTags('Support')
@Controller('support')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post('tickets')
  @ApiOperation({ summary: 'Destek talebi oluştur' })
  async createTicket(@CurrentUser() user: any, @Body() body: any) {
    return this.supportService.createTicket(user.id, body);
  }

  @Get('tickets')
  @ApiOperation({ summary: 'Destek taleplerim' })
  async getMyTickets(@CurrentUser() user: any) {
    return this.supportService.getMyTickets(user.id);
  }

  @Get('tickets/:id')
  @ApiOperation({ summary: 'Destek talebi detayı' })
  async getTicket(@CurrentUser() user: any, @Param('id') id: string) {
    return this.supportService.getTicketById(id, user.id);
  }

  @Post('tickets/:id/reply')
  @ApiOperation({ summary: 'Destek talebine yanıt' })
  async addReply(@CurrentUser() user: any, @Param('id') id: string, @Body() body: { content: string }) {
    return this.supportService.addReply(id, user.id, body.content);
  }
}
