# 📱 Performans Optimizasyon Kılavuzu

## Android Optimizasyonları

### 1. ProGuard/R8 Optimizasyonu

```kotlin
// build.gradle.kts
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

### 2. Image Optimization

- **Coil** kullanımı ile lazy loading
- WebP formatı kullanımı (30-80% daha küçük)
- Placeholder ve error image'lar
- Disk cache stratejisi

```kotlin
AsyncImage(
    model = ImageRequest.Builder(LocalContext.current)
        .data(imageUrl)
        .crossfade(true)
        .diskCachePolicy(CachePolicy.ENABLED)
        .memoryCachePolicy(CachePolicy.ENABLED)
        .build(),
    contentDescription = null
)
```

### 3. LazyColumn Optimizasyonu

```kotlin
LazyColumn(
    modifier = Modifier.fillMaxSize(),
    contentPadding = PaddingValues(16.dp)
) {
    items(
        items = list,
        key = { it.id } // Recomposition optimizasyonu
    ) { item ->
        ItemCard(item)
    }
}
```

### 4. Memory Leak Önleme

- ViewModel kullanımı
- Lifecycle-aware components
- Coroutine scope yönetimi
- Weak references

```kotlin
class MyViewModel : ViewModel() {
    private val _state = MutableStateFlow<UiState>(UiState.Loading)
    val state = _state.asStateFlow()

    override fun onCleared() {
        super.onCleared()
        // Cleanup
    }
}
```

### 5. Network Optimizasyonu

```kotlin
// Retrofit with OkHttp
OkHttpClient.Builder()
    .connectTimeout(30, TimeUnit.SECONDS)
    .readTimeout(30, TimeUnit.SECONDS)
    .writeTimeout(30, TimeUnit.SECONDS)
    .cache(Cache(context.cacheDir, 10 * 1024 * 1024)) // 10 MB
    .addInterceptor(HttpLoggingInterceptor().apply {
        level = if (BuildConfig.DEBUG)
            HttpLoggingInterceptor.Level.BODY
        else
            HttpLoggingInterceptor.Level.NONE
    })
    .build()
```

### 6. Database Optimizasyonu

- Room database kullanımı
- Index'ler ekleme
- Query optimizasyonu
- Pagination

```kotlin
@Query("SELECT * FROM orders WHERE userId = :userId ORDER BY createdAt DESC LIMIT :limit OFFSET :offset")
suspend fun getOrdersPaginated(userId: String, limit: Int, offset: Int): List<Order>
```

### 7. Startup Optimization

```kotlin
class BenimSehrimApp : Application() {
    override fun onCreate() {
        super.onCreate()

        // Lazy initialization
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        }

        // Background initialization
        lifecycleScope.launch(Dispatchers.IO) {
            initializeNonCriticalComponents()
        }
    }
}
```

## iOS Optimizasyonları

### 1. Image Caching

```swift
// Kingfisher veya SDWebImage kullanımı
KF.url(URL(string: imageUrl))
    .placeholder(UIImage(named: "placeholder"))
    .cacheMemoryOnly()
    .fade(duration: 0.25)
    .set(to: imageView)
```

### 2. List Performance

```swift
List {
    ForEach(items, id: \.id) { item in
        ItemRow(item: item)
            .id(item.id)
    }
}
.listStyle(.plain)
```

### 3. Memory Management

```swift
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    private var cancellables = Set<AnyCancellable>()

    deinit {
        cancellables.removeAll()
    }
}
```

## Backend Optimizasyonları

### 1. Database Query Optimization

```typescript
// Prisma ile efficient queries
const orders = await prisma.order.findMany({
  where: { userId },
  select: {
    id: true,
    orderNo: true,
    total: true,
    // Sadece gerekli alanlar
  },
  take: 20,
  skip: page * 20,
  orderBy: { createdAt: "desc" },
});
```

### 2. Caching Strategy

```typescript
// Redis caching
async getStores(cityId: string) {
    const cacheKey = `stores:${cityId}`;

    // Cache'den kontrol et
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    // Database'den çek
    const stores = await this.prisma.store.findMany({
        where: { cityId }
    });

    // Cache'e kaydet (1 saat)
    await this.redis.setex(cacheKey, 3600, JSON.stringify(stores));

    return stores;
}
```

### 3. Pagination

```typescript
@Get()
async findAll(@Query() query: PaginationDto) {
    const { page = 1, limit = 20 } = query;

    const [data, total] = await Promise.all([
        this.prisma.store.findMany({
            skip: (page - 1) * limit,
            take: limit,
        }),
        this.prisma.store.count(),
    ]);

    return {
        data,
        meta: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        },
    };
}
```

### 4. Connection Pooling

```typescript
// Prisma datasource
datasource db {
    provider = "postgresql"
    url      = env("DATABASE_URL")

    // Connection pool
    connection_limit = 10
    pool_timeout = 20
}
```

### 5. Response Compression

```typescript
// main.ts
import compression from "compression";

app.use(
  compression({
    filter: (req, res) => {
      if (req.headers["x-no-compression"]) {
        return false;
      }
      return compression.filter(req, res);
    },
    level: 6, // Compression level (0-9)
  })
);
```

## Genel Optimizasyon İpuçları

### 1. API Response Size

- Sadece gerekli alanları döndür
- Pagination kullan
- Compression aktif et
- GraphQL düşün (over-fetching önleme)

### 2. Network Calls

- Batch requests
- Debouncing (arama için)
- Retry logic
- Timeout ayarları

### 3. Monitoring

```typescript
// Performance monitoring
import { performance } from "perf_hooks";

const start = performance.now();
await someOperation();
const end = performance.now();

logger.info(`Operation took ${end - start}ms`);
```

### 4. Load Testing

```bash
# Apache Bench
ab -n 1000 -c 100 http://localhost:3000/v1/stores

# Artillery
artillery quick --count 100 --num 10 http://localhost:3000/v1/stores
```

## Performans Metrikleri

### Hedef Değerler

- **API Response Time**: < 200ms (p95)
- **Database Query**: < 100ms (p95)
- **App Startup**: < 2 saniye
- **Screen Load**: < 1 saniye
- **Image Load**: < 500ms

### Monitoring Tools

- **Backend**: New Relic, DataDog, Sentry
- **Mobile**: Firebase Performance, Crashlytics
- **Database**: PgHero, pg_stat_statements

## Checklist

### Android

- [ ] ProGuard/R8 aktif
- [ ] Image optimization (WebP)
- [ ] LazyColumn key kullanımı
- [ ] Memory leak kontrolü
- [ ] Network caching
- [ ] Database indexing

### iOS

- [ ] Image caching
- [ ] List optimization
- [ ] Memory management
- [ ] Network optimization

### Backend

- [ ] Query optimization
- [ ] Redis caching
- [ ] Pagination
- [ ] Connection pooling
- [ ] Response compression
- [ ] Monitoring setup
