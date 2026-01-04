import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface Location {
  lat: number;
  lng: number;
}

interface RouteResult {
  distance: number; // meters
  duration: number; // seconds
  polyline?: string;
}

interface GeocodeResult {
  lat: number;
  lng: number;
  address: string;
  city?: string;
  district?: string;
}

/**
 * Maps Service - 100% FREE
 * 
 * Uses:
 * - OpenRouteService: 2000 requests/day FREE - https://openrouteservice.org
 * - Nominatim (OpenStreetMap): Unlimited with fair use - https://nominatim.org
 * - Haversine formula: Offline distance calculation (always available)
 * 
 * NO PAID SERVICES USED!
 */
@Injectable()
export class MapsService {
  private readonly logger = new Logger(MapsService.name);
  private orsApiKey: string | undefined;

  constructor(private configService: ConfigService) {
    this.orsApiKey = this.configService.get('OPENROUTESERVICE_API_KEY');
    
    if (this.orsApiKey) {
      this.logger.log('Maps: Using OpenRouteService + Nominatim (FREE)');
    } else {
      this.logger.log('Maps: Using Haversine + Nominatim (FREE, no API key needed)');
    }
  }

  /**
   * Calculate route between two points
   * Uses OpenRouteService if API key available, otherwise Haversine formula
   */
  async getRoute(origin: Location, destination: Location): Promise<RouteResult> {
    if (this.orsApiKey) {
      const route = await this.getOpenRouteServiceRoute(origin, destination);
      if (route) return route;
    }

    // Fallback: Haversine formula (always works, no API needed)
    return this.getHaversineRoute(origin, destination);
  }

  /**
   * Haversine formula - Calculate distance between two points
   * 100% offline, no API needed
   */
  private getHaversineRoute(origin: Location, destination: Location): RouteResult {
    const distance = this.calculateDistance(origin, destination);
    // Estimate duration: assume 30km/h average speed in city
    const duration = Math.round((distance / 1000) * 2 * 60); // seconds

    return { distance: Math.round(distance), duration };
  }

  /**
   * Calculate straight-line distance between two points (Haversine formula)
   * Returns distance in meters
   */
  calculateDistance(origin: Location, destination: Location): number {
    const R = 6371e3; // Earth's radius in meters
    const φ1 = (origin.lat * Math.PI) / 180;
    const φ2 = (destination.lat * Math.PI) / 180;
    const Δφ = ((destination.lat - origin.lat) * Math.PI) / 180;
    const Δλ = ((destination.lng - origin.lng) * Math.PI) / 180;

    const a =
      Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  /**
   * Geocode address to coordinates
   * Uses Nominatim (OpenStreetMap) - 100% FREE
   */
  async geocode(address: string): Promise<GeocodeResult | null> {
    return this.nominatimGeocode(address);
  }

  /**
   * Reverse geocode coordinates to address
   * Uses Nominatim (OpenStreetMap) - 100% FREE
   */
  async reverseGeocode(lat: number, lng: number): Promise<GeocodeResult | null> {
    return this.nominatimReverseGeocode(lat, lng);
  }

  /**
   * Estimate fare for taxi/courier
   */
  estimateFare(distanceMeters: number, type: 'taxi' | 'courier' = 'taxi'): number {
    const distanceKm = distanceMeters / 1000;

    if (type === 'taxi') {
      // Taxi fare: Base 15₺ + 8₺/km
      const baseFare = 15;
      const perKm = 8;
      return Math.round(baseFare + distanceKm * perKm);
    } else {
      // Courier fare: Base 10₺ + 5₺/km
      const baseFare = 10;
      const perKm = 5;
      return Math.round(baseFare + distanceKm * perKm);
    }
  }

  /**
   * Find nearby locations within radius
   */
  filterByDistance(
    center: Location,
    locations: (Location & { id: string })[],
    radiusMeters: number,
  ): (Location & { id: string; distance: number })[] {
    return locations
      .map((loc) => ({
        ...loc,
        distance: this.calculateDistance(center, loc),
      }))
      .filter((loc) => loc.distance <= radiusMeters)
      .sort((a, b) => a.distance - b.distance);
  }

  // ============================================
  // OPENROUTESERVICE - FREE: 2000 requests/day
  // https://openrouteservice.org
  // ============================================

  private async getOpenRouteServiceRoute(
    origin: Location,
    destination: Location,
  ): Promise<RouteResult | null> {
    try {
      const response = await fetch(
        'https://api.openrouteservice.org/v2/directions/driving-car',
        {
          method: 'POST',
          headers: {
            Authorization: this.orsApiKey!,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            coordinates: [
              [origin.lng, origin.lat],
              [destination.lng, destination.lat],
            ],
          }),
        },
      );

      if (!response.ok) {
        this.logger.warn(`OpenRouteService error: ${response.status}`);
        return null;
      }

      const data = await response.json();

      if (data.routes && data.routes[0]) {
        const route = data.routes[0];
        return {
          distance: Math.round(route.summary.distance),
          duration: Math.round(route.summary.duration),
          polyline: route.geometry,
        };
      }

      return null;
    } catch (error) {
      this.logger.error('OpenRouteService error:', error);
      return null;
    }
  }

  // ============================================
  // NOMINATIM (OpenStreetMap) - 100% FREE
  // https://nominatim.org
  // Fair use policy: max 1 request/second
  // ============================================

  private async nominatimGeocode(address: string): Promise<GeocodeResult | null> {
    try {
      // Add Turkey context for better results
      const searchAddress = address.includes('Türkiye') ? address : `${address}, Türkiye`;

      const params = new URLSearchParams({
        q: searchAddress,
        format: 'json',
        limit: '1',
        countrycodes: 'tr',
        addressdetails: '1',
      });

      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?${params}`,
        {
          headers: {
            'User-Agent': 'BenimSehrim/1.0 (https://benimsehrim.com)',
            Accept: 'application/json',
          },
        },
      );

      if (!response.ok) {
        this.logger.warn(`Nominatim geocode error: ${response.status}`);
        return null;
      }

      const data = await response.json();

      if (data && data[0]) {
        const result = data[0];
        return {
          lat: parseFloat(result.lat),
          lng: parseFloat(result.lon),
          address: result.display_name,
          city: result.address?.city || result.address?.town || result.address?.province,
          district: result.address?.suburb || result.address?.neighbourhood || result.address?.district,
        };
      }

      return null;
    } catch (error) {
      this.logger.error('Nominatim geocode error:', error);
      return null;
    }
  }

  private async nominatimReverseGeocode(lat: number, lng: number): Promise<GeocodeResult | null> {
    try {
      const params = new URLSearchParams({
        lat: lat.toString(),
        lon: lng.toString(),
        format: 'json',
        addressdetails: '1',
        'accept-language': 'tr',
      });

      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?${params}`,
        {
          headers: {
            'User-Agent': 'BenimSehrim/1.0 (https://benimsehrim.com)',
            Accept: 'application/json',
          },
        },
      );

      if (!response.ok) {
        this.logger.warn(`Nominatim reverse geocode error: ${response.status}`);
        return null;
      }

      const data = await response.json();

      if (data && data.display_name) {
        return {
          lat,
          lng,
          address: data.display_name,
          city: data.address?.city || data.address?.town || data.address?.province,
          district: data.address?.suburb || data.address?.neighbourhood || data.address?.district,
        };
      }

      return null;
    } catch (error) {
      this.logger.error('Nominatim reverse geocode error:', error);
      return null;
    }
  }

  // ============================================
  // LEAFLET/OPENSTREETMAP TILE URLs (for frontend)
  // 100% FREE - No API key needed
  // ============================================

  /**
   * Get OpenStreetMap tile URL for frontend maps
   * Use with Leaflet.js or MapLibre GL JS
   */
  getMapTileUrl(): string {
    return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /**
   * Get map attribution (required for OSM)
   */
  getMapAttribution(): string {
    return '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
  }

  /**
   * Alternative tile providers (all FREE)
   */
  getAlternativeTileUrls(): Record<string, string> {
    return {
      // Standard OpenStreetMap
      osm: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      // CartoDB (clean, minimal)
      cartodb_light: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      cartodb_dark: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
      // Stamen (stylized)
      stamen_terrain: 'https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.jpg',
      stamen_toner: 'https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png',
    };
  }
}
