# MVP Implementation Plan — Kütüphane Yönetim Sistemi

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Monorepo kurulumu, Flutter mobil uygulama (ISBN tarama, kapak OCR, raf OCR, kaydetme, envanter listesi) ve React web dashboard (hiyerarşik sorgulama, kitap arama) — tamamı mock data üzerinden çalışan MVP.

**Architecture:** Union Catalog modeli — merkezi kitap kataloğu + okul bazlı holding kayıtları. Backend soyutlanmış, tüm veri bir repository pattern üzerinden mock data'dan gelir. İleride aynı interface'e gerçek API bağlanır.

**Tech Stack:** Flutter + Google ML Kit (mobil), React + TypeScript + Vite (web), JSON mock data (shared package)

---

## Task 1: Monorepo İskelet Yapısı

**Files:**
- Create: `apps/mobile/.gitkeep`
- Create: `apps/web/.gitkeep`
- Create: `packages/shared/models/book.json`
- Create: `packages/shared/models/school.json`
- Create: `packages/shared/models/holding.json`
- Create: `packages/shared/mock-data/books.json`
- Create: `packages/shared/mock-data/schools.json`
- Create: `packages/shared/mock-data/holdings.json`
- Create: `packages/shared/api-contracts/endpoints.yaml`
- Modify: `README.md`

**Step 1: Dizin yapısını oluştur**

```bash
mkdir -p apps/mobile apps/web
mkdir -p packages/shared/models packages/shared/mock-data packages/shared/api-contracts
```

**Step 2: JSON Schema modelleri oluştur**

`packages/shared/models/book.json`:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Book",
  "type": "object",
  "required": ["id", "title", "authors", "language", "source", "createdAt"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "isbn": { "type": ["string", "null"], "pattern": "^[0-9]{13}$" },
    "title": { "type": "string" },
    "authors": { "type": "array", "items": { "type": "string" }, "minItems": 1 },
    "publisher": { "type": ["string", "null"] },
    "publishedDate": { "type": ["string", "null"] },
    "pageCount": { "type": ["integer", "null"], "minimum": 1 },
    "coverImageUrl": { "type": ["string", "null"], "format": "uri" },
    "language": { "type": "string", "minLength": 2, "maxLength": 5 },
    "source": { "type": "string", "enum": ["GOOGLE_BOOKS", "OPEN_LIBRARY", "MANUAL", "OCR"] },
    "createdAt": { "type": "string", "format": "date-time" }
  }
}
```

`packages/shared/models/school.json`:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "School",
  "type": "object",
  "required": ["id", "name", "province", "district", "schoolType", "ministryCode"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "province": { "type": "string" },
    "district": { "type": "string" },
    "schoolType": { "type": "string", "enum": ["ILKOKUL", "ORTAOKUL", "LISE"] },
    "ministryCode": { "type": "string" }
  }
}
```

`packages/shared/models/holding.json`:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Holding",
  "type": "object",
  "required": ["id", "bookId", "schoolId", "quantity", "addedBy", "addedAt", "source"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "bookId": { "type": "string", "format": "uuid" },
    "schoolId": { "type": "string", "format": "uuid" },
    "quantity": { "type": "integer", "minimum": 1, "default": 1 },
    "addedBy": { "type": "string" },
    "addedAt": { "type": "string", "format": "date-time" },
    "source": { "type": "string", "enum": ["BARCODE_SCAN", "COVER_OCR", "SHELF_OCR", "MANUAL"] }
  }
}
```

**Step 3: Mock data oluştur**

`packages/shared/mock-data/schools.json` — 3 il, 6 ilçe, 12 okul:
```json
[
  {
    "id": "s1-ankara-cankaya-ataturk-ilk",
    "name": "Atatürk İlkokulu",
    "province": "Ankara",
    "district": "Çankaya",
    "schoolType": "ILKOKUL",
    "ministryCode": "06001001"
  },
  {
    "id": "s2-ankara-cankaya-inonu-orta",
    "name": "İnönü Ortaokulu",
    "province": "Ankara",
    "district": "Çankaya",
    "schoolType": "ORTAOKUL",
    "ministryCode": "06001002"
  },
  {
    "id": "s3-ankara-kecioren-fatih-lise",
    "name": "Fatih Anadolu Lisesi",
    "province": "Ankara",
    "district": "Keçiören",
    "schoolType": "LISE",
    "ministryCode": "06002001"
  },
  {
    "id": "s4-ankara-kecioren-mehmetakif-ilk",
    "name": "Mehmet Akif İlkokulu",
    "province": "Ankara",
    "district": "Keçiören",
    "schoolType": "ILKOKUL",
    "ministryCode": "06002002"
  },
  {
    "id": "s5-istanbul-kadikoy-moda-orta",
    "name": "Moda Ortaokulu",
    "province": "İstanbul",
    "district": "Kadıköy",
    "schoolType": "ORTAOKUL",
    "ministryCode": "34001001"
  },
  {
    "id": "s6-istanbul-kadikoy-fenerbahce-lise",
    "name": "Fenerbahçe Anadolu Lisesi",
    "province": "İstanbul",
    "district": "Kadıköy",
    "schoolType": "LISE",
    "ministryCode": "34001002"
  },
  {
    "id": "s7-istanbul-besiktas-barbaros-ilk",
    "name": "Barbaros İlkokulu",
    "province": "İstanbul",
    "district": "Beşiktaş",
    "schoolType": "ILKOKUL",
    "ministryCode": "34002001"
  },
  {
    "id": "s8-istanbul-besiktas-sinanpasa-orta",
    "name": "Sinanpaşa Ortaokulu",
    "province": "İstanbul",
    "district": "Beşiktaş",
    "schoolType": "ORTAOKUL",
    "ministryCode": "34002002"
  },
  {
    "id": "s9-izmir-konak-alsancak-lise",
    "name": "Alsancak Fen Lisesi",
    "province": "İzmir",
    "district": "Konak",
    "schoolType": "LISE",
    "ministryCode": "35001001"
  },
  {
    "id": "s10-izmir-konak-kemeralt-ilk",
    "name": "Kemeraltı İlkokulu",
    "province": "İzmir",
    "district": "Konak",
    "schoolType": "ILKOKUL",
    "ministryCode": "35001002"
  },
  {
    "id": "s11-izmir-bornova-ege-orta",
    "name": "Ege Ortaokulu",
    "province": "İzmir",
    "district": "Bornova",
    "schoolType": "ORTAOKUL",
    "ministryCode": "35002001"
  },
  {
    "id": "s12-izmir-bornova-dokuz-eylul-lise",
    "name": "Dokuz Eylül Anadolu Lisesi",
    "province": "İzmir",
    "district": "Bornova",
    "schoolType": "LISE",
    "ministryCode": "35002002"
  }
]
```

`packages/shared/mock-data/books.json` — 15 Türkçe kitap (gerçek ISBN):
```json
[
  {
    "id": "b1",
    "isbn": "9789750718533",
    "title": "Küçük Prens",
    "authors": ["Antoine de Saint-Exupéry"],
    "publisher": "Can Yayınları",
    "publishedDate": "2020",
    "pageCount": 96,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-01-15T10:00:00Z"
  },
  {
    "id": "b2",
    "isbn": "9789750726439",
    "title": "Sefiller",
    "authors": ["Victor Hugo"],
    "publisher": "İş Bankası Kültür Yayınları",
    "publishedDate": "2019",
    "pageCount": 1488,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-01-15T10:05:00Z"
  },
  {
    "id": "b3",
    "isbn": "9789750738609",
    "title": "Suç ve Ceza",
    "authors": ["Fyodor Dostoyevski"],
    "publisher": "İş Bankası Kültür Yayınları",
    "publishedDate": "2018",
    "pageCount": 687,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-01-16T09:00:00Z"
  },
  {
    "id": "b4",
    "isbn": "9789750505034",
    "title": "Tutunamayanlar",
    "authors": ["Oğuz Atay"],
    "publisher": "İletişim Yayınları",
    "publishedDate": "2021",
    "pageCount": 724,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-01-16T09:30:00Z"
  },
  {
    "id": "b5",
    "isbn": "9789750719387",
    "title": "Fareler ve İnsanlar",
    "authors": ["John Steinbeck"],
    "publisher": "Can Yayınları",
    "publishedDate": "2020",
    "pageCount": 118,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-01-17T08:00:00Z"
  },
  {
    "id": "b6",
    "isbn": "9789753638029",
    "title": "Kürk Mantolu Madonna",
    "authors": ["Sabahattin Ali"],
    "publisher": "Yapı Kredi Yayınları",
    "publishedDate": "2019",
    "pageCount": 160,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-01-17T08:30:00Z"
  },
  {
    "id": "b7",
    "isbn": "9789750736186",
    "title": "Dönüşüm",
    "authors": ["Franz Kafka"],
    "publisher": "İş Bankası Kültür Yayınları",
    "publishedDate": "2018",
    "pageCount": 77,
    "coverImageUrl": null,
    "language": "tr",
    "source": "OPEN_LIBRARY",
    "createdAt": "2026-01-18T10:00:00Z"
  },
  {
    "id": "b8",
    "isbn": "9789750724602",
    "title": "1984",
    "authors": ["George Orwell"],
    "publisher": "Can Yayınları",
    "publishedDate": "2021",
    "pageCount": 352,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-01-18T11:00:00Z"
  },
  {
    "id": "b9",
    "isbn": "9789750734762",
    "title": "Hayvan Çiftliği",
    "authors": ["George Orwell"],
    "publisher": "Can Yayınları",
    "publishedDate": "2020",
    "pageCount": 152,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-01-19T09:00:00Z"
  },
  {
    "id": "b10",
    "isbn": null,
    "title": "İstanbul Hatırası",
    "authors": ["Ahmet Ümit"],
    "publisher": "Everest Yayınları",
    "publishedDate": "2010",
    "pageCount": 456,
    "coverImageUrl": null,
    "language": "tr",
    "source": "MANUAL",
    "createdAt": "2026-01-20T10:00:00Z"
  },
  {
    "id": "b11",
    "isbn": "9789750732881",
    "title": "Beyaz Diş",
    "authors": ["Jack London"],
    "publisher": "İş Bankası Kültür Yayınları",
    "publishedDate": "2017",
    "pageCount": 248,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-01-21T08:00:00Z"
  },
  {
    "id": "b12",
    "isbn": "9789750714542",
    "title": "Simyacı",
    "authors": ["Paulo Coelho"],
    "publisher": "Can Yayınları",
    "publishedDate": "2019",
    "pageCount": 184,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-01-22T09:00:00Z"
  },
  {
    "id": "b13",
    "isbn": null,
    "title": "Matematik Dünyası 5. Sınıf",
    "authors": ["MEB"],
    "publisher": "MEB Yayınları",
    "publishedDate": "2025",
    "pageCount": 320,
    "coverImageUrl": null,
    "language": "tr",
    "source": "OCR",
    "createdAt": "2026-02-01T10:00:00Z"
  },
  {
    "id": "b14",
    "isbn": "9789750803246",
    "title": "Çalıkuşu",
    "authors": ["Reşat Nuri Güntekin"],
    "publisher": "İnkılâp Kitabevi",
    "publishedDate": "2018",
    "pageCount": 440,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-02-02T09:00:00Z"
  },
  {
    "id": "b15",
    "isbn": "9789750738012",
    "title": "Savaş ve Barış",
    "authors": ["Lev Tolstoy"],
    "publisher": "İş Bankası Kültür Yayınları",
    "publishedDate": "2019",
    "pageCount": 1460,
    "coverImageUrl": null,
    "language": "tr",
    "source": "GOOGLE_BOOKS",
    "createdAt": "2026-02-03T10:00:00Z"
  }
]
```

`packages/shared/mock-data/holdings.json` — kitap-okul eşleştirmeleri:
```json
[
  { "id": "h1", "bookId": "b1", "schoolId": "s1-ankara-cankaya-ataturk-ilk", "quantity": 5, "addedBy": "Ayşe Öğretmen", "addedAt": "2026-02-01T10:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h2", "bookId": "b1", "schoolId": "s5-istanbul-kadikoy-moda-orta", "quantity": 3, "addedBy": "Mehmet Bey", "addedAt": "2026-02-02T11:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h3", "bookId": "b1", "schoolId": "s9-izmir-konak-alsancak-lise", "quantity": 2, "addedBy": "Fatma Hanım", "addedAt": "2026-02-03T09:00:00Z", "source": "COVER_OCR" },
  { "id": "h4", "bookId": "b2", "schoolId": "s3-ankara-kecioren-fatih-lise", "quantity": 4, "addedBy": "Ali Bey", "addedAt": "2026-02-01T14:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h5", "bookId": "b2", "schoolId": "s6-istanbul-kadikoy-fenerbahce-lise", "quantity": 2, "addedBy": "Zeynep Hanım", "addedAt": "2026-02-04T10:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h6", "bookId": "b3", "schoolId": "s3-ankara-kecioren-fatih-lise", "quantity": 6, "addedBy": "Ali Bey", "addedAt": "2026-02-01T14:30:00Z", "source": "BARCODE_SCAN" },
  { "id": "h7", "bookId": "b3", "schoolId": "s9-izmir-konak-alsancak-lise", "quantity": 3, "addedBy": "Fatma Hanım", "addedAt": "2026-02-05T08:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h8", "bookId": "b3", "schoolId": "s12-izmir-bornova-dokuz-eylul-lise", "quantity": 4, "addedBy": "Hasan Bey", "addedAt": "2026-02-06T09:00:00Z", "source": "SHELF_OCR" },
  { "id": "h9", "bookId": "b4", "schoolId": "s6-istanbul-kadikoy-fenerbahce-lise", "quantity": 3, "addedBy": "Zeynep Hanım", "addedAt": "2026-02-04T10:30:00Z", "source": "BARCODE_SCAN" },
  { "id": "h10", "bookId": "b5", "schoolId": "s2-ankara-cankaya-inonu-orta", "quantity": 8, "addedBy": "Ayşe Öğretmen", "addedAt": "2026-02-01T11:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h11", "bookId": "b5", "schoolId": "s8-istanbul-besiktas-sinanpasa-orta", "quantity": 5, "addedBy": "Kemal Bey", "addedAt": "2026-02-07T10:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h12", "bookId": "b5", "schoolId": "s11-izmir-bornova-ege-orta", "quantity": 4, "addedBy": "Hasan Bey", "addedAt": "2026-02-08T09:00:00Z", "source": "COVER_OCR" },
  { "id": "h13", "bookId": "b6", "schoolId": "s1-ankara-cankaya-ataturk-ilk", "quantity": 3, "addedBy": "Ayşe Öğretmen", "addedAt": "2026-02-01T11:30:00Z", "source": "BARCODE_SCAN" },
  { "id": "h14", "bookId": "b6", "schoolId": "s5-istanbul-kadikoy-moda-orta", "quantity": 4, "addedBy": "Mehmet Bey", "addedAt": "2026-02-09T10:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h15", "bookId": "b6", "schoolId": "s7-istanbul-besiktas-barbaros-ilk", "quantity": 2, "addedBy": "Kemal Bey", "addedAt": "2026-02-10T08:00:00Z", "source": "MANUAL" },
  { "id": "h16", "bookId": "b6", "schoolId": "s10-izmir-konak-kemeralt-ilk", "quantity": 3, "addedBy": "Fatma Hanım", "addedAt": "2026-02-11T09:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h17", "bookId": "b7", "schoolId": "s3-ankara-kecioren-fatih-lise", "quantity": 5, "addedBy": "Ali Bey", "addedAt": "2026-02-01T15:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h18", "bookId": "b8", "schoolId": "s2-ankara-cankaya-inonu-orta", "quantity": 10, "addedBy": "Ayşe Öğretmen", "addedAt": "2026-02-01T12:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h19", "bookId": "b8", "schoolId": "s6-istanbul-kadikoy-fenerbahce-lise", "quantity": 7, "addedBy": "Zeynep Hanım", "addedAt": "2026-02-12T10:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h20", "bookId": "b8", "schoolId": "s9-izmir-konak-alsancak-lise", "quantity": 5, "addedBy": "Fatma Hanım", "addedAt": "2026-02-13T08:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h21", "bookId": "b8", "schoolId": "s12-izmir-bornova-dokuz-eylul-lise", "quantity": 6, "addedBy": "Hasan Bey", "addedAt": "2026-02-14T09:00:00Z", "source": "SHELF_OCR" },
  { "id": "h22", "bookId": "b9", "schoolId": "s4-ankara-kecioren-mehmetakif-ilk", "quantity": 4, "addedBy": "Ali Bey", "addedAt": "2026-02-02T08:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h23", "bookId": "b9", "schoolId": "s7-istanbul-besiktas-barbaros-ilk", "quantity": 3, "addedBy": "Kemal Bey", "addedAt": "2026-02-15T10:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h24", "bookId": "b10", "schoolId": "s8-istanbul-besiktas-sinanpasa-orta", "quantity": 2, "addedBy": "Kemal Bey", "addedAt": "2026-02-16T09:00:00Z", "source": "MANUAL" },
  { "id": "h25", "bookId": "b11", "schoolId": "s1-ankara-cankaya-ataturk-ilk", "quantity": 4, "addedBy": "Ayşe Öğretmen", "addedAt": "2026-02-01T12:30:00Z", "source": "BARCODE_SCAN" },
  { "id": "h26", "bookId": "b11", "schoolId": "s11-izmir-bornova-ege-orta", "quantity": 3, "addedBy": "Hasan Bey", "addedAt": "2026-02-17T10:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h27", "bookId": "b12", "schoolId": "s5-istanbul-kadikoy-moda-orta", "quantity": 6, "addedBy": "Mehmet Bey", "addedAt": "2026-02-18T11:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h28", "bookId": "b12", "schoolId": "s10-izmir-konak-kemeralt-ilk", "quantity": 2, "addedBy": "Fatma Hanım", "addedAt": "2026-02-19T08:00:00Z", "source": "COVER_OCR" },
  { "id": "h29", "bookId": "b13", "schoolId": "s2-ankara-cankaya-inonu-orta", "quantity": 30, "addedBy": "Ayşe Öğretmen", "addedAt": "2026-02-20T09:00:00Z", "source": "MANUAL" },
  { "id": "h30", "bookId": "b13", "schoolId": "s5-istanbul-kadikoy-moda-orta", "quantity": 25, "addedBy": "Mehmet Bey", "addedAt": "2026-02-21T10:00:00Z", "source": "MANUAL" },
  { "id": "h31", "bookId": "b14", "schoolId": "s3-ankara-kecioren-fatih-lise", "quantity": 3, "addedBy": "Ali Bey", "addedAt": "2026-02-22T08:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h32", "bookId": "b14", "schoolId": "s6-istanbul-kadikoy-fenerbahce-lise", "quantity": 5, "addedBy": "Zeynep Hanım", "addedAt": "2026-02-23T10:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h33", "bookId": "b14", "schoolId": "s9-izmir-konak-alsancak-lise", "quantity": 4, "addedBy": "Fatma Hanım", "addedAt": "2026-02-24T09:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h34", "bookId": "b15", "schoolId": "s6-istanbul-kadikoy-fenerbahce-lise", "quantity": 2, "addedBy": "Zeynep Hanım", "addedAt": "2026-02-25T10:00:00Z", "source": "BARCODE_SCAN" },
  { "id": "h35", "bookId": "b15", "schoolId": "s12-izmir-bornova-dokuz-eylul-lise", "quantity": 3, "addedBy": "Hasan Bey", "addedAt": "2026-02-26T09:00:00Z", "source": "BARCODE_SCAN" }
]
```

**Step 4: API kontratları oluştur**

`packages/shared/api-contracts/endpoints.yaml`:
```yaml
openapi: 3.0.3
info:
  title: Kütüphane Yönetim Sistemi API
  version: 0.1.0-mock
  description: MVP mock API contract — backend henüz yok, bu kontrat frontend'lerin beklediği yapıyı tanımlar

paths:
  /api/books:
    get:
      summary: Kitap listesi
      parameters:
        - name: search
          in: query
          schema: { type: string }
        - name: isbn
          in: query
          schema: { type: string }
      responses:
        '200':
          description: Kitap listesi
          content:
            application/json:
              schema:
                type: array
                items: { $ref: '#/components/schemas/Book' }

  /api/books/{id}:
    get:
      summary: Kitap detayı (holding bilgileriyle)
      responses:
        '200':
          description: Kitap + hangi okullarda var
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/Book'
                  - type: object
                    properties:
                      holdings:
                        type: array
                        items: { $ref: '#/components/schemas/HoldingWithSchool' }

  /api/schools:
    get:
      summary: Okul listesi (filtreli)
      parameters:
        - name: province
          in: query
          schema: { type: string }
        - name: district
          in: query
          schema: { type: string }
        - name: schoolType
          in: query
          schema: { type: string }
      responses:
        '200':
          description: Okul listesi

  /api/schools/{id}/holdings:
    get:
      summary: Bir okulun kitap envanteri
      responses:
        '200':
          description: Holding listesi (kitap bilgileriyle)
    post:
      summary: Okul envanterine kitap ekle
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [bookId, source]
              properties:
                bookId: { type: string }
                quantity: { type: integer, default: 1 }
                source: { type: string, enum: [BARCODE_SCAN, COVER_OCR, SHELF_OCR, MANUAL] }

  /api/lookup/isbn/{isbn}:
    get:
      summary: ISBN ile kitap ara (Google Books → Open Library fallback)
      responses:
        '200':
          description: Kitap bilgisi bulundu
        '404':
          description: Kitap bulunamadı

components:
  schemas:
    Book:
      $ref: '../models/book.json'
    School:
      $ref: '../models/school.json'
    Holding:
      $ref: '../models/holding.json'
    HoldingWithSchool:
      type: object
      properties:
        holding: { $ref: '#/components/schemas/Holding' }
        school: { $ref: '#/components/schemas/School' }
```

**Step 5: README.md oluştur**

Projenin ne olduğu, nasıl çalıştırılacağı, monorepo yapısı.

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: scaffold monorepo with shared models, mock data, and API contracts"
```

---

## Task 2: Flutter Proje Kurulumu

**Files:**
- Create: `apps/mobile/` (Flutter project)
- Create: `apps/mobile/lib/models/book.dart`
- Create: `apps/mobile/lib/models/school.dart`
- Create: `apps/mobile/lib/models/holding.dart`
- Create: `apps/mobile/test/models/book_test.dart`

**Step 1: Flutter projesi oluştur**

```bash
cd apps
flutter create --org com.kutuphane --project-name kutuphane_mobile mobile
```

**Step 2: pubspec.yaml'a bağımlılıkları ekle**

```yaml
dependencies:
  flutter:
    sdk: flutter
  mobile_scanner: ^6.0.0      # Barkod tarama
  google_mlkit_text_recognition: ^0.14.0  # OCR
  http: ^1.2.0                 # API istekleri
  uuid: ^4.0.0                 # UUID üretimi
  provider: ^6.0.0             # State management
  cached_network_image: ^3.3.0 # Kitap kapak görselleri

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

**Step 3: Failing test yaz — Book modeli**

`apps/mobile/test/models/book_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/models/book.dart';

void main() {
  group('Book', () {
    test('fromJson creates Book from valid JSON', () {
      final json = {
        'id': 'b1',
        'isbn': '9789750718533',
        'title': 'Küçük Prens',
        'authors': ['Antoine de Saint-Exupéry'],
        'publisher': 'Can Yayınları',
        'publishedDate': '2020',
        'pageCount': 96,
        'coverImageUrl': null,
        'language': 'tr',
        'source': 'GOOGLE_BOOKS',
        'createdAt': '2026-01-15T10:00:00Z',
      };

      final book = Book.fromJson(json);

      expect(book.id, 'b1');
      expect(book.isbn, '9789750718533');
      expect(book.title, 'Küçük Prens');
      expect(book.authors, ['Antoine de Saint-Exupéry']);
      expect(book.source, BookSource.googleBooks);
    });

    test('fromJson handles null isbn', () {
      final json = {
        'id': 'b10',
        'isbn': null,
        'title': 'İstanbul Hatırası',
        'authors': ['Ahmet Ümit'],
        'language': 'tr',
        'source': 'MANUAL',
        'createdAt': '2026-01-20T10:00:00Z',
      };

      final book = Book.fromJson(json);
      expect(book.isbn, isNull);
      expect(book.source, BookSource.manual);
    });

    test('toJson produces valid JSON', () {
      final book = Book(
        id: 'b1',
        isbn: '9789750718533',
        title: 'Küçük Prens',
        authors: ['Antoine de Saint-Exupéry'],
        language: 'tr',
        source: BookSource.googleBooks,
        createdAt: DateTime.parse('2026-01-15T10:00:00Z'),
      );

      final json = book.toJson();
      expect(json['id'], 'b1');
      expect(json['isbn'], '9789750718533');
      expect(json['source'], 'GOOGLE_BOOKS');
    });
  });
}
```

**Step 4: Run test to verify it fails**

```bash
cd apps/mobile
flutter test test/models/book_test.dart
```
Expected: FAIL — `book.dart` does not exist yet

**Step 5: Implement Book model**

`apps/mobile/lib/models/book.dart`:
```dart
enum BookSource {
  googleBooks,
  openLibrary,
  manual,
  ocr;

  static BookSource fromString(String value) {
    switch (value) {
      case 'GOOGLE_BOOKS': return BookSource.googleBooks;
      case 'OPEN_LIBRARY': return BookSource.openLibrary;
      case 'MANUAL': return BookSource.manual;
      case 'OCR': return BookSource.ocr;
      default: throw ArgumentError('Unknown BookSource: $value');
    }
  }

  String toJsonString() {
    switch (this) {
      case BookSource.googleBooks: return 'GOOGLE_BOOKS';
      case BookSource.openLibrary: return 'OPEN_LIBRARY';
      case BookSource.manual: return 'MANUAL';
      case BookSource.ocr: return 'OCR';
    }
  }
}

class Book {
  final String id;
  final String? isbn;
  final String title;
  final List<String> authors;
  final String? publisher;
  final String? publishedDate;
  final int? pageCount;
  final String? coverImageUrl;
  final String language;
  final BookSource source;
  final DateTime createdAt;

  Book({
    required this.id,
    this.isbn,
    required this.title,
    required this.authors,
    this.publisher,
    this.publishedDate,
    this.pageCount,
    this.coverImageUrl,
    required this.language,
    required this.source,
    required this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      isbn: json['isbn'] as String?,
      title: json['title'] as String,
      authors: List<String>.from(json['authors'] as List),
      publisher: json['publisher'] as String?,
      publishedDate: json['publishedDate'] as String?,
      pageCount: json['pageCount'] as int?,
      coverImageUrl: json['coverImageUrl'] as String?,
      language: json['language'] as String,
      source: BookSource.fromString(json['source'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'authors': authors,
      'publisher': publisher,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'coverImageUrl': coverImageUrl,
      'language': language,
      'source': source.toJsonString(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

**Step 6: Run test — should pass**

```bash
cd apps/mobile
flutter test test/models/book_test.dart
```

**Step 7: Repeat for School and Holding models** (same TDD pattern)

**Step 8: Commit**

```bash
git add apps/mobile/
git commit -m "feat(mobile): init Flutter project with Book, School, Holding models"
```

---

## Task 3: Flutter Mock Data Repository

**Files:**
- Create: `apps/mobile/lib/repositories/book_repository.dart`
- Create: `apps/mobile/lib/repositories/mock_book_repository.dart`
- Create: `apps/mobile/test/repositories/mock_book_repository_test.dart`
- Copy: `packages/shared/mock-data/*.json` → `apps/mobile/assets/mock-data/`

**Step 1: Write failing test**

`apps/mobile/test/repositories/mock_book_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/repositories/book_repository.dart';
import 'package:kutuphane_mobile/repositories/mock_book_repository.dart';

void main() {
  late BookRepository repository;

  setUp(() {
    repository = MockBookRepository();
  });

  group('MockBookRepository', () {
    test('getBooks returns all books', () async {
      final books = await repository.getBooks();
      expect(books.length, 15);
    });

    test('getBookByIsbn finds existing book', () async {
      final book = await repository.getBookByIsbn('9789750718533');
      expect(book, isNotNull);
      expect(book!.title, 'Küçük Prens');
    });

    test('getBookByIsbn returns null for unknown ISBN', () async {
      final book = await repository.getBookByIsbn('0000000000000');
      expect(book, isNull);
    });

    test('getHoldingsForSchool returns correct holdings', () async {
      final holdings = await repository.getHoldingsForSchool(
        's1-ankara-cankaya-ataturk-ilk',
      );
      expect(holdings.length, 3); // b1, b6, b11
    });

    test('addHolding creates new holding', () async {
      await repository.addHolding(
        bookId: 'b15',
        schoolId: 's1-ankara-cankaya-ataturk-ilk',
        source: 'BARCODE_SCAN',
        addedBy: 'Test User',
      );
      final holdings = await repository.getHoldingsForSchool(
        's1-ankara-cankaya-ataturk-ilk',
      );
      expect(holdings.length, 4);
    });

    test('searchBooks filters by title', () async {
      final results = await repository.searchBooks('prens');
      expect(results.length, 1);
      expect(results.first.title, 'Küçük Prens');
    });

    test('getSchoolsByProvince filters correctly', () async {
      final schools = await repository.getSchoolsByProvince('Ankara');
      expect(schools.length, 4);
    });

    test('getSchoolsByDistrict filters correctly', () async {
      final schools = await repository.getSchoolsByDistrict('Ankara', 'Çankaya');
      expect(schools.length, 2);
    });

    test('getBookWithHoldings returns book with school info', () async {
      final result = await repository.getBookWithHoldings('b1');
      expect(result, isNotNull);
      expect(result!.holdings.length, 3); // s1, s5, s9
    });
  });
}
```

**Step 2: Run test — should fail**

**Step 3: Implement abstract repository + mock**

`apps/mobile/lib/repositories/book_repository.dart` — abstract interface:
```dart
import '../models/book.dart';
import '../models/school.dart';
import '../models/holding.dart';

class BookWithHoldings {
  final Book book;
  final List<HoldingWithSchool> holdings;
  BookWithHoldings({required this.book, required this.holdings});
}

class HoldingWithSchool {
  final Holding holding;
  final School school;
  HoldingWithSchool({required this.holding, required this.school});
}

abstract class BookRepository {
  Future<List<Book>> getBooks();
  Future<Book?> getBookByIsbn(String isbn);
  Future<List<Book>> searchBooks(String query);
  Future<BookWithHoldings?> getBookWithHoldings(String bookId);
  Future<List<HoldingWithSchool>> getHoldingsForSchool(String schoolId);
  Future<void> addHolding({
    required String bookId,
    required String schoolId,
    required String source,
    required String addedBy,
    int quantity = 1,
  });
  Future<Book> addBook(Book book);
  Future<List<School>> getSchoolsByProvince(String province);
  Future<List<School>> getSchoolsByDistrict(String province, String district);
  Future<List<String>> getProvinces();
  Future<List<String>> getDistricts(String province);
}
```

`apps/mobile/lib/repositories/mock_book_repository.dart` — in-memory mock that loads from JSON assets.

**Step 4: Run tests — should pass**

**Step 5: Commit**

```bash
git commit -m "feat(mobile): add BookRepository interface and MockBookRepository"
```

---

## Task 4: Flutter ISBN Barkod Tarama Ekranı

**Files:**
- Create: `apps/mobile/lib/services/isbn_lookup_service.dart`
- Create: `apps/mobile/lib/screens/scan_screen.dart`
- Create: `apps/mobile/lib/screens/book_result_screen.dart`
- Create: `apps/mobile/test/services/isbn_lookup_service_test.dart`

**Step 1: Write failing test — ISBN lookup fallback chain**

`apps/mobile/test/services/isbn_lookup_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/services/isbn_lookup_service.dart';

void main() {
  late IsbnLookupService service;

  setUp(() {
    // Mock HTTP client ile test — gerçek API çağrısı yapmaz
    service = IsbnLookupService.withMockClient();
  });

  group('IsbnLookupService', () {
    test('lookupIsbn returns book from Google Books', () async {
      final result = await service.lookupIsbn('9789750718533');
      expect(result, isNotNull);
      expect(result!.title, isNotEmpty);
      expect(result.source, BookSource.googleBooks);
    });

    test('lookupIsbn falls back to Open Library', () async {
      // ISBN that Google Books mock doesn't have
      final result = await service.lookupIsbn('9780000000001');
      expect(result, isNotNull);
      expect(result!.source, BookSource.openLibrary);
    });

    test('lookupIsbn returns null when neither has it', () async {
      final result = await service.lookupIsbn('0000000000000');
      expect(result, isNull);
    });
  });
}
```

**Step 2: Implement IsbnLookupService**

`apps/mobile/lib/services/isbn_lookup_service.dart`:
- Google Books API: `https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}`
- Open Library API: `https://openlibrary.org/api/books?bibkeys=ISBN:{isbn}&format=json&jscmd=data`
- Fallback zinciri: Google → Open Library → null
- Mock client constructor for testing

**Step 3: Run test — should pass**

**Step 4: Implement ScanScreen**

`apps/mobile/lib/screens/scan_screen.dart`:
- `mobile_scanner` package ile barkod tarama
- Barkod algılandığında → `IsbnLookupService.lookupIsbn()` çağır
- Sonucu `BookResultScreen`'e yönlendir
- Bulunamazsa manuel giriş formuna yönlendir

**Step 5: Implement BookResultScreen**

`apps/mobile/lib/screens/book_result_screen.dart`:
- Kitap bilgilerini göster (kapak, başlık, yazar, yayınevi)
- "Kütüphaneme Kaydet" butonu → `repository.addHolding()`
- Kayıt sonrası başarı mesajı ve taramaya dön

**Step 6: Commit**

```bash
git commit -m "feat(mobile): add ISBN barcode scanning with Google Books/Open Library fallback"
```

---

## Task 5: Flutter Kitap Kapağı OCR

**Files:**
- Create: `apps/mobile/lib/services/ocr_service.dart`
- Create: `apps/mobile/lib/screens/cover_ocr_screen.dart`
- Create: `apps/mobile/test/services/ocr_service_test.dart`

**Step 1: Write failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/services/ocr_service.dart';

void main() {
  group('OcrService', () {
    test('parseBookInfoFromText extracts title and author', () {
      final text = 'Küçük Prens\nAntoine de Saint-Exupéry\nCan Yayınları';
      final result = OcrService.parseBookInfoFromText(text);

      expect(result.possibleTitle, 'Küçük Prens');
      expect(result.possibleAuthor, 'Antoine de Saint-Exupéry');
    });

    test('parseBookInfoFromText handles single line', () {
      final text = 'Suç ve Ceza';
      final result = OcrService.parseBookInfoFromText(text);

      expect(result.possibleTitle, 'Suç ve Ceza');
      expect(result.possibleAuthor, isNull);
    });
  });
}
```

**Step 2: Implement OcrService**

`apps/mobile/lib/services/ocr_service.dart`:
- `google_mlkit_text_recognition` ile kameradan metin çıkarma
- `parseBookInfoFromText()` — OCR metninden başlık/yazar tahmini:
  - İlk satır → muhtemel başlık
  - İkinci satır → muhtemel yazar
  - Üçüncü satır → muhtemel yayınevi
- Heuristik: büyük punto metin → başlık, küçük punto → yazar

**Step 3: Run test — should pass**

**Step 4: Implement CoverOcrScreen**

`apps/mobile/lib/screens/cover_ocr_screen.dart`:
- Kamera açılır, fotoğraf çekilir
- OCR çalışır, metin çıkar
- Başlık/yazar alanları otomatik doldurulur (düzenlenebilir TextFormField)
- ISBN alanı boş (opsiyonel doldurma)
- "Kaydet" butonu → `repository.addBook()` + `repository.addHolding()`

**Step 5: Commit**

```bash
git commit -m "feat(mobile): add cover OCR with ML Kit text recognition"
```

---

## Task 6: Flutter Raf Fotoğrafı ile Toplu Giriş

**Files:**
- Create: `apps/mobile/lib/services/shelf_ocr_service.dart`
- Create: `apps/mobile/lib/screens/shelf_scan_screen.dart`
- Create: `apps/mobile/lib/widgets/book_entry_card.dart`
- Create: `apps/mobile/test/services/shelf_ocr_service_test.dart`

**Step 1: Write failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_mobile/services/shelf_ocr_service.dart';

void main() {
  group('ShelfOcrService', () {
    test('parseShelfText splits into individual book entries', () {
      // Simulates vertical text blocks from book spines
      final ocrBlocks = [
        OcrTextBlock(text: 'Küçük Prens', boundingBox: Rect.fromLTWH(10, 0, 30, 200)),
        OcrTextBlock(text: 'Suç ve Ceza', boundingBox: Rect.fromLTWH(50, 0, 30, 200)),
        OcrTextBlock(text: '1984', boundingBox: Rect.fromLTWH(90, 0, 30, 200)),
      ];

      final entries = ShelfOcrService.parseShelfBlocks(ocrBlocks);

      expect(entries.length, 3);
      expect(entries[0].possibleTitle, 'Küçük Prens');
      expect(entries[1].possibleTitle, 'Suç ve Ceza');
      expect(entries[2].possibleTitle, '1984');
    });
  });
}
```

**Step 2: Implement ShelfOcrService**

- Fotoğraftaki metin bloklarını x-pozisyonuna göre grupla (her kitap sırtı dikey bir kolon)
- Her grup = bir kitap adayı
- Her aday için `BookEntryDraft` döndür (possibleTitle, possibleAuthor)

**Step 3: Implement ShelfScanScreen**

- Kamera ile raf fotoğrafı çek
- OCR çalıştır → metin blokları al
- `ShelfOcrService.parseShelfBlocks()` ile kitap adaylarını çıkar
- Her aday `BookEntryCard` widget'ı olarak gösterilir
- Kullanıcı her kartı düzenleyebilir / silebilir / onaylayabilir
- "Seçilenleri Kaydet" butonu → toplu `addBook()` + `addHolding()`

**Step 4: Commit**

```bash
git commit -m "feat(mobile): add shelf photo OCR for batch book entry"
```

---

## Task 7: Flutter Okul Envanter Ekranı ve Ana Navigasyon

**Files:**
- Create: `apps/mobile/lib/screens/home_screen.dart`
- Create: `apps/mobile/lib/screens/inventory_screen.dart`
- Create: `apps/mobile/lib/screens/book_detail_screen.dart`
- Create: `apps/mobile/lib/screens/manual_entry_screen.dart`
- Modify: `apps/mobile/lib/main.dart`

**Step 1: Write failing test — inventory filtering**

```dart
test('inventory screen shows books for current school', () async {
  final holdings = await repository.getHoldingsForSchool(
    's1-ankara-cankaya-ataturk-ilk',
  );
  expect(holdings.every((h) => h.holding.schoolId == 's1-ankara-cankaya-ataturk-ilk'), true);
});
```

**Step 2: Implement HomeScreen — ana navigasyon**

`apps/mobile/lib/screens/home_screen.dart`:
- Bottom navigation: 3 sekme
  1. **Tara** — tarama yöntem seçimi (barkod / kapak / raf)
  2. **Kitaplarımız** — envanter listesi
  3. **Profil** — okul bilgisi (mock: hardcoded okul)

**Step 3: Implement InventoryScreen**

`apps/mobile/lib/screens/inventory_screen.dart`:
- `repository.getHoldingsForSchool(currentSchoolId)` ile kitap listesi
- Arama çubuğu (başlık/yazar filtreleme)
- Her satır: kapak thumbnail, başlık, yazar, adet
- Tıklanınca `BookDetailScreen`'e git

**Step 4: Implement BookDetailScreen**

- Kitap bilgileri (kapak büyük, tüm alanlar)
- Okuldaki adet
- Eklenme tarihi ve kaynak (barkod/OCR/manuel)

**Step 5: Implement ManualEntryScreen**

- Form: başlık*, yazar*, ISBN (opsiyonel), yayınevi, sayfa sayısı, dil
- "Kaydet" → `repository.addBook()` + `repository.addHolding()`

**Step 6: Wire up main.dart**

Provider ile MockBookRepository inject et, routing ayarla.

**Step 7: Commit**

```bash
git commit -m "feat(mobile): add home navigation, inventory list, book detail, manual entry"
```

---

## Task 8: React Web Projesi Kurulumu

**Files:**
- Create: `apps/web/` (Vite + React + TypeScript project)
- Create: `apps/web/src/types/book.ts`
- Create: `apps/web/src/types/school.ts`
- Create: `apps/web/src/types/holding.ts`

**Step 1: React projesi oluştur**

```bash
cd apps
npm create vite@latest web -- --template react-ts
cd web
npm install
npm install @tanstack/react-query axios
npm install -D @testing-library/react @testing-library/jest-dom vitest jsdom
```

**Step 2: TypeScript tiplerini oluştur**

`apps/web/src/types/book.ts`:
```typescript
export type BookSource = 'GOOGLE_BOOKS' | 'OPEN_LIBRARY' | 'MANUAL' | 'OCR';

export interface Book {
  id: string;
  isbn: string | null;
  title: string;
  authors: string[];
  publisher: string | null;
  publishedDate: string | null;
  pageCount: number | null;
  coverImageUrl: string | null;
  language: string;
  source: BookSource;
  createdAt: string;
}
```

`apps/web/src/types/school.ts`:
```typescript
export type SchoolType = 'ILKOKUL' | 'ORTAOKUL' | 'LISE';

export interface School {
  id: string;
  name: string;
  province: string;
  district: string;
  schoolType: SchoolType;
  ministryCode: string;
}
```

`apps/web/src/types/holding.ts`:
```typescript
export type HoldingSource = 'BARCODE_SCAN' | 'COVER_OCR' | 'SHELF_OCR' | 'MANUAL';

export interface Holding {
  id: string;
  bookId: string;
  schoolId: string;
  quantity: number;
  addedBy: string;
  addedAt: string;
  source: HoldingSource;
}

export interface HoldingWithSchool {
  holding: Holding;
  school: School;
}

export interface BookWithHoldings {
  book: Book;
  holdings: HoldingWithSchool[];
}
```

**Step 3: Commit**

```bash
git commit -m "feat(web): init React + TypeScript project with shared type definitions"
```

---

## Task 9: React Mock Data Service

**Files:**
- Create: `apps/web/src/services/mock-data.ts`
- Create: `apps/web/src/services/api.ts`
- Create: `apps/web/src/__tests__/api.test.ts`

**Step 1: Write failing test**

`apps/web/src/__tests__/api.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';
import { api } from '../services/api';

describe('API Service (mock)', () => {
  it('getBooks returns all books', async () => {
    const books = await api.getBooks();
    expect(books.length).toBe(15);
  });

  it('searchBooks filters by title', async () => {
    const books = await api.searchBooks('prens');
    expect(books.length).toBe(1);
    expect(books[0].title).toBe('Küçük Prens');
  });

  it('getSchools filters by province', async () => {
    const schools = await api.getSchools({ province: 'Ankara' });
    expect(schools.length).toBe(4);
  });

  it('getSchools filters by province and district', async () => {
    const schools = await api.getSchools({ province: 'İstanbul', district: 'Kadıköy' });
    expect(schools.length).toBe(2);
  });

  it('getBookWithHoldings returns holdings with school info', async () => {
    const result = await api.getBookWithHoldings('b1');
    expect(result).not.toBeNull();
    expect(result!.holdings.length).toBe(3);
  });

  it('getProvinces returns unique sorted provinces', async () => {
    const provinces = await api.getProvinces();
    expect(provinces).toEqual(['Ankara', 'İstanbul', 'İzmir']);
  });

  it('getDistricts returns districts for province', async () => {
    const districts = await api.getDistricts('Ankara');
    expect(districts).toEqual(['Keçiören', 'Çankaya']);
  });

  it('getSchoolHoldings returns books for a school', async () => {
    const holdings = await api.getSchoolHoldings('s1-ankara-cankaya-ataturk-ilk');
    expect(holdings.length).toBe(3);
  });
});
```

**Step 2: Run test — should fail**

```bash
cd apps/web
npx vitest run src/__tests__/api.test.ts
```

**Step 3: Implement mock-data.ts and api.ts**

`apps/web/src/services/mock-data.ts`:
- Import JSON from `packages/shared/mock-data/` (vite allows JSON import)
- Export typed arrays

`apps/web/src/services/api.ts`:
- Implements same interface that real API will have
- Uses mock data internally
- All methods return `Promise<T>` (simulating async API calls)

**Step 4: Run tests — should pass**

**Step 5: Commit**

```bash
git commit -m "feat(web): add mock API service with filtering and search"
```

---

## Task 10: React Web Dashboard — Hiyerarşik Filtre

**Files:**
- Create: `apps/web/src/components/HierarchyFilter.tsx`
- Create: `apps/web/src/components/BookTable.tsx`
- Create: `apps/web/src/pages/DashboardPage.tsx`
- Create: `apps/web/src/__tests__/HierarchyFilter.test.tsx`

**Step 1: Write failing test**

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { HierarchyFilter } from '../components/HierarchyFilter';

describe('HierarchyFilter', () => {
  it('renders province dropdown', async () => {
    render(<HierarchyFilter onFilterChange={() => {}} />);
    await waitFor(() => {
      expect(screen.getByLabelText('İl')).toBeInTheDocument();
    });
  });

  it('shows district dropdown after province selected', async () => {
    render(<HierarchyFilter onFilterChange={() => {}} />);
    // Select a province
    fireEvent.change(screen.getByLabelText('İl'), { target: { value: 'Ankara' } });
    await waitFor(() => {
      expect(screen.getByLabelText('İlçe')).toBeInTheDocument();
    });
  });
});
```

**Step 2: Implement HierarchyFilter**

`apps/web/src/components/HierarchyFilter.tsx`:
- 3 cascading dropdown: İl → İlçe → Okul
- İl seçilince ilçeler yüklenir, ilçe seçilince okullar
- "Tümü" seçeneği her seviyede mevcut
- `onFilterChange` callback: `{ province?, district?, schoolId? }`

**Step 3: Implement BookTable**

`apps/web/src/components/BookTable.tsx`:
- Kitap listesini tablo olarak göster
- Sütunlar: Başlık, Yazar, ISBN, Okul Sayısı, Toplam Adet
- Arama çubuğu (başlık/yazar/ISBN)
- Satıra tıklanınca detay sayfasına yönlendir

**Step 4: Implement DashboardPage**

- HierarchyFilter + BookTable birleşik
- Filtre değişince kitap listesi güncellenir
- Sayfa başlığı: seçilen coğrafi kapsamı gösterir

**Step 5: Commit**

```bash
git commit -m "feat(web): add dashboard with hierarchical filter and book table"
```

---

## Task 11: React Web — Kitap Detay ve Okul Listesi

**Files:**
- Create: `apps/web/src/pages/BookDetailPage.tsx`
- Create: `apps/web/src/components/SchoolHoldingsList.tsx`
- Create: `apps/web/src/__tests__/BookDetailPage.test.tsx`

**Step 1: Write failing test**

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { BookDetailPage } from '../pages/BookDetailPage';
import { MemoryRouter, Route, Routes } from 'react-router-dom';

describe('BookDetailPage', () => {
  it('shows book info and holding schools', async () => {
    render(
      <MemoryRouter initialEntries={['/books/b1']}>
        <Routes>
          <Route path="/books/:id" element={<BookDetailPage />} />
        </Routes>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('Küçük Prens')).toBeInTheDocument();
      // 3 okul bu kitaba sahip
      expect(screen.getByText('Atatürk İlkokulu')).toBeInTheDocument();
      expect(screen.getByText('Moda Ortaokulu')).toBeInTheDocument();
      expect(screen.getByText('Alsancak Fen Lisesi')).toBeInTheDocument();
    });
  });
});
```

**Step 2: Implement BookDetailPage**

- URL param: `/books/:id`
- `api.getBookWithHoldings(id)` ile veri çek
- Üst kısım: kitap bilgileri (kapak, başlık, yazar, ISBN, yayınevi)
- Alt kısım: `SchoolHoldingsList` — bu kitaba sahip okullar tablosu

**Step 3: Implement SchoolHoldingsList**

- Tablo: Okul Adı, İl, İlçe, Adet, Eklenme Tarihi
- İl/İlçe bazında filtrelenebilir

**Step 4: Commit**

```bash
git commit -m "feat(web): add book detail page with school holdings list"
```

---

## Task 12: React Web — Routing ve Layout

**Files:**
- Create: `apps/web/src/components/Layout.tsx`
- Create: `apps/web/src/pages/SearchPage.tsx`
- Modify: `apps/web/src/App.tsx`

**Step 1: Install react-router**

```bash
cd apps/web
npm install react-router-dom
```

**Step 2: Implement Layout**

`apps/web/src/components/Layout.tsx`:
- Header: "Kütüphane Yönetim Sistemi" logo + başlık
- Sidebar veya top-nav: Dashboard, Kitap Ara
- Ana içerik alanı (`<Outlet />`)

**Step 3: Implement SearchPage**

- Tek amaçlı arama: başlık/yazar/ISBN
- Sonuçlar BookTable ile gösterilir
- "Bu kitap hangi okullarda var?" → kitap detay sayfasına link

**Step 4: Wire up App.tsx routing**

```typescript
<BrowserRouter>
  <Routes>
    <Route element={<Layout />}>
      <Route path="/" element={<DashboardPage />} />
      <Route path="/search" element={<SearchPage />} />
      <Route path="/books/:id" element={<BookDetailPage />} />
    </Route>
  </Routes>
</BrowserRouter>
```

**Step 5: Commit**

```bash
git commit -m "feat(web): add layout, search page, and routing"
```

---

## Task 13: Final — README, CLAUDE.md ve Push

**Files:**
- Create: `README.md`
- Create: `CLAUDE.md`

**Step 1: README.md yaz**

Proje açıklaması, monorepo yapısı, her uygulamanın nasıl çalıştırılacağı.

**Step 2: CLAUDE.md yaz**

Build komutları, mimari özet, test komutları.

**Step 3: Tüm testleri çalıştır**

```bash
cd apps/mobile && flutter test
cd apps/web && npx vitest run
```

**Step 4: Final commit ve push**

```bash
git add -A
git commit -m "docs: add README and CLAUDE.md"
git push origin master
```

---

## Özet: Task Listesi

| # | Task | Bağımlılık |
|---|------|-----------|
| 1 | Monorepo iskelet + shared models + mock data | — |
| 2 | Flutter proje kurulumu + modeller | 1 |
| 3 | Flutter mock data repository | 2 |
| 4 | Flutter ISBN barkod tarama | 3 |
| 5 | Flutter kitap kapağı OCR | 3 |
| 6 | Flutter raf fotoğrafı toplu OCR | 5 |
| 7 | Flutter envanter ekranı + navigasyon | 3, 4, 5, 6 |
| 8 | React web proje kurulumu + tipler | 1 |
| 9 | React mock data service | 8 |
| 10 | React hiyerarşik filtre + dashboard | 9 |
| 11 | React kitap detay + okul listesi | 9 |
| 12 | React routing + layout | 10, 11 |
| 13 | README, CLAUDE.md, final push | 12, 7 |

**Paralellik:** Task 2-7 (Flutter) ve Task 8-12 (React) birbirinden bağımsız, paralel yürütülebilir.
