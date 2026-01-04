import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RecommendationsService } from './recommendations.service';

@ApiTags('Recommendations')
@Controller('recommendations')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class RecommendationsController {
  constructor(private readonly recommendationsService: RecommendationsService) {}

  @Get()
  @ApiOperation({ summary: 'Kişiselleştirilmiş öneriler getir' })
  async getRecommendations(@CurrentUser() user: any, @Query('limit') limit?: string) {
    return this.recommendationsService.getRecommendations(user.id, parseInt(limit || '10'));
  }

  @Get('product-relations')
  @ApiOperation({ summary: 'Ürün detay sayfası için ilişkili ürünler' })
  async getRelatedProducts(@Query('productId') productId: string) {
    return this.recommendationsService.getRelatedProducts(productId);
  }
}
