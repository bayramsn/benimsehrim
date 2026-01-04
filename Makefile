# Benim Şehrim - Makefile
# ========================

.PHONY: help install dev build docker-up docker-down clean

# Default target
help:
	@echo ""
	@echo "🏙️  Benim Şehrim - Kullanılabilir Komutlar"
	@echo "=========================================="
	@echo ""
	@echo "Kurulum:"
	@echo "  make install       - Tüm bağımlılıkları yükle"
	@echo "  make setup         - Veritabanını hazırla (migrate + seed)"
	@echo ""
	@echo "Geliştirme:"
	@echo "  make dev           - Backend + Admin geliştirme sunucusu"
	@echo "  make dev-backend   - Sadece backend"
	@echo "  make dev-admin     - Sadece admin panel"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-up      - Docker ile tüm servisleri başlat"
	@echo "  make docker-down    - Docker servislerini durdur"
	@echo "  make docker-dev     - Sadece PostgreSQL, Redis ve Adminer"
	@echo "  make docker-build   - Docker image'ları build et"
	@echo "  make docker-restart - Servisleri yeniden başlat"
	@echo "  make docker-logs    - Logları göster"
	@echo "  make docker-migrate - Database migration'ları çalıştır"
	@echo "  make docker-seed    - Database'i seed et"
	@echo "  make docker-clean   - Volume'ları temizle"
	@echo ""
	@echo "Diğer:"
	@echo "  make build         - Production build"
	@echo "  make clean         - node_modules temizle"
	@echo "  make prisma-studio - Prisma Studio aç"
	@echo ""

# ===== KURULUM =====

install:
	@echo "📦 Backend bağımlılıkları yükleniyor..."
	cd backend && npm install
	@echo "📦 Admin bağımlılıkları yükleniyor..."
	cd admin && npm install
	@echo "✅ Kurulum tamamlandı!"

setup: install
	@echo "🗄️ Veritabanı hazırlanıyor..."
	cd backend && npx prisma generate
	cd backend && npx prisma migrate dev --name init
	cd backend && npx prisma db seed
	@echo "✅ Veritabanı hazır!"

# ===== GELİŞTİRME =====

dev-backend:
	cd backend && npm run start:dev

dev-admin:
	cd admin && npm run dev

dev:
	@echo "🚀 Geliştirme sunucuları başlatılıyor..."
	@echo "Backend: http://localhost:3000"
	@echo "Admin:   http://localhost:5173"
	@echo ""
	(cd backend && npm run start:dev &) && (cd admin && npm run dev)

# ===== DOCKER =====

docker-db:
	docker run --name benimsehrim-db -e POSTGRES_USER=benimsehrim -e POSTGRES_PASSWORD=benimsehrim123 -e POSTGRES_DB=benimsehrim -p 5432:5432 -d postgres:16-alpine
	docker run --name benimsehrim-redis -p 6379:6379 -d redis:7-alpine
	@echo "✅ PostgreSQL ve Redis başlatıldı!"

docker-up:
	docker-compose up -d
	@echo "✅ Tüm servisler başlatıldı!"

docker-down:
	docker-compose down
	@echo "✅ Servisler durduruldu!"

docker-logs:
	docker-compose logs -f

docker-build:
	@echo "🔨 Docker image'ları build ediliyor..."
	docker-compose build
	@echo "✅ Build tamamlandı!"

docker-dev:
	@echo "🔧 Development ortamı başlatılıyor (sadece DB)..."
	docker-compose -f docker-compose.dev.yml up -d
	@echo "✅ PostgreSQL, Redis ve Adminer başlatıldı!"
	@echo "   PostgreSQL: localhost:5432"
	@echo "   Redis:      localhost:6379"
	@echo "   Adminer:    http://localhost:8080"

docker-clean:
	@echo "🧹 Docker volume'ları temizleniyor..."
	docker-compose down -v
	@echo "✅ Temizlendi!"

docker-restart:
	docker-compose restart

docker-migrate:
	@echo "🗄️ Database migration'ları çalıştırılıyor..."
	docker-compose exec backend npx prisma migrate deploy
	@echo "✅ Migration'lar tamamlandı!"

docker-seed:
	@echo "🌱 Database seed ediliyor..."
	docker-compose exec backend npx prisma db seed
	@echo "✅ Seed tamamlandı!"

# ===== BUILD =====

build:
	@echo "🔨 Production build..."
	cd backend && npm run build
	cd admin && npm run build
	@echo "✅ Build tamamlandı!"

# ===== DİĞER =====

prisma-studio:
	cd backend && npx prisma studio

prisma-migrate:
	cd backend && npx prisma migrate dev

prisma-seed:
	cd backend && npx prisma db seed

clean:
	rm -rf backend/node_modules backend/dist
	rm -rf admin/node_modules admin/dist
	@echo "✅ Temizlendi!"
