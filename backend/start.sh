#!/bin/bash

# Benim Şehrim - Backend Kurulum ve Başlatma Scripti

set -e

echo "🏙️ Benim Şehrim - Backend Kurulumu"
echo "=================================="
echo ""

# Renkli çıktı için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Klasör kontrolü
if [ ! -f "package.json" ]; then
    echo -e "${RED}Hata: Bu scripti backend klasöründen çalıştırın!${NC}"
    echo "  cd backend && ./start.sh"
    exit 1
fi

# Node.js kontrolü
if ! command -v node &> /dev/null; then
    echo -e "${RED}Hata: Node.js yüklü değil!${NC}"
    echo "  brew install node"
    exit 1
fi

echo -e "${YELLOW}1. Bağımlılıklar yükleniyor...${NC}"
npm install

echo ""
echo -e "${YELLOW}2. Prisma client oluşturuluyor...${NC}"
npx prisma generate

# PostgreSQL kontrolü
echo ""
echo -e "${YELLOW}3. PostgreSQL bağlantısı kontrol ediliyor...${NC}"

if command -v psql &> /dev/null; then
    if psql -U postgres -c '\q' 2>/dev/null; then
        echo -e "${GREEN}PostgreSQL bağlantısı başarılı${NC}"
        
        # Veritabanı oluştur
        echo "Veritabanı oluşturuluyor..."
        psql -U postgres -c "CREATE DATABASE benimsehrim;" 2>/dev/null || echo "Veritabanı zaten mevcut"
        
        echo ""
        echo -e "${YELLOW}4. Veritabanı migrasyonları çalıştırılıyor...${NC}"
        npx prisma migrate dev --name init 2>/dev/null || npx prisma migrate deploy
        
        echo ""
        echo -e "${YELLOW}5. Demo veriler yükleniyor...${NC}"
        npx prisma db seed 2>/dev/null || echo "Seed zaten çalıştırılmış olabilir"
        
    else
        echo -e "${YELLOW}PostgreSQL çalışmıyor. Docker kullanabilirsiniz:${NC}"
        echo "  docker run --name benimsehrim-db -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16"
    fi
else
    echo -e "${YELLOW}PostgreSQL yüklü değil. Docker kullanabilirsiniz:${NC}"
    echo "  docker run --name benimsehrim-db -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16"
fi

echo ""
echo -e "${GREEN}✅ Kurulum tamamlandı!${NC}"
echo ""
echo "Backend'i başlatmak için:"
echo "  npm run start:dev"
echo ""
echo "API Swagger docs: http://localhost:3000/docs"
echo ""
echo "Demo Kullanıcılar (OTP: 123456):"
echo "  Admin:    +905001234567"
echo "  Esnaf:    +905001234568"
echo "  Şoför:    +905001234569"
echo "  Kurye:    +905001234570"
echo "  Müşteri:  +905001234571"
