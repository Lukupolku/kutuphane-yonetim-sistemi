# Yol Haritası — Kütüphane Yönetim Sistemi

**Son güncelleme:** 2026-03-05

---

## Faz 0: MVP (Mevcut)

- [x] Tasarım dokümanı onaylandı
- [ ] Monorepo yapısı kurulumu
- [ ] Shared paket: modeller, mock data, API kontratları
- [ ] Flutter mobil uygulama (ISBN tarama, kapak OCR, raf OCR, kaydetme, envanter listesi)
- [ ] React web dashboard (hiyerarşik sorgulama, kitap arama)
- [ ] Mock data layer (backend soyutlanmış)

---

## Faz 1: Backend ve Veritabanı

**Önkoşul:** MVP tamamlanmış, kullanıcı akışları doğrulanmış

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

### Faz 2A — Okul Hesapları (MVP Genişletme)

- [ ] Okul bazlı hesap oluşturma (e-posta + şifre veya MEB e-okul entegrasyonu)
- [ ] JWT tabanlı kimlik doğrulama
- [ ] Okul hesabı ile giriş → sadece kendi okulunun verilerini düzenleyebilme
- [ ] Şifre sıfırlama akışı

### Faz 2B — Hiyerarşik Hesaplar

**Açıklama:** MVP'de sadece okul hesabı var. Bu fazda ilçe, il ve bakanlık seviyesinde kullanıcılar eklenir.

- [ ] Kullanıcı rolleri tanımlama:
  - `SCHOOL_LIBRARIAN` — kendi okulunun envanterini yönetir
  - `DISTRICT_ADMIN` — ilçesindeki tüm okulları görür (read-only)
  - `PROVINCE_ADMIN` — ilindeki tüm okulları görür (read-only)
  - `MINISTRY_ADMIN` — tüm Türkiye'yi görür (read-only)
- [ ] Rol bazlı erişim kontrolü (RBAC) middleware
- [ ] Web dashboard'da rol bazlı filtre kısıtlaması (ilçe admin'i sadece kendi ilçesini görebilir)
- [ ] Admin paneli: kullanıcı oluşturma, rol atama

### Faz 2C — Tek Hesap + Rol Bazlı (Uzun Vade)

**Açıklama:** Hiyerarşik hesaplardan sonra, daha esnek bir yapıya geçiş.

- [ ] Bir kullanıcının birden fazla rolü olabilmesi (örn: hem okul kütüphanecisi hem ilçe yetkilisi)
- [ ] Dinamik yetki delegasyonu (il müdürü bir kullanıcıya geçici ilçe admin yetkisi verebilir)
- [ ] MEB e-okul SSO entegrasyonu (tek oturum açma)
- [ ] Audit log: kim ne zaman hangi veriyi gördü/değiştirdi

---

## Faz 3: Ödünç Verme (Sirkülasyon)

**Önkoşul:** Faz 2A minimum

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

## Karar Kayıtları

| Tarih | Karar | Gerekçe |
|-------|-------|---------|
| 2026-03-05 | Union Catalog modeli | Aynı kitabın tekrar tekrar tanımlanmasını önler, ölçeklenebilir |
| 2026-03-05 | 2 ayrı uygulama (Flutter + React) | Farklı kullanıcı profilleri, farklı güçlü yanlar |
| 2026-03-05 | Monorepo | Ortak modeller ve mock data paylaşımı, bağımsız build/deploy |
| 2026-03-05 | MVP'de sadece okul hesabı | Karmaşıklığı düşük tutma, hiyerarşik yapı Faz 2'de |
| 2026-03-05 | Backend-agnostic başlangıç | Frontend'leri olgunlaştır, mock data ile doğrula |
| 2026-03-05 | Fallback zinciri (Google Books → Open Library → Manuel) | Türkçe kitap kapsamını maksimize etme |
