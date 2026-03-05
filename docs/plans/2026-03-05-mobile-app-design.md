# Mobil Uygulama Tasarımı — Kütüphane Yönetim Sistemi

**Tarih:** 2026-03-05
**Kapsam:** Faz 0 MVP — Tam kapsam (ISBN tarama + kapak OCR + raf OCR + kaydetme + envanter listesi)

---

## Ekran Akışı

Tek akış navigasyonu: Ana sayfa envanter listesi, FAB ile kitap ekleme.

```
Okul Seçimi (ilk açılış) → Envanter Listesi (ana sayfa)
                                    │ FAB
                                    ▼
                              Bottom Sheet
                    ┌─────────┬──────────┬─────────┐
                    ▼         ▼          ▼         ▼
               Barkod Tara  Kapak OCR  Raf OCR  Manuel
                    │         │          │         │
                    ▼         ▼          ▼         │
                 Kamera     Kamera    Kamera       │
                    │         │          │         │
                    ▼         ▼          ▼         │
               Kitap Onay  Kitap Onay  Toplu      │
               Ekranı      Ekranı     Seçim      │
                    │         │       Listesi     │
                    │         │          │         │
                    └─────────┴──────────┴─────────┘
                                    │
                                    ▼
                          Envanter Listesi (güncellendi)
```

Manuel giriş doğrudan Kitap Onay Ekranı'nın boş form haliyle açılır.

---

## Mimari

### Katmanlar

```
UI (Screens) → State (Providers) → Services/Repos → Data (Mock)
```

### Ekranlar
- SchoolSelectionScreen — İlk açılışta il → ilçe → okul seçimi
- InventoryScreen — Holding listesi + FAB
- BarcodeScanScreen — mobile_scanner ile barkod okuma
- CoverOcrScreen — Fotoğraf çekip ML Kit ile metin tanıma
- ShelfOcrScreen — Raf fotoğrafı çekip çoklu metin tanıma
- BookConfirmScreen — Kitap bilgi onay/düzenleme formu
- ShelfResultsScreen — Raf OCR sonuçları checkbox listesi

### Provider'lar
- SchoolProvider — Seçili okul state'i, SharedPreferences'a persist
- InventoryProvider — Holding CRUD (mevcut okula filtreli)
- BookProvider — Kitap arama, oluşturma

### Servisler ve Repository'ler
- BookRepository (abstract) → MockBookRepository
- SchoolRepository (abstract) → MockSchoolRepository
- IsbnLookupService — Fallback zinciri: Google Books → Open Library → null
- OcrService — ML Kit text recognition wrapper

### Veri Katmanı
- packages/shared/mock-data/*.json asset olarak bundle'lanır
- Backend geldiğinde sadece repository implementasyonu değişir

---

## Veri Akışları

### Barkod Tarama
1. Kamera → mobile_scanner ISBN algılar
2. IsbnLookupService.lookup(isbn) — mock repo'da var mı → API fallback (mock) → null
3. BookConfirmScreen'e Book veya boş form gönderilir
4. Kullanıcı onaylar → InventoryProvider.addHolding()
5. Book yoksa önce oluşturulur, holding eklenir
6. Aynı okulda aynı ISBN varsa quantity artırılır

### Kapak OCR
1. image_picker ile fotoğraf → OcrService.extractText()
2. Çıkan metinden başlık/yazar parse → IsbnLookupService.searchByTitle() (mock)
3. BookConfirmScreen'e sonuç veya parse edilen metin
4. Aynı onay/kaydet akışı

### Raf OCR
1. image_picker ile fotoğraf → OcrService.extractMultipleTexts()
2. ShelfResultsScreen: checkbox listesi
3. Kullanıcı seçer → her biri için ISBN araması
4. Toplu holding kaydı → envanter listesine dön

### Okul Seçimi
1. İlk açılış → SharedPreferences'ta schoolId var mı?
2. Yoksa → SchoolSelectionScreen (cascading dropdown)
3. Varsa → doğrudan InventoryScreen

---

## Hata Yönetimi

| Durum | Davranış |
|-------|----------|
| ISBN bulunamadı | Mesaj + boş manuel giriş formu |
| OCR metni okunamadı | "Tekrar deneyin veya manuel girin" + seçenek |
| Kamera izni reddedildi | Açıklama + ayarlara yönlendirme |
| Aynı ISBN tekrar taranırsa | Mevcut Book kullanılır, holding quantity artırılır |
| ISBN'siz kitap | uuid ile ID, isbn: null |
| Raf OCR hiçbir metin bulamadı | Mesaj + tekrar çek seçeneği |
| Raf OCR çok fazla sonuç | Scrollable liste + "Tümünü Seç/Kaldır" toggle |

Offline: Mock data yerel, MVP'de sorun yok. Gerçek offline-first Faz 4'te.

---

## Test Stratejisi

### Unit Testler
- Model fromJson/toJson (mevcut)
- Repository CRUD işlemleri
- IsbnLookupService fallback zinciri
- OcrService metin parse mantığı

### Widget Testler
- SchoolSelectionScreen cascading dropdown
- InventoryScreen liste render + FAB → bottom sheet
- BookConfirmScreen form validasyonu
- ShelfResultsScreen checkbox seçimi + toplu kayıt

### Integration Testler
- MVP'de yok, Faz 1'de backend ile birlikte
