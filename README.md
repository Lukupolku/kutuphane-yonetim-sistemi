<div align="center">

# MEB Okul Kutuphaneleri Yonetim Sistemi

### Turkiye Geneli Okul Kutuphaneleri Icin Birlesik Katalog Platformu

[![React](https://img.shields.io/badge/React-19.2-61DAFB?logo=react&logoColor=white)](https://react.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.9-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Vite](https://img.shields.io/badge/Vite-7.3-646CFF?logo=vite&logoColor=white)](https://vite.dev)
[![License](https://img.shields.io/badge/Lisans-MIT-green.svg)](LICENSE)

---

**Web Dashboard** ile il/ilce/okul bazli kitap envanteri sorgulama | **Mobil Uygulama** ile barkod tarama, kapak OCR ve kitap kaydetme

</div>

---

## Proje Hakkinda

MEB Okul Kutuphaneleri Yonetim Sistemi, Turkiye'deki ~60.000 okulun kutuphane envanterlerini tek bir **Union Catalog** (Birlesik Katalog) altinda dijitallestirmeyi hedefleyen acik kaynakli bir platformdur.

**Temel Fikir:** Ayni ISBN'e sahip kitap tum Turkiye'de tek kayit olarak tutulur. Her okul bu kayda kendi sahiplik bilgisini (holding) ekler. Boylece kitap dagilimi, eksikler ve fazlaliklar ulke genelinde anlik olarak izlenebilir.

### Kimler Icin?

| Rol | Uygulama | Yapabilecekleri |
|-----|----------|-----------------|
| Okul Kutuphanecisi | Mobil | Barkod tara, kapak/raf OCR ile kitap kaydet, envanter yonet |
| Ilce Muduru | Web | Ilcesindeki tum okullarin kitap dagilimini incele, karsilastir |
| Il Muduru | Web | Il genelinde istatistikleri gor, eksikleri tespit et |
| Bakanlik Yetkisi | Web | Tum Turkiye'yi izle, okullar arasi karsilastirma yap |

---

## Ozellikler

### Web Dashboard

- **Hiyerarsik Filtreleme** — Il > Ilce > Okul kademeli secim, rol bazli kapsam kilitleme
- **Istatistik Paneli** — Farkli eser, toplam kopya, ogrenci basina kitap, okul basina kopya
- **Kademe Bazli Ozet** — Ilkokul / Ortaokul / Lise ayri istatistik kartlari
- **Kitap Katalogu** — Baslik, yazar, ISBN ile arama; siralanabilir kolonlar
- **Kitap Detay** — Hangi okullarda kac adet oldugu, sahiplik tablosu
- **Okullar Arasi Karsilastirma** — 8 okula kadar secim, isi haritasi (heat map) gorunumu
- **CSV/Excel Export** — UTF-8 BOM ile Turkce karakter destekli dosya indirme
- **Rol Bazli Giris** — Bakanlik, il, ilce, okul rolleri; oturum yonetimi
- **Responsive Tasarim** — Masaustu, tablet, mobil uyumlu; hamburger menu
- **Hata Yonetimi** — ErrorBoundary, 404 sayfasi, kullanici dostu Turkce mesajlar

### Mobil Uygulama (Flutter)

- **Barkod Tarama** — Kamera ile ISBN-13 barkod okuma, animasyonlu tarayici
- **Kapak OCR** — Kitap kapagindan baslik/yazar cikartma (ML Kit)
- **Raf OCR** — Raf etiketinden toplu kitap tespiti
- **ISBN Arama** — Google Books API > Open Library API > Manuel giris (fallback zinciri)
- **Envanter Listesi** — Okulun mevcut kitaplarini goruntuleme ve duzenleme
- **Excel Import** — Toplu kitap yuklemesi
- **MEB Markalama** — Kurumsal bordo tema, MEB logosu, splash screen

---

## Mimari

```
kutuphane-yonetim-sistemi/
|
├── apps/
│   ├── web/                 React + TypeScript + Vite
│   │   ├── src/
│   │   │   ├── components/  BookTable, HierarchyFilter, Layout, ErrorBoundary
│   │   │   ├── pages/       Dashboard, Search, BookDetail, Compare, Login, 404
│   │   │   ├── services/    Mock API (backend-agnostic arayuz)
│   │   │   ├── contexts/    AuthContext (oturum yonetimi)
│   │   │   ├── hooks/       useSort (generic siralama)
│   │   │   └── utils/       CSV export
│   │   └── public/          Statik dosyalar, favicon, logo
│   │
│   └── mobile/              Flutter (iOS + Android)
│       └── lib/
│           ├── models/      Book, School, Holding, User
│           ├── providers/   Auth, Inventory, School (ChangeNotifier)
│           ├── repositories/ Abstract + Mock implementasyonlar
│           ├── services/    ISBN lookup, OCR, mock data
│           ├── screens/     Tum ekranlar (12 ekran)
│           └── widgets/     Yeniden kullabilir widget'lar
│
├── packages/
│   └── shared/              Her iki uygulamanin ortak katmani
│       ├── models/          JSON Schema tanimlari (OpenAPI uyumlu)
│       └── mock-data/       15 kitap, 12 okul, 41 sahiplik kaydi
│
└── docs/
    └── plans/               Tasarim dokumanlari, yol haritasi
```

### Veri Modeli — Union Catalog

```
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│    Book      │       │   Holding    │       │   School    │
│─────────────│       │──────────────│       │─────────────│
│ id           │◄──────│ bookId       │       │ id          │
│ isbn         │       │ schoolId     │──────►│ name        │
│ title        │       │ quantity     │       │ province    │
│ authors[]    │       │ addedBy      │       │ district    │
│ publisher    │       │ addedAt      │       │ schoolType  │
│ source       │       │ source       │       │ studentCount│
└─────────────┘       └──────────────┘       └─────────────┘
                  (Ayni ISBN = tek Book kaydi,
                   her okul kendi Holding'ini ekler)
```

---

## Hizli Baslangic

### Gereksinimler

| Arac | Surum | Notlar |
|------|-------|--------|
| Node.js | 18+ | Web dashboard icin |
| npm | 9+ | Paket yoneticisi |
| Flutter SDK | 3.7+ | Mobil uygulama icin (opsiyonel) |

### Web Dashboard

```bash
# Repoyu klonla
git clone https://github.com/Lukupolku/kutuphane-yonetim-sistemi.git
cd kutuphane-yonetim-sistemi

# Web uygulamasini baslat
cd apps/web
npm install
npm run dev
```

Tarayicida `http://localhost:5173` adresini ac. Demo giris bilgileri:

| Alan | Deger |
|------|-------|
| E-posta | `demo` (@meb.k12.tr otomatik eklenir) |
| Sifre | `123456` |
| Rol | Bakanlik, Il, Ilce veya Okul sec |

### Mobil Uygulama

```bash
cd apps/mobile
flutter pub get
flutter run
```

### Testler

```bash
# Web testleri
cd apps/web
npx vitest run

# Mobil testleri
cd apps/mobile
flutter test

# Tip kontrolu (web)
cd apps/web
npx tsc --noEmit
```

---

## Teknoloji Yigini

### Web Dashboard

| Teknoloji | Kullanim |
|-----------|----------|
| **React 19** | UI framework |
| **TypeScript 5.9** | Tip guvenligi |
| **Vite 7** | Build araci ve dev server |
| **react-router-dom** | Sayfa yonlendirme |
| **TanStack Query** | Sunucu durumu yonetimi |
| **lucide-react** | Ikon kutuphanesi |
| **xlsx** | Excel dosya isleme |
| **Vitest** | Test framework |

### Mobil Uygulama

| Teknoloji | Kullanim |
|-----------|----------|
| **Flutter 3.7+** | Cross-platform framework |
| **Provider** | Durum yonetimi |
| **mobile_scanner** | Barkod tarama |
| **google_mlkit_text_recognition** | OCR (kapak/raf okuma) |
| **shared_preferences** | Yerel veri saklama |
| **http** | API istekleri |
| **google_fonts** | Tipografi (Outfit, Nunito) |

---

## Mock Veri

Gercek backend hazir olana kadar her iki uygulama yerlesik mock veri ile calisir:

| Veri | Adet | Detay |
|------|------|-------|
| Kitaplar | 15 | 13'u ISBN'li, 2'si manuel giris |
| Okullar | 12 | 3 il (Ankara, Istanbul, Izmir), 2'ser ilce |
| Sahiplikler | 41 | Kitap-okul eslestirmeleri |
| Kademeler | 3 | Ilkokul, Ortaokul, Lise |

> API arayuzu soyutlanmis durumdadir. Gercek backend'e gecis icin yalnizca servis implementasyonu degistirilir — UI kodu degismez.

---

## Yol Haritasi

| Faz | Durum | Aciklama |
|-----|-------|----------|
| **Faz 0** — MVP | Tamamlandi | Monorepo, mock data, temel ekranlar |
| **Faz 0.5** — Web Zenginlestirme | Tamamlandi | Rol bazli auth, istatistikler, karsilastirma, responsive |
| **Faz 1** — Backend | Baslanmadi | Node.js API, PostgreSQL, gercek veri katmani |
| **Faz 2** — Kimlik Dogrulama | Baslanmadi | JWT auth, MEB e-okul SSO entegrasyonu |
| **Faz 3** — Odunc Verme | Baslanmadi | Sirkulasyon sistemi, ogrenci kaydi |
| **Faz 4** — Gelismis Ozellikler | Baslanmadi | Offline-first, bildirimler, oneri sistemi |
| **Faz 5** — Olceklendirme | Baslanmadi | 60.000+ okul, CDN, read-replica |

Detayli yol haritasi: [`docs/plans/roadmap.md`](docs/plans/roadmap.md)

---

## Tasarim Kararlari

| Karar | Gerekce |
|-------|---------|
| **Union Catalog** modeli | Ayni kitabin tekrar tekrar tanimlanmasini onler, olceklenebilir |
| **2 ayri uygulama** (Flutter + React) | Farkli kullanici profilleri, farkli guclu yanlar |
| **Monorepo** yapisi | Ortak modeller ve mock data paylasimi, bagimsiz build/deploy |
| **Backend-agnostic baslangic** | Frontend'leri olgunlastir, mock data ile dogrula |
| **ISBN fallback zinciri** | Google Books > Open Library > Manuel: Turkce kitap kapsamini maksimize etme |
| **MEB kurumsal tema** | Bordo/kirmizi renk paleti, resmi gorunum |
| **Heat map karsilastirma** | Kitap dagilimini hizlica gorsellestirme, eksikleri tespit etme |

---

## Katki

1. Bu repoyu fork'layin
2. Feature branch olusturun (`git checkout -b feat/yeni-ozellik`)
3. Degisikliklerinizi commit'leyin (`git commit -m 'feat: yeni ozellik aciklamasi'`)
4. Branch'inizi push'layin (`git push origin feat/yeni-ozellik`)
5. Pull Request acin

### Commit Mesaj Formati

```
feat: yeni ozellik
fix: hata duzeltmesi
docs: dokumantasyon
refactor: yeniden yapilandirma
test: test ekleme/duzeltme
```

---

## Lisans

Bu proje [MIT Lisansi](LICENSE) ile lisanslanmistir.

---

<div align="center">

**MEB Okul Kutuphaneleri Yonetim Sistemi** — Turkiye'nin okul kutuphanelerini dijitallestiriyoruz.

[Web Dashboard](apps/web/) | [Mobil Uygulama](apps/mobile/) | [Yol Haritasi](docs/plans/roadmap.md)

</div>
