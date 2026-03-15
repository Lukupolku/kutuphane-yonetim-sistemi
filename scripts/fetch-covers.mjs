#!/usr/bin/env node
/**
 * Open Library API ile kitap kapak resimlerini bul.
 * Kullanım: node scripts/fetch-covers.mjs
 */

import { readFileSync, writeFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const BOOKS_PATH = resolve(__dirname, '../packages/shared/mock-data/books.json')
const WEB_BOOKS_PATH = resolve(__dirname, '../apps/web/src/data/books.json')
const DELAY_MS = 1000 // Open Library rate limit: 1 req/sec

const books = JSON.parse(readFileSync(BOOKS_PATH, 'utf-8'))

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms))
}

// Open Library cover URL'leri: S=small, M=medium, L=large
function coverUrl(coverId) {
  return `https://covers.openlibrary.org/b/id/${coverId}-L.jpg`
}

function coverUrlByIsbn(isbn) {
  return `https://covers.openlibrary.org/b/isbn/${isbn}-L.jpg`
}

async function fetchJson(url) {
  try {
    const res = await fetch(url)
    if (!res.ok) return null
    return await res.json()
  } catch {
    return null
  }
}

// Check if a cover URL actually returns an image (not a 1x1 placeholder)
async function isValidCover(url) {
  try {
    const res = await fetch(url, { method: 'HEAD', redirect: 'follow' })
    if (!res.ok) return false
    const len = res.headers.get('content-length')
    // Open Library returns a tiny 1x1 gif for missing covers (~43 bytes)
    return len && parseInt(len) > 1000
  } catch {
    return false
  }
}

async function searchOpenLibrary(title, author) {
  // Sadece soyadını kullan
  const authorParts = author.split(' ')
  const surname = authorParts[authorParts.length - 1]

  const params = new URLSearchParams({
    title: title,
    author: surname,
    limit: '3',
    fields: 'cover_i,title,author_name,isbn,cover_edition_key'
  })

  const data = await fetchJson(`https://openlibrary.org/search.json?${params}`)
  if (!data?.docs?.length) return null

  // 1. cover_i varsa kullan
  for (const doc of data.docs) {
    if (doc.cover_i) {
      return coverUrl(doc.cover_i)
    }
  }

  // 2. ISBN'den cover dene
  for (const doc of data.docs) {
    if (doc.isbn?.length) {
      for (const isbn of doc.isbn.slice(0, 3)) {
        const url = coverUrlByIsbn(isbn)
        if (await isValidCover(url)) {
          return url
        }
      }
    }
  }

  return null
}

async function tryIsbnDirect(isbn) {
  const url = coverUrlByIsbn(isbn)
  if (await isValidCover(url)) return url
  return null
}

async function main() {
  let found = 0
  let notFound = 0
  let skipped = 0
  const notFoundList = []

  console.log(`\n📚 ${books.length} kitap için kapak resmi aranıyor (Open Library)...\n`)

  for (let i = 0; i < books.length; i++) {
    const book = books[i]
    const label = `[${i + 1}/${books.length}] ${book.title} — ${book.authors[0]}`

    // Zaten kapak varsa atla
    if (book.coverImageUrl) {
      skipped++
      console.log(`  ⏭️  ${label}`)
      continue
    }

    let url = null

    // 1. ISBN varsa direkt dene
    if (book.isbn) {
      url = await tryIsbnDirect(book.isbn)
    }

    // 2. Open Library arama
    if (!url) {
      await sleep(DELAY_MS)
      url = await searchOpenLibrary(book.title, book.authors[0])
    }

    if (url) {
      book.coverImageUrl = url
      found++
      console.log(`  ✅ ${label}`)
    } else {
      notFound++
      notFoundList.push(`${book.id}: ${book.title}`)
      console.log(`  ❌ ${label}`)
    }

    await sleep(DELAY_MS)
  }

  // Kaydet
  writeFileSync(BOOKS_PATH, JSON.stringify(books, null, 2) + '\n', 'utf-8')
  writeFileSync(WEB_BOOKS_PATH, JSON.stringify(books, null, 2) + '\n', 'utf-8')

  console.log(`\n${'─'.repeat(50)}`)
  console.log(`✅ Bulunan: ${found}`)
  console.log(`❌ Bulunamayan: ${notFound}`)
  console.log(`⏭️  Zaten mevcut: ${skipped}`)
  console.log(`📁 Kaydedildi: ${BOOKS_PATH}`)

  if (notFoundList.length > 0) {
    console.log(`\nBulunamayan kitaplar:`)
    notFoundList.forEach(t => console.log(`  - ${t}`))
  }
  console.log()
}

main().catch(console.error)
