import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FeatureFlagService } from './feature-flags.service';

@ApiTags('Features')
@Controller('features')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class FeatureFlagController {
  constructor(private readonly featureFlagService: FeatureFlagService) {}

  @Get('me')
  @ApiOperation({ summary: 'Kullanıcının aktif özelliklerini getir' })
  async getMyFeatures(@CurrentUser() user: any) {
    return this.featureFlagService.getUserFeatures(user.id);
  }
}
