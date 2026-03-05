# Kütüphane Yönetim Sistemi

MEB ortaklığı ile Türkiye genelindeki K-12 okullarının kütüphane envanterlerini dijitalleştiren Union Catalog tabanlı sistem.

## Mimari

**Monorepo** yapısında iki ayrı uygulama:

- **Mobil Uygulama** (`apps/mobile/`) — Flutter, okul kütüphanecileri için kitap tarama ve kaydetme
- **Web Dashboard** (`apps/web/`) — React + TypeScript, ilçe/il/bakanlık yetkilileri için kitap sorgulama

Her iki uygulama aynı veri modellerini (`packages/shared/`) ve ileride aynı backend API'yi kullanır.

## Hızlı Başlangıç

### Web Dashboard

```bash
cd apps/web
npm install
npm run dev        # http://localhost:5173
npm run build      # Üretim build
npx vitest run     # Testler
```

### Mobil Uygulama (Flutter SDK gerekli)

```bash
cd apps/mobile
flutter pub get
flutter test
flutter run
```

## Proje Yapısı

```
├── apps/
│   ├── mobile/          # Flutter (iOS + Android)
│   └── web/             # React + TypeScript + Vite
├── packages/
│   └── shared/          # Ortak modeller, mock data, API kontratları
└── docs/
    └── plans/           # Tasarım dokümanları ve yol haritası
```

## Veri Modeli (Union Catalog)

- **Book** — Merkezi kitap kataloğu (ISBN, başlık, yazar, yayınevi)
- **School** — Okul bilgileri (ad, il, ilçe, tür, MEB kodu)
- **Holding** — Sahiplik kaydı (hangi okul, hangi kitap, kaç adet)

## Mevcut Durum

- [x] Monorepo yapısı ve paylaşılan modeller
- [x] Web dashboard (hiyerarşik filtre, kitap arama, detay sayfası)
- [x] Flutter proje iskeleti ve veri modelleri
- [ ] Flutter tarama ekranları (Flutter SDK kurulumu gerekli)
- [ ] Backend API (Faz 1)
- [ ] Kimlik doğrulama (Faz 2)

Detaylı yol haritası: [docs/plans/roadmap.md](docs/plans/roadmap.md)
