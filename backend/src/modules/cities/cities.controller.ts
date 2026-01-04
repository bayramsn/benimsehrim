import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { CitiesService } from './cities.service';

@ApiTags('Cities')
@Controller('cities')
export class CitiesController {
  constructor(private readonly citiesService: CitiesService) {}

  @Get()
  @ApiOperation({ summary: 'Aktif şehirleri getir' })
  async findAll() {
    return this.citiesService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Şehir detayı ve ilçeler' })
  async findById(@Param('id') id: string) {
    return this.citiesService.findById(id);
  }

  @Get(':id/districts')
  @ApiOperation({ summary: 'Şehrin ilçeleri' })
  async getDistricts(@Param('id') id: string) {
    return this.citiesService.getDistricts(id);
  }
}
