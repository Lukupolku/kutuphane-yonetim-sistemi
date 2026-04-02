#!/usr/bin/env node
/**
 * Google Books API ile kitap açıklamalarını bul.
 * Kullanım: node scripts/fetch-descriptions.mjs
 */

import { readFileSync, writeFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const BOOKS_PATH = resolve(__dirname, '../packages/shared/mock-data/books.json')
const WEB_BOOKS_PATH = resolve(__dirname, '../apps/web/src/data/books.json')
const DELAY_MS = 1000

const books = JSON.parse(readFileSync(BOOKS_PATH, 'utf-8'))

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms))
}

async function fetchJson(url) {
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': 'KutuphaneYonetim/1.0' }
    })
    if (!res.ok) return null
    return await res.json()
  } catch {
    return null
  }
}

/**
 * ISBN ile Google Books'tan açıklama ara
 */
async function searchByIsbn(isbn) {
  const data = await fetchJson(`https://www.googleapis.com/books/v1/volumes?q=isbn:${isbn}&langRestrict=tr&maxResults=1`)
  return extractDescription(data)
}

/**
 * Başlık + yazar ile Google Books'tan açıklama ara
 */
async function searchByTitle(title, author) {
  const q = encodeURIComponent(`intitle:${title} inauthor:${author}`)
  const data = await fetchJson(`https://www.googleapis.com/books/v1/volumes?q=${q}&langRestrict=tr&maxResults=3`)
  return extractDescription(data)
}

function extractDescription(data) {
  if (!data?.items?.length) return null

  for (const item of data.items) {
    const desc = item.volumeInfo?.description
    if (desc && desc.length > 30) {
      return desc
    }
  }
  return null
}

async function main() {
  let found = 0
  let notFound = 0
  let skipped = 0
  const notFoundList = []

  console.log(`\n📖 ${books.length} kitap için açıklama aranıyor (Google Books)...\n`)

  for (let i = 0; i < books.length; i++) {
    const book = books[i]
    const label = `[${i + 1}/${books.length}] ${book.title}`

    // Zaten açıklama varsa atla
    if (book.description) {
      skipped++
      console.log(`  ⏭️  ${label}`)
      continue
    }

    let desc = null

    // 1. ISBN ile dene
    if (book.isbn) {
      desc = await searchByIsbn(book.isbn)
      await sleep(DELAY_MS)
    }

    // 2. Başlık + yazar ile dene
    if (!desc) {
      desc = await searchByTitle(book.title, book.authors[0])
      await sleep(DELAY_MS)
    }

    if (desc) {
      book.description = desc
      found++
      console.log(`  ✅ ${label} (${desc.length} karakter)`)
    } else {
      book.description = null
      notFound++
      notFoundList.push(`${book.id}: ${book.title}`)
      console.log(`  ❌ ${label}`)
    }
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
