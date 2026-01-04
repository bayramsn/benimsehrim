import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ChatService } from './chat.service';

@ApiTags('Chat')
@Controller('chats')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get(':id/messages')
  @ApiOperation({ summary: 'Mesajları getir' })
  async getMessages(@CurrentUser() user: any, @Param('id') id: string, @Query('limit') limit?: string) {
    return this.chatService.getMessages(id, user.id, parseInt(limit || '50'));
  }

  @Post(':id/messages')
  @ApiOperation({ summary: 'Mesaj gönder (sadece metin)' })
  async sendMessage(@CurrentUser() user: any, @Param('id') id: string, @Body() body: { content: string }) {
    return this.chatService.sendMessage(id, user.id, body.content);
  }

  @Get('order/:orderId')
  @ApiOperation({ summary: 'Sipariş sohbetini getir' })
  async getChatByOrder(@CurrentUser() user: any, @Param('orderId') orderId: string) {
    return this.chatService.getChatByOrder(orderId, user.id);
  }

  @Get('ride/:rideId')
  @ApiOperation({ summary: 'Yolculuk sohbetini getir' })
  async getChatByRide(@CurrentUser() user: any, @Param('rideId') rideId: string) {
    return this.chatService.getChatByRide(rideId, user.id);
  }
}
