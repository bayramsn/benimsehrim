import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ReviewsService } from './reviews.service';

@ApiTags('Reviews')
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Get()
  @ApiOperation({ summary: 'Değerlendirmeleri getir' })
  async findByTarget(@Query() query: { targetType: string; targetId: string }) {
    const [reviews, stats] = await Promise.all([
      this.reviewsService.findByTarget(query.targetType, query.targetId),
      this.reviewsService.getAverageRating(query.targetType, query.targetId),
    ]);
    return { data: reviews, ...stats };
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Değerlendirme yap' })
  async create(@CurrentUser() user: any, @Body() body: any) {
    return this.reviewsService.create(user.id, body);
  }
}
