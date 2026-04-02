#!/usr/bin/env node
/**
 * Wikidata API ile yazar profil fotoğraflarını bul.
 * Kullanım: node scripts/fetch-author-photos.mjs
 */

import { readFileSync, writeFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'
import { createHash } from 'crypto'

const __dirname = dirname(fileURLToPath(import.meta.url))
const AUTHORS_PATH = resolve(__dirname, '../packages/shared/mock-data/authors.json')
const WEB_AUTHORS_PATH = resolve(__dirname, '../apps/web/src/data/authors.json')
const DELAY_MS = 1000 // Wikidata rate limit

const authors = JSON.parse(readFileSync(AUTHORS_PATH, 'utf-8'))

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms))
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

/**
 * Wikidata'da yazar adıyla arama yap, entity ID döndür.
 */
async function searchWikidata(name) {
  const params = new URLSearchParams({
    action: 'wbsearchentities',
    search: name,
    language: 'tr',
    format: 'json',
    limit: '5',
    type: 'item'
  })

  const data = await fetchJson(`https://www.wikidata.org/w/api.php?${params}`)
  if (!data?.search?.length) return null

  // İlk sonucu döndür (genelde doğru eşleşme)
  return data.search[0].id
}

/**
 * Entity'den P18 (image) claim'ini al.
 */
async function getEntityImage(entityId) {
  const params = new URLSearchParams({
    action: 'wbgetentities',
    ids: entityId,
    props: 'claims',
    format: 'json'
  })

  const data = await fetchJson(`https://www.wikidata.org/w/api.php?${params}`)
  if (!data?.entities?.[entityId]) return null

  const claims = data.entities[entityId].claims
  const p18 = claims?.P18
  if (!p18?.length) return null

  const filename = p18[0].mainsnak?.datavalue?.value
  if (!filename) return null

  return commonsThumbUrl(filename, 300)
}

/**
 * Wikimedia Commons dosya adından thumb URL oluştur.
 * URL format: https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Filename.jpg/300px-Filename.jpg
 */
function commonsThumbUrl(filename, width) {
  // Boşlukları alt çizgiye çevir
  const normalizedName = filename.replace(/ /g, '_')
  const hash = createHash('md5').update(normalizedName).digest('hex')
  const a = hash[0]
  const ab = hash.substring(0, 2)

  return `https://upload.wikimedia.org/wikipedia/commons/thumb/${a}/${ab}/${normalizedName}/${width}px-${normalizedName}`
}

async function main() {
  let found = 0
  let notFound = 0
  let skipped = 0
  const notFoundList = []

  console.log(`\n📸 ${authors.length} yazar için profil fotoğrafı aranıyor (Wikidata)...\n`)

  for (let i = 0; i < authors.length; i++) {
    const author = authors[i]
    const label = `[${i + 1}/${authors.length}] ${author.name}`

    // Zaten fotoğraf varsa atla
    if (author.photoUrl) {
      skipped++
      console.log(`  ⏭️  ${label}`)
      continue
    }

    // 1. Wikidata'da ara
    const entityId = await searchWikidata(author.name)
    await sleep(DELAY_MS)

    if (!entityId) {
      author.photoUrl = null
      notFound++
      notFoundList.push(`${author.id}: ${author.name}`)
      console.log(`  ❌ ${label} (Wikidata'da bulunamadı)`)
      continue
    }

    // 2. Entity'den P18 al
    const photoUrl = await getEntityImage(entityId)
    await sleep(DELAY_MS)

    if (photoUrl) {
      author.photoUrl = photoUrl
      found++
      console.log(`  ✅ ${label} → ${entityId}`)
    } else {
      author.photoUrl = null
      notFound++
      notFoundList.push(`${author.id}: ${author.name} (${entityId} - fotoğraf yok)`)
      console.log(`  ❌ ${label} → ${entityId} (P18 yok)`)
    }
  }

  // Kaydet
  writeFileSync(AUTHORS_PATH, JSON.stringify(authors, null, 2) + '\n', 'utf-8')
  writeFileSync(WEB_AUTHORS_PATH, JSON.stringify(authors, null, 2) + '\n', 'utf-8')

  console.log(`\n${'─'.repeat(50)}`)
  console.log(`✅ Bulunan: ${found}`)
  console.log(`❌ Bulunamayan: ${notFound}`)
  console.log(`⏭️  Zaten mevcut: ${skipped}`)
  console.log(`📁 Kaydedildi: ${AUTHORS_PATH}`)

  if (notFoundList.length > 0) {
    console.log(`\nBulunamayan yazarlar:`)
    notFoundList.forEach(t => console.log(`  - ${t}`))
  }
  console.log()
}

main().catch(console.error)
