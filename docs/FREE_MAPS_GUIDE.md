# 🆓 100% Ücretsiz Harita Servisleri

Bu projede **Google Maps kullanılmıyor**. Tamamen ücretsiz ve açık kaynak harita servisleri kullanılmaktadır.

## Backend Harita Servisleri

### 1. Nominatim (OpenStreetMap Geocoding)

- **Maliyet:** 100% Ücretsiz
- **Limit:** Fair use (1 istek/saniye)
- **Website:** https://nominatim.org
- **Kullanım:**
  - Adres → Koordinat (Geocoding)
  - Koordinat → Adres (Reverse Geocoding)

### 2. OpenRouteService

- **Maliyet:** Ücretsiz (2000 istek/gün)
- **Website:** https://openrouteservice.org
- **API Key:** https://openrouteservice.org/dev/#/signup (opsiyonel)
- **Kullanım:**
  - Rota hesaplama
  - Mesafe ve süre tahmini

### 3. Haversine Formula

- **Maliyet:** 100% Ücretsiz (API gerektirmez)
- **Kullanım:**
  - İki nokta arası kuş uçuşu mesafe
  - Yakındaki lokasyonları filtreleme

---

## Frontend/Mobil Harita Görüntüleme

### Web (React/Next.js) - Leaflet.js

```bash
npm install leaflet react-leaflet
```

```tsx
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";

function Map() {
  return (
    <MapContainer
      center={[39.8468, 34.0288]}
      zoom={13}
      style={{ height: "400px" }}
    >
      {/* OpenStreetMap - 100% FREE */}
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
      />
      <Marker position={[39.8468, 34.0288]}>
        <Popup>Kırşehir Merkez</Popup>
      </Marker>
    </MapContainer>
  );
}
```

### Android - OSMDroid

```kotlin
// build.gradle
implementation("org.osmdroid:osmdroid-android:6.1.18")
implementation("org.osmdroid:osmdroid-wms:6.1.18")
```

```kotlin
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.views.MapView

class MapActivity : AppCompatActivity() {
    private lateinit var mapView: MapView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Configuration for OSMDroid
        Configuration.getInstance().userAgentValue = "BenimSehrim/1.0"

        mapView = MapView(this)
        mapView.setTileSource(TileSourceFactory.MAPNIK) // OpenStreetMap tiles
        mapView.controller.setZoom(15.0)
        mapView.controller.setCenter(GeoPoint(39.8468, 34.0288)) // Kırşehir

        setContentView(mapView)
    }
}
```

### iOS - MapKit (Apple Maps - FREE)

```swift
import MapKit
import SwiftUI

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8468, longitude: 34.0288),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locations) { location in
            MapMarker(coordinate: location.coordinate, tint: .green)
        }
    }
}
```

### React Native - react-native-maps (OpenStreetMap)

```bash
npm install react-native-maps
```

```tsx
import MapView, { UrlTile, Marker } from "react-native-maps";

function OSMMap() {
  return (
    <MapView
      style={{ flex: 1 }}
      initialRegion={{
        latitude: 39.8468,
        longitude: 34.0288,
        latitudeDelta: 0.05,
        longitudeDelta: 0.05,
      }}
    >
      {/* OpenStreetMap Tiles - FREE */}
      <UrlTile
        urlTemplate="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        maximumZ={19}
        flipY={false}
      />
      <Marker
        coordinate={{ latitude: 39.8468, longitude: 34.0288 }}
        title="Kırşehir"
      />
    </MapView>
  );
}
```

---

## Ücretsiz Harita Tile Kaynakları

| Kaynak              | URL                                                             | Stil         |
| ------------------- | --------------------------------------------------------------- | ------------ |
| OpenStreetMap       | `https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png`            | Standart     |
| CartoDB Positron    | `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png`   | Açık/Minimal |
| CartoDB Dark Matter | `https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png`    | Koyu         |
| Stamen Terrain      | `https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.jpg` | Arazi        |
| Stamen Toner        | `https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png`   | Siyah-Beyaz  |

---

## Rota/Navigasyon İçin

### OSRM (Open Source Routing Machine)

- **Website:** http://project-osrm.org
- **Demo API:** http://router.project-osrm.org (ücretsiz, rate limited)

```typescript
// Rota hesaplama
const response = await fetch(
  `http://router.project-osrm.org/route/v1/driving/${startLng},${startLat};${endLng},${endLat}?overview=full`
);
const data = await response.json();
const route = data.routes[0];
console.log(`Distance: ${route.distance}m, Duration: ${route.duration}s`);
```

### Valhalla

- **Website:** https://github.com/valhalla/valhalla
- Self-hosted, tamamen ücretsiz

---

## Özet: Maliyet Karşılaştırması

| Servis                            | Google Maps      | Bu Proje           |
| --------------------------------- | ---------------- | ------------------ |
| Harita Görüntüleme                | ~$7/1000 yükleme | $0 (OSM)           |
| Geocoding                         | ~$5/1000 istek   | $0 (Nominatim)     |
| Directions                        | ~$5/1000 istek   | $0 (ORS/Haversine) |
| **Aylık Maliyet (10k kullanıcı)** | **~$500+**       | **$0**             |

---

## Notlar

1. **OpenStreetMap Attribution:** OSM kullanırken attribution göstermek zorunludur
2. **Rate Limiting:** Nominatim için 1 istek/saniye kuralına uyun
3. **Self-Hosting:** Yüksek trafik için Nominatim/OSRM kendi sunucunuzda çalıştırın
4. **Kalite:** OSM verileri Türkiye için oldukça iyi kalitede
