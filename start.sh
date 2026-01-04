#!/bin/bash

# Benim Şehrim - Tüm Proje Hızlı Başlatma Scripti

set -e

echo ""
echo "🏙️ ======================================"
echo "   Benim Şehrim - Proje Başlatma"
echo "========================================"
echo ""

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📦 1. Backend kurulumu...${NC}"
cd "$PROJECT_DIR/backend"
npm install --silent
npx prisma generate
echo -e "${GREEN}   ✅ Backend hazır${NC}"

echo ""
echo -e "${BLUE}🎨 2. Admin Panel kurulumu...${NC}"
cd "$PROJECT_DIR/admin"
npm install --silent
echo -e "${GREEN}   ✅ Admin Panel hazır${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Tüm bağımlılıklar yüklendi!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Başlatmak için:"
echo ""
echo -e "${YELLOW}1. PostgreSQL başlat:${NC}"
echo "   docker run --name benimsehrim-db -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16"
echo ""
echo -e "${YELLOW}2. Redis başlat (opsiyonel):${NC}"
echo "   docker run --name benimsehrim-redis -p 6379:6379 -d redis:7-alpine"
echo ""
echo -e "${YELLOW}3. Backend başlat:${NC}"
echo "   cd backend && npm run start:dev"
echo ""
echo -e "${YELLOW}4. Admin Panel başlat:${NC}"
echo "   cd admin && npm run dev"
echo ""
echo "Veya Docker Compose ile hepsini başlat:"
echo "   docker-compose up -d"
echo ""
echo -e "${BLUE}📖 API Docs:${NC} http://localhost:3000/docs"
echo -e "${BLUE}🎨 Admin:${NC}    http://localhost:5173"
echo ""
