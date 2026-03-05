# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

School library management system (Union Catalog model) for Turkey's Ministry of Education (MEB). Monorepo with two apps sharing common data models.

## Commands

### Web Dashboard (apps/web/)
```bash
cd apps/web
npm run dev          # Dev server at localhost:5173
npm run build        # Production build
npx vitest run       # Run all tests
npx vitest run src/__tests__/api.test.ts  # Single test file
npx tsc --noEmit     # Type check
```

### Mobile App (apps/mobile/) — requires Flutter SDK
```bash
cd apps/mobile
flutter pub get
flutter test                              # All tests
flutter test test/models/book_test.dart   # Single test file
flutter run
```

## Architecture

- **apps/mobile/** — Flutter (Dart). ISBN barcode scanning + cover/shelf OCR + book registration. State management via Provider.
- **apps/web/** — React + TypeScript + Vite. Hierarchical dashboard (province → district → school filtering), book search, book detail with school holdings. Uses react-router-dom for routing.
- **packages/shared/** — JSON Schema models (book, school, holding), mock data (15 books, 12 schools, 35 holdings), OpenAPI contract.

### Data Flow (Mock Phase)
Both apps use a repository/service pattern with in-memory mock data. The API interface is defined so swapping to a real backend requires only replacing the service implementation — no UI changes needed.

### Key Patterns
- **Union Catalog**: Single book catalog, schools attach holdings (ownership records). Same ISBN entered by different schools references the same Book record.
- **Fallback chain for ISBN lookup**: Google Books API → Open Library API → manual entry.
- **HierarchyFilter** cascading: Province selection loads districts, district loads schools. All levels have "all" option.

### Web App Structure
- `src/types/` — TypeScript interfaces matching shared JSON schemas
- `src/services/api.ts` — Mock API service (async, mirrors real API contract)
- `src/services/mock-data.ts` — Typed imports of JSON mock data
- `src/pages/` — DashboardPage, SearchPage, BookDetailPage
- `src/components/` — HierarchyFilter, BookTable, SchoolHoldingsList, Layout

### Mobile App Structure
- `lib/models/` — Book, School, Holding Dart classes with fromJson/toJson
- `lib/repositories/` — Abstract BookRepository + MockBookRepository (planned)
- `lib/services/` — IsbnLookupService, OcrService (planned)
- `lib/screens/` — UI screens (planned)

## Mock Data Reference
- Schools: 3 provinces (Ankara, İstanbul, İzmir), 2 districts each, 2 schools per district = 12 schools
- Books: 15 Turkish titles (13 with ISBN, 2 without)
- Holdings: 35 entries linking books to schools
- School IDs follow pattern: `s{n}-{province}-{district}-{name}-{type}`
- Book IDs: `b1` through `b15`
