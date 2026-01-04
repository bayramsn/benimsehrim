#!/bin/bash

# Benim Şehrim - Docker Deployment Script
# ========================================

set -e

echo "🐳 Benim Şehrim - Docker Deployment"
echo "===================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker bulunamadı. Lütfen Docker'ı yükleyin: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose bulunamadı. Lütfen Docker Compose'u yükleyin."
    exit 1
fi

echo "✅ Docker ve Docker Compose bulundu"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 .env dosyası bulunamadı, .env.docker'dan kopyalanıyor..."
    cp .env.docker .env
    echo "⚠️  UYARI: .env dosyasını düzenleyip güvenlik ayarlarını yapın!"
    echo ""
fi

# Function to start services
start_services() {
    echo "🚀 Servisler başlatılıyor..."
    docker-compose up -d
    
    echo ""
    echo "⏳ Servislerin hazır olması bekleniyor..."
    sleep 10
    
    echo ""
    echo "📊 Servis durumları:"
    docker-compose ps
    
    echo ""
    echo "✅ Deployment tamamlandı!"
    echo ""
    echo "📍 Erişim Adresleri:"
    echo "   Backend API:    http://localhost:3000"
    echo "   API Docs:       http://localhost:3000/api"
    echo "   Admin Panel:    http://localhost:5173"
    echo "   Database GUI:   http://localhost:8080 (Adminer - sadece dev modunda)"
    echo ""
    echo "💡 Logları görmek için: docker-compose logs -f"
    echo "💡 Durdurmak için:      docker-compose down"
    echo ""
}

# Function to stop services
stop_services() {
    echo "🛑 Servisler durduruluyor..."
    docker-compose down
    echo "✅ Servisler durduruldu!"
}

# Function to restart services
restart_services() {
    echo "🔄 Servisler yeniden başlatılıyor..."
    docker-compose restart
    echo "✅ Servisler yeniden başlatıldı!"
}

# Function to show logs
show_logs() {
    docker-compose logs -f
}

# Function to run database migrations
run_migrations() {
    echo "🗄️ Veritabanı migration'ları çalıştırılıyor..."
    docker-compose exec backend npx prisma migrate deploy
    echo "✅ Migration'lar tamamlandı!"
}

# Function to seed database
seed_database() {
    echo "🌱 Veritabanı seed ediliyor..."
    docker-compose exec backend npx prisma db seed
    echo "✅ Seed tamamlandı!"
}

# Main menu
case "${1:-start}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        show_logs
        ;;
    migrate)
        run_migrations
        ;;
    seed)
        seed_database
        ;;
    dev)
        echo "🔧 Development modu başlatılıyor (sadece DB)..."
        docker-compose -f docker-compose.dev.yml up -d
        echo ""
        echo "✅ PostgreSQL ve Redis başlatıldı!"
        echo "   PostgreSQL: localhost:5432"
        echo "   Redis:      localhost:6379"
        echo "   Adminer:    http://localhost:8080"
        echo ""
        echo "💡 Backend'i manuel başlatın: cd backend && npm run start:dev"
        ;;
    *)
        echo "Kullanım: $0 {start|stop|restart|logs|migrate|seed|dev}"
        echo ""
        echo "Komutlar:"
        echo "  start    - Tüm servisleri başlat (varsayılan)"
        echo "  stop     - Tüm servisleri durdur"
        echo "  restart  - Tüm servisleri yeniden başlat"
        echo "  logs     - Logları göster"
        echo "  migrate  - Database migration'ları çalıştır"
        echo "  seed     - Database'i seed et"
        echo "  dev      - Sadece PostgreSQL ve Redis başlat (geliştirme)"
        exit 1
        ;;
esac
