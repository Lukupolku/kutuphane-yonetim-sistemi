# Yol Haritası — Kütüphane Yönetim Sistemi

**Son güncelleme:** 2026-03-06

---

## Faz 0: MVP — TAMAMLANDI

- [x] Tasarım dokümanı onaylandı
- [x] Monorepo yapısı kurulumu
- [x] Shared paket: modeller, mock data, API kontratları
- [x] Flutter mobil uygulama (ISBN tarama, kapak OCR, raf OCR, kaydetme, envanter listesi)
- [x] React web dashboard (hiyerarşik sorgulama, kitap arama)
- [x] Mock data layer (backend soyutlanmış)

## Faz 0.5: Web Zenginleştirme — TAMAMLANDI

- [x] Rol bazlı giriş ekranı (Bakanlık / İl / İlçe / Okul)
- [x] AuthContext + ProtectedRoute + SessionStorage persistence
- [x] MEB kurumsal kimlik (bordo/kırmızı tema, MEB logosu, favicon)
- [x] Dashboard: İstatistik kartları (farklı eser, toplam kopya, okul sayısı, öğrenci başına, okul başına)
- [x] Dashboard: Okul bazlı istatistik tablosu (sortable)
- [x] Kitap Kataloğu sayfası (arama, filtreleme, CSV export)
- [x] Okullar arası karşılaştırma sayfası (heat map, summary row, sortable)
- [x] Tüm tablolarda sıralanabilir sütunlar (useSort hook + SortHeader)
- [x] Excel import modal (okul rolü)
- [x] CSV export (UTF-8 BOM, Türkçe Excel uyumlu)
- [x] HierarchyFilter scope locking (rol bazlı)
- [x] studentCount alanı eklendi (shared + web + mock data)

---

## Faz 1: Backend ve Veritabanı

**Önkoşul:** MVP tamamlanmış, kullanıcı akışları doğrulanmış
**Durum:** Başlanmadı

### Görevler

- [ ] Node.js + Express (veya Fastify) API sunucusu
- [ ] PostgreSQL veritabanı şeması (books, schools, holdings tabloları)
- [ ] Coğrafi hiyerarşi tabloları (provinces, districts) — MEB verileriyle seed
- [ ] Mock data layer'ı gerçek API client ile değiştirme
- [ ] Google Books API ve Open Library API entegrasyonu (server-side proxy)
- [ ] Kitap kapak görselleri için dosya depolama (S3 veya benzeri)
- [ ] CI/CD pipeline: mobil için path-filtered build, web için ayrı deploy

### Veritabanı Notları

- Union Catalog modeli: `books` tablosu unique ISBN constraint ile
- `holdings` tablosu: `(book_id, school_id)` composite unique — aynı okul aynı kitabı tekrar ekleyince adet artar
- `schools` tablosu MEB okul kodları ile seed edilmeli (~60.000 kayıt)
- İl/ilçe verileri için TÜİK veya MEB açık veri kaynakları kullanılabilir

---

## Faz 2: Kimlik Doğrulama ve Hesap Yönetimi

**Önkoşul:** Faz 1 tamamlanmış
**Durum:** Başlanmadı (mock auth Faz 0.5'te eklendi)

### Faz 2A — Okul Hesapları

- [ ] Okul bazlı hesap oluşturma (e-posta + şifre veya MEB e-okul entegrasyonu)
- [ ] JWT tabanlı kimlik doğrulama
- [ ] Okul hesabı ile giriş → sadece kendi okulunun verilerini düzenleyebilme
- [ ] Şifre sıfırlama akışı

### Faz 2B — Hiyerarşik Hesaplar

- [ ] Kullanıcı rolleri tanımlama:
  - `SCHOOL_LIBRARIAN` — kendi okulunun envanterini yönetir
  - `DISTRICT_ADMIN` — ilçesindeki tüm okulları görür (read-only)
  - `PROVINCE_ADMIN` — ilindeki tüm okulları görür (read-only)
  - `MINISTRY_ADMIN` — tüm Türkiye'yi görür (read-only)
- [ ] Rol bazlı erişim kontrolü (RBAC) middleware
- [ ] Web dashboard'da rol bazlı filtre kısıtlaması (ilçe admin'i sadece kendi ilçesini görebilir)
- [ ] Admin paneli: kullanıcı oluşturma, rol atama

### Faz 2C — Tek Hesap + Rol Bazlı (Uzun Vade)

- [ ] Bir kullanıcının birden fazla rolü olabilmesi
- [ ] Dinamik yetki delegasyonu
- [ ] MEB e-okul SSO entegrasyonu (tek oturum açma)
- [ ] Audit log: kim ne zaman hangi veriyi gördü/değiştirdi

---

## Faz 3: Ödünç Verme (Sirkülasyon)

**Önkoşul:** Faz 2A minimum
**Durum:** Başlanmadı

- [ ] Öğrenci/üye kaydı (okul bazlı)
- [ ] Kitap ödünç verme / iade akışı
- [ ] Süre takibi ve gecikme bildirimi
- [ ] Ödünç geçmişi raporları
- [ ] Mobil uygulamada ödünç verme ekranı

---

## Faz 4: Gelişmiş Özellikler

- [ ] Offline-first: internet kesintisinde tarama yapıp sonra sync etme
- [ ] Push notification (gecikmiş iadeler, sistem bildirimleri)
- [ ] Raporlama ve istatistik dashboard (en çok okunan kitaplar, okul bazlı kıyaslama)
- [ ] Kitap öneri sistemi (okullar arası popülerlik bazlı)
- [ ] MEB resmi API entegrasyonları
- [ ] KVKK uyumluluk denetimi ve veri anonimleştirme
- [ ] Çoklu dil desteği (Kürtçe, Arapça vb. bölgesel ihtiyaçlar)

---

## Faz 5: Ölçeklendirme

- [ ] Performans optimizasyonu (60.000+ okul, milyonlarca holding kaydı)
- [ ] CDN ile kitap kapak görselleri
- [ ] Veritabanı read-replica yapısı
- [ ] Rate limiting ve API güvenliği
- [ ] Monitoring ve alerting altyapısı

---

## Kısa Vadeli TODO (Sonraki Adımlar)

### Web — Öncelik: Yüksek
- [ ] Mobil app'e studentCount alanı eklenmesi (Flutter School model)
- [ ] BookDetailPage'deki SchoolHoldingsList tablosuna sortable header eklenmesi
- [ ] Excel import'un gerçek parsing yapması (şu an mock)
- [ ] Responsive tasarım iyileştirmeleri (mobil breakpoint'ler)

### Web — Öncelik: Orta
- [ ] Karşılaştırma sayfasında "En eksik önce" / "En yaygın önce" hazır sıralama butonları
- [ ] Dashboard'da trend göstergesi (önceki döneme göre artış/azalış)
- [ ] Kitap detay sayfasında holding geçmişi (ne zaman eklenmiş)
- [ ] Dark mode desteği

### Backend — Faz 1 Hazırlık
- [ ] API kontratını OpenAPI 3.0 spec olarak tamamlama
- [ ] Veritabanı migration aracı seçimi (Prisma vs Drizzle vs knex)
- [ ] Docker compose ile local dev ortamı (PostgreSQL + API)
- [ ] Seed script: MEB il/ilçe verilerini yükleme

### Mobil — İyileştirmeler
- [ ] Camera permission handling iyileştirmesi
- [ ] Barcode tarama sonucu vibration feedback
- [ ] Offline queue: internet yokken taramaları kaydet, sonra sync et
- [ ] App icon ve splash screen (MEB branding)

---

## Karar Kayıtları

| Tarih | Karar | Gerekçe |
|-------|-------|---------|
| 2026-03-05 | Union Catalog modeli | Aynı kitabın tekrar tekrar tanımlanmasını önler, ölçeklenebilir |
| 2026-03-05 | 2 ayrı uygulama (Flutter + React) | Farklı kullanıcı profilleri, farklı güçlü yanlar |
| 2026-03-05 | Monorepo | Ortak modeller ve mock data paylaşımı, bağımsız build/deploy |
| 2026-03-05 | Backend-agnostic başlangıç | Frontend'leri olgunlaştır, mock data ile doğrula |
| 2026-03-05 | Fallback zinciri (Google Books → Open Library → Manuel) | Türkçe kitap kapsamını maksimize etme |
| 2026-03-06 | Mock auth + role-based UI | Faz 2'den önce UI akışlarını test etme, scope locking deneyimi |
| 2026-03-06 | MEB bordo/kırmızı tema | Kurumsal kimliğe uyum, resmi görünüm |
| 2026-03-06 | Heat map karşılaştırma | Kitap dağılımını hızlıca görselleştirme, eksikleri tespit etme |
| 2026-03-06 | useSort generic hook | DRY: tüm tablolarda aynı sıralama davranışı |
