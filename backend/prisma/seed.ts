import { PrismaClient, UserRole, PaymentType, CampaignType } from '@prisma/client';
import { v4 as uuid } from 'uuid';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // 1. Şehir ve İlçeler
  const kirsehir = await prisma.city.create({
    data: {
      id: uuid(),
      name: 'Kırşehir',
      code: '40',
      latitude: 39.1425,
      longitude: 34.1709,
      isActive: true,
    },
  });

  const districts = await Promise.all([
    prisma.district.create({
      data: { name: 'Merkez', cityId: kirsehir.id, latitude: 39.1425, longitude: 34.1709 },
    }),
    prisma.district.create({
      data: { name: 'Kaman', cityId: kirsehir.id, latitude: 39.3572, longitude: 33.7236 },
    }),
    prisma.district.create({
      data: { name: 'Mucur', cityId: kirsehir.id, latitude: 39.0633, longitude: 34.3917 },
    }),
  ]);

  console.log('✅ Cities and districts created');

  // 2. Kategoriler
  const categories = await Promise.all([
    prisma.category.create({ data: { name: 'Kasap', icon: '🥩', sortOrder: 1 } }),
    prisma.category.create({ data: { name: 'Fırın', icon: '🍞', sortOrder: 2 } }),
    prisma.category.create({ data: { name: 'Market', icon: '🛒', sortOrder: 3 } }),
    prisma.category.create({ data: { name: 'Manav', icon: '🥬', sortOrder: 4 } }),
    prisma.category.create({ data: { name: 'Restoran', icon: '🍽️', sortOrder: 5 } }),
    prisma.category.create({ data: { name: 'Cafe', icon: '☕', sortOrder: 6 } }),
    prisma.category.create({ data: { name: 'Eczane', icon: '💊', sortOrder: 7 } }),
    prisma.category.create({ data: { name: 'Kırtasiye', icon: '📚', sortOrder: 8 } }),
  ]);

  console.log('✅ Categories created');

  // 3. Feature Flags (MVP'de hepsi ücretsiz)
  const featureFlags = [
    { key: 'UNLIMITED_PRODUCTS', name: 'Sınırsız Ürün', defaultValue: true, isPremium: false },
    { key: 'UNLIMITED_CAMPAIGNS', name: 'Sınırsız Kampanya', defaultValue: true, isPremium: false },
    { key: 'PRIORITY_LISTING', name: 'Öne Çıkarma', defaultValue: false, isPremium: true },
    { key: 'ADVANCED_ANALYTICS', name: 'Gelişmiş Analitik', defaultValue: false, isPremium: true },
    { key: 'MULTI_BRANCH', name: 'Çoklu Şube', defaultValue: false, isPremium: true },
    { key: 'API_ACCESS', name: 'API Erişimi', defaultValue: false, isPremium: true },
    { key: 'BULK_IMPORT', name: 'Toplu Ürün Yükleme', defaultValue: false, isPremium: true },
    { key: 'COMMISSION_FREE', name: 'Komisyonsuz', defaultValue: true, isPremium: false },
    { key: 'FREE_SMS', name: 'Ücretsiz SMS', defaultValue: true, isPremium: false },
  ];

  await Promise.all(
    featureFlags.map((flag) =>
      prisma.featureFlag.create({ data: flag }),
    ),
  );

  console.log('✅ Feature flags created');

  // 4. Subscription Plans (Hazır ama pasif)
  await Promise.all([
    prisma.subscriptionPlan.create({
      data: {
        name: 'Ücretsiz',
        slug: 'free',
        price: 0,
        isActive: true,
        features: ['UNLIMITED_PRODUCTS', 'UNLIMITED_CAMPAIGNS', 'COMMISSION_FREE'],
      },
    }),
    prisma.subscriptionPlan.create({
      data: {
        name: 'Başlangıç',
        slug: 'starter',
        price: 299,
        billingPeriod: 'monthly',
        isActive: false,
        features: ['UNLIMITED_PRODUCTS', 'UNLIMITED_CAMPAIGNS', 'PRIORITY_LISTING'],
      },
    }),
    prisma.subscriptionPlan.create({
      data: {
        name: 'Profesyonel',
        slug: 'pro',
        price: 599,
        billingPeriod: 'monthly',
        isActive: false,
        features: ['UNLIMITED_PRODUCTS', 'UNLIMITED_CAMPAIGNS', 'PRIORITY_LISTING', 'ADVANCED_ANALYTICS', 'BULK_IMPORT'],
      },
    }),
  ]);

  console.log('✅ Subscription plans created');

  // 5. Demo Kullanıcılar
  const adminUser = await prisma.user.create({
    data: {
      phone: '+905001234567',
      name: 'Admin',
      email: 'admin@benimsehrim.com',
      role: UserRole.ADMIN,
      cityId: kirsehir.id,
      districtId: districts[0].id,
    },
  });

  const vendorUser = await prisma.user.create({
    data: {
      phone: '+905001234568',
      name: 'Demo Esnaf',
      email: 'esnaf@benimsehrim.com',
      role: UserRole.VENDOR,
      cityId: kirsehir.id,
      districtId: districts[0].id,
    },
  });

  const driverUser = await prisma.user.create({
    data: {
      phone: '+905001234569',
      name: 'Demo Şoför',
      email: 'sofor@benimsehrim.com',
      role: UserRole.TAXI_DRIVER,
      cityId: kirsehir.id,
      districtId: districts[0].id,
    },
  });

  const courierUser = await prisma.user.create({
    data: {
      phone: '+905001234570',
      name: 'Demo Kurye',
      email: 'kurye@benimsehrim.com',
      role: UserRole.COURIER,
      cityId: kirsehir.id,
      districtId: districts[0].id,
    },
  });

  const customerUser = await prisma.user.create({
    data: {
      phone: '+905001234571',
      name: 'Demo Müşteri',
      email: 'musteri@benimsehrim.com',
      role: UserRole.USER,
      cityId: kirsehir.id,
      districtId: districts[0].id,
    },
  });

  console.log('✅ Demo users created');

  // 6. Demo Mağaza
  const demoStore = await prisma.store.create({
    data: {
      userId: vendorUser.id,
      cityId: kirsehir.id,
      name: 'Kırşehir Kasabı',
      description: '1985 yılından beri Kırşehir halkına kaliteli et ürünleri sunuyoruz.',
      address: 'Atatürk Caddesi No: 45',
      latitude: 39.1425,
      longitude: 34.1709,
      phone: '+905001234568',
      isOpen: true,
      openTime: '08:00',
      closeTime: '22:00',
      isApproved: true,
      paymentTypes: [PaymentType.CASH, PaymentType.CARD],
      minOrder: 50,
      deliveryFee: 10,
      rating: 4.8,
      reviewCount: 128,
      categories: { connect: [{ id: categories[0].id }] },
    },
  });

  // 7. Demo Ürünler
  const products = await Promise.all([
    prisma.product.create({
      data: {
        storeId: demoStore.id,
        categoryId: categories[0].id,
        name: 'Dana Kıyma',
        description: 'Taze çekilmiş dana kıyma, günlük kesim',
        price: 280,
        stock: 50,
        unit: 'kg',
        images: ['https://placeholder.com/meat1.jpg', 'https://placeholder.com/meat2.jpg'],
        isActive: true,
      },
    }),
    prisma.product.create({
      data: {
        storeId: demoStore.id,
        categoryId: categories[0].id,
        name: 'Kuzu Pirzola',
        description: 'Taze kuzu pirzola',
        price: 320,
        stock: 30,
        unit: 'kg',
        images: ['https://placeholder.com/lamb1.jpg', 'https://placeholder.com/lamb2.jpg'],
        isActive: true,
      },
    }),
    prisma.product.create({
      data: {
        storeId: demoStore.id,
        categoryId: categories[0].id,
        name: 'Biftek',
        description: 'Premium biftek',
        price: 450,
        stock: 20,
        unit: 'kg',
        images: ['https://placeholder.com/steak1.jpg', 'https://placeholder.com/steak2.jpg'],
        isActive: true,
      },
    }),
  ]);

  console.log('✅ Demo products created');

  // 8. Demo Kampanya
  await prisma.campaign.create({
    data: {
      storeId: demoStore.id,
      productId: products[0].id,
      type: CampaignType.PERCENTAGE,
      value: 20,
      startDate: new Date(),
      endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      stockLimit: 50,
      isActive: true,
    },
  });

  console.log('✅ Demo campaign created');

  // 9. Demo Taksi Şoförü
  await prisma.driver.create({
    data: {
      userId: driverUser.id,
      vehiclePlate: '40 ABC 123',
      vehicleModel: 'Fiat Egea',
      vehicleColor: 'Beyaz',
      licenseNo: 'A12345678',
      isOnline: true,
      isApproved: true,
      latitude: 39.1430,
      longitude: 34.1715,
      rating: 4.9,
      reviewCount: 256,
    },
  });

  console.log('✅ Demo driver created');

  // 10. Demo Kurye
  await prisma.courier.create({
    data: {
      userId: courierUser.id,
      vehicleType: 'Motosiklet',
      isOnline: true,
      isApproved: true,
      latitude: 39.1420,
      longitude: 34.1700,
      rating: 4.7,
      reviewCount: 89,
      maxDaily: 20,
    },
  });

  console.log('✅ Demo courier created');

  // 11. Demo Adres
  await prisma.address.create({
    data: {
      userId: customerUser.id,
      title: 'Ev',
      address: 'Atatürk Mahallesi 123 Sokak No:5',
      latitude: 39.1400,
      longitude: 34.1680,
      note: 'Sarı bina, 3. kat',
      isDefault: true,
    },
  });

  console.log('✅ Demo address created');

  console.log('');
  console.log('🎉 Database seeded successfully!');
  console.log('');
  console.log('Demo Kullanıcılar:');
  console.log('  Admin:    +905001234567');
  console.log('  Esnaf:    +905001234568');
  console.log('  Şoför:    +905001234569');
  console.log('  Kurye:    +905001234570');
  console.log('  Müşteri:  +905001234571');
  console.log('');
  console.log('Development modunda OTP: 123456');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
