# MVP Tasarım Dokümanı — Kütüphane Yönetim Sistemi

**Tarih:** 2026-03-05
**Durum:** Onaylandı
**Paydaş:** MEB (Milli Eğitim Bakanlığı) ortaklığı ile okullar arası kütüphane envanter sistemi

---

## 1. Vizyon

Türkiye genelindeki K-12 okullarının kütüphane envanterlerini dijitalleştiren, merkezi bir Union Catalog modeli üzerine kurulu sistem. Okullar mobil uygulamayla kitaplarını tarayıp kaydeder, yetkili kullanıcılar web dashboard üzerinden okul/ilçe/il/ülke genelinde kitap envanterini sorgular.

## 2. Mimari Kararlar

### 2.1 Union Catalog Modeli

Dünya standartlarındaki K-12 kütüphane sistemlerinden (Follett Destiny, Alexandria, Koha) esinlenilmiştir. Tek bir merkezi kitap kataloğu bulunur, her okul bu katalogdaki kitaplara "holding" (sahiplik) kaydı ekler. Aynı kitap sisteme bir kez girer, binlerce okul aynı kaydı paylaşır.

```
┌─────────────────────────────────┐
│       Merkezi Kitap Kataloğu    │
│  (ISBN, başlık, yazar, kapak)   │
└──────────────┬──────────────────┘
               │ 1:N
    ┌──────────┼──────────┐
    ▼          ▼          ▼
 Okul A     Okul B     Okul C
 holding    holding    holding
 (adet,     (adet,     (adet,
  tarih)     tarih)     tarih)
```

### 2.2 Uygulama Yapısı — 2 Ayrı Uygulama

| Uygulama | Teknoloji | Kullanıcı | Amaç |
|----------|-----------|-----------|------|
| **Mobil** | Flutter (iOS + Android) | Okul kütüphanecisi | Kitap tarama, kaydetme, okul envanteri görüntüleme |
| **Web Dashboard** | React + TypeScript | İlçe/İl/Bakanlık yetkilileri | Hiyerarşik kitap sorgulama, filtreleme |

### 2.3 Teknoloji Stack

- **Mobil:** Flutter + Google ML Kit (barkod + OCR)
- **Web:** React + TypeScript + Vite
- **Backend:** Soyutlanmış (mock data layer) — ileride Node.js + PostgreSQL
- **Kitap Veri Kaynağı:** Google Books API → Open Library API → Manuel giriş (fallback zinciri)
- **Repo Yapısı:** Monorepo

### 2.4 Monorepo Yapısı

```
kutuphane-yonetim-sistemi/
├── apps/
│   ├── mobile/              # Flutter projesi
│   │   ├── lib/
│   │   │   ├── models/      # Kitap, Okul, Holding modelleri
│   │   │   ├── services/    # API client, ISBN lookup, OCR service
│   │   │   ├── screens/     # Tarama, kayıt, envanter ekranları
│   │   │   └── widgets/     # Ortak UI bileşenleri
│   │   └── pubspec.yaml
│   └── web/                 # React projesi
│       ├── src/
│       │   ├── components/  # UI bileşenleri
│       │   ├── pages/       # Dashboard, arama, detay sayfaları
│       │   ├── services/    # API client, mock data
│       │   └── types/       # TypeScript tip tanımları
│       └── package.json
├── packages/
│   └── shared/              # Ortak kontratlar
│       ├── models/          # JSON Schema — kitap, okul, holding
│       ├── mock-data/       # Geliştirme için sahte veri
│       └── api-contracts/   # API endpoint tanımları (OpenAPI/JSON)
├── docs/
│   └── plans/               # Tasarım ve yol haritası
└── README.md
```

## 3. Veri Modeli

### 3.1 Book (Kitap — Merkezi Katalog)

| Alan | Tip | Açıklama |
|------|-----|----------|
| id | UUID | Sistem ID |
| isbn | string? | ISBN-13 (nullable — ISBN'siz kitaplar için) |
| title | string | Kitap başlığı |
| authors | string[] | Yazar(lar) |
| publisher | string? | Yayınevi |
| publishedDate | string? | Basım yılı |
| pageCount | number? | Sayfa sayısı |
| coverImageUrl | string? | Kapak görseli URL |
| language | string | Dil kodu (tr, en, ...) |
| source | enum | GOOGLE_BOOKS, OPEN_LIBRARY, MANUAL, OCR |
| createdAt | datetime | Oluşturulma tarihi |

### 3.2 School (Okul)

| Alan | Tip | Açıklama |
|------|-----|----------|
| id | UUID | Sistem ID |
| name | string | Okul adı |
| province | string | İl |
| district | string | İlçe |
| schoolType | enum | ILKOKUL, ORTAOKUL, LISE |
| ministryCode | string | MEB okul kodu |

### 3.3 Holding (Sahiplik Kaydı)

| Alan | Tip | Açıklama |
|------|-----|----------|
| id | UUID | Sistem ID |
| bookId | UUID | Kitap referansı |
| schoolId | UUID | Okul referansı |
| quantity | number | Adet (varsayılan: 1) |
| addedBy | string | Kaydeden kullanıcı |
| addedAt | datetime | Kayıt tarihi |
| source | enum | BARCODE_SCAN, COVER_OCR, SHELF_OCR, MANUAL |

## 4. Mobil Uygulama — Kullanıcı Akışları

### 4.1 ISBN Barkod Tarama

```
Kamera aç → Barkod algıla → ISBN çıkar
  → Google Books API'de ara
    → Bulursa: kitap bilgilerini göster → "Kaydet" butonu
    → Bulamazsa: Open Library'de ara
      → Bulursa: kitap bilgilerini göster → "Kaydet" butonu
      → Bulamazsa: Manuel giriş formu (boş)
```

### 4.2 Kitap Kapağı OCR

```
Kamera aç → Fotoğraf çek → ML Kit OCR çalıştır
  → Algılanan metin → Başlık/yazar alanlarını otomatik doldur
  → Kullanıcı düzenler → "Kaydet" butonu
```

### 4.3 Raf Fotoğrafı ile Toplu Giriş

```
Kamera aç → Raf fotoğrafı çek → OCR çalıştır
  → Kitap sırtlarındaki metinleri ayrıştır
  → Her kitap için ayrı kart oluştur (düzenlenebilir)
  → Kullanıcı seçtiklerini toplu kaydeder
```

### 4.4 Okul Envanter Görüntüleme

```
Ana ekran → "Kitaplarımız" sekmesi
  → Okulun kayıtlı kitap listesi (arama + filtreleme)
  → Kitap detayında: kapak, bilgiler, eklenme tarihi, adet
```

## 5. Web Dashboard — Kullanıcı Akışları

### 5.1 Hiyerarşik Sorgulama

```
Giriş → Coğrafi filtre seç:
  ├── Bakanlık: Tüm Türkiye
  ├── İl: Bir il seç → o ildeki tüm okullar
  ├── İlçe: İl + ilçe seç → o ilçedeki okullar
  └── Okul: Spesifik okul seç

→ Seçime göre kitap listesi (toplam adet, okul sayısı)
→ Kitap detay: Hangi okullarda var, kaç adet
```

### 5.2 Kitap Arama

```
Arama çubuğu → Başlık/yazar/ISBN ile ara
  → Sonuçlar listesi
  → Kitap seç → Hangi okullarda mevcut (harita veya liste)
```

## 6. MVP Dışında Kalan (Sonraki Fazlar)

Detaylı yol haritası: [roadmap.md](./roadmap.md)

## 7. Açık Sorular (Backend Fazında Cevaplanacak)

- Kimlik doğrulama mekanizması (MEB e-okul entegrasyonu vs bağımsız)
- Hosting stratejisi (MEB altyapısı vs bulut)
- Veri yedekleme ve KVKK uyumluluğu
- Offline-first sync stratejisi (internet kesintisinde tarama yapılabilmesi)
