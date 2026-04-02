#!/usr/bin/env node
/**
 * kitapyurdu.com'dan kitap açıklamalarını çek.
 * Kullanım: node scripts/fetch-descriptions-kitapyurdu.mjs
 */

import { readFileSync, writeFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const BOOKS_PATH = resolve(__dirname, '../packages/shared/mock-data/books.json')
const WEB_BOOKS_PATH = resolve(__dirname, '../apps/web/src/data/books.json')
const DELAY_MS = 2000

const books = JSON.parse(readFileSync(BOOKS_PATH, 'utf-8'))

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms))
}

async function fetchHtml(url) {
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept-Language': 'tr-TR,tr;q=0.9',
        'Accept': 'text/html,application/xhtml+xml'
      }
    })
    if (!res.ok) return null
    return await res.text()
  } catch {
    return null
  }
}

/**
 * HTML'den basit text çıkar (tag'leri temizle)
 */
function stripHtml(html) {
  return html
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\n{3,}/g, '\n\n')
    .trim()
}

/**
 * kitapyurdu arama sayfasından ilk sonucun URL'ini al
 */
async function searchKitapyurdu(title) {
  const searchUrl = `https://www.kitapyurdu.com/index.php?route=product/search&filter_name=${encodeURIComponent(title)}`
  const html = await fetchHtml(searchUrl)
  if (!html) return null

  // Ürün linkini bul: /kitap/SLUG/ID.html
  const match = html.match(/href="(https:\/\/www\.kitapyurdu\.com\/kitap\/[^"]+\.html)"/i)
  return match ? match[1] : null
}

/**
 * Kitap detay sayfasından açıklamayı çek
 */
async function getDescription(url) {
  const html = await fetchHtml(url)
  if (!html) return null

  // #description_text içeriğini çek
  const match = html.match(/id="description_text"[^>]*>([\s\S]*?)<\/div>/i)
  if (!match) return null

  const text = stripHtml(match[1])
  return text.length > 20 ? text : null
}

async function main() {
  const missing = books.filter(b => !b.description)
  let found = 0
  let notFound = 0

  console.log(`\n📖 ${missing.length} kitap için açıklama aranıyor (kitapyurdu.com)...\n`)

  for (let i = 0; i < missing.length; i++) {
    const book = missing[i]
    const label = `[${i + 1}/${missing.length}] ${book.title}`

    // 1. Kitapyurdu'da ara
    const bookUrl = await searchKitapyurdu(book.title)
    await sleep(DELAY_MS)

    if (!bookUrl) {
      notFound++
      console.log(`  ❌ ${label} (arama sonucu yok)`)
      continue
    }

    // 2. Detay sayfasından açıklamayı çek
    const desc = await getDescription(bookUrl)
    await sleep(DELAY_MS)

    if (desc) {
      book.description = desc
      found++
      console.log(`  ✅ ${label} (${desc.length} karakter)`)
    } else {
      notFound++
      console.log(`  ❌ ${label} (açıklama yok)`)
    }
  }

  // Kaydet
  writeFileSync(BOOKS_PATH, JSON.stringify(books, null, 2) + '\n', 'utf-8')
  writeFileSync(WEB_BOOKS_PATH, JSON.stringify(books, null, 2) + '\n', 'utf-8')

  console.log(`\n${'─'.repeat(50)}`)
  console.log(`✅ Bulunan: ${found}`)
  console.log(`❌ Bulunamayan: ${notFound}`)
  console.log(`📁 Kaydedildi: ${BOOKS_PATH}`)
  console.log()
}

main().catch(console.error)
