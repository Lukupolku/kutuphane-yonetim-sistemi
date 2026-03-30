# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Monorepo with two apps:
- **Rafta** — Personal home library management mobile app (Flutter)
- **MEB Okul Kutuphaneleri Yonetim Sistemi** — School library dashboard (React)

## Commands

### Web Dashboard (apps/web/)
```bash
cd apps/web
npm run dev          # Dev server at localhost:5173
npm run build        # Production build
npx vitest run       # Run all tests
npx tsc --noEmit     # Type check
```

### Mobile App — Rafta (apps/mobile/) — requires Flutter SDK
```bash
cd apps/mobile
flutter pub get
flutter analyze      # Static analysis
flutter run          # Run on device/emulator
```

## Architecture

### Mobile App — Rafta (apps/mobile/)
Personal home library manager for kids and adults. SQLite local database, Provider state management.

**Data Model:**
- Room → Bookshelf → Shelf → Book (physical library hierarchy)
- UserBook: user's copy with status (toRead/reading/read/dropped), rating, favorites
- BookNote: highlights, notes, quotes linked to books (OCR from page photos)
- Lending: track who borrowed which book
- ReadingList: user-created or API-suggested book lists

**Key Services:**
- `BookLookupService`: Google Books API → Open Library API → manual entry (fallback chain)
- OCR via google_mlkit_text_recognition for page note capture
- Barcode scanning via mobile_scanner for ISBN lookup

**Structure:**
- `lib/models/` — Room, Bookshelf, Shelf, Book, UserBook, BookNote, Lending, ReadingList
- `lib/database/database_helper.dart` — SQLite schema and singleton
- `lib/providers/` — LibraryProvider (rooms/shelves), BookProvider (books/notes/lending)
- `lib/services/` — BookLookupService (API integration)
- `lib/screens/` — HomeScreen, LibraryScreen, BookDetailScreen, SearchScreen, BarcodeScanScreen, NoteCaptureScreen
- `lib/widgets/` — BookCard, RatingWidget, ErrorView

### Web Dashboard (apps/web/)
React + TypeScript + Vite. School library dashboard with hierarchical filtering, book catalog, school comparison heat map.

- `src/pages/` — DashboardPage, SearchPage, BookDetailPage, ComparePage, LoginPage, NotFoundPage
- `src/components/` — HierarchyFilter, BookTable, Layout, ErrorBoundary
- `src/services/api.ts` — Mock API service (async, mirrors real API contract)
- `src/contexts/AuthContext.tsx` — Role-based auth with session persistence

### Shared (packages/shared/)
JSON Schema models, mock data (15 books, 12 schools, 41 holdings), OpenAPI contract. Used by web app only.

## Key Patterns
- **Fallback chain for ISBN lookup**: Google Books API → Open Library API → manual entry
- **MEB bordo theme**: Primary #8B1A2B, shared between web and mobile via theme.dart / index.css
- **Provider pattern**: ChangeNotifier-based state management in mobile app
- **SQLite local DB**: All mobile data persisted locally via sqflite
