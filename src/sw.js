const CACHE_STATIC = 'mz-static-v3'
const CACHE_DYNAMIC = 'mz-dynamic-v3'
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json'
]

self.addEventListener('install', (event) => {
  self.skipWaiting()
  event.waitUntil(
    caches.open(CACHE_STATIC).then(cache => cache.addAll(STATIC_ASSETS).catch(()=>{}))
  )
})

self.addEventListener('activate', (event) => {
  clients.claim()
  event.waitUntil(
    caches.keys().then(keys => Promise.all(keys.map(k => {
      if(k !== CACHE_STATIC && k !== CACHE_DYNAMIC) return caches.delete(k)
      return Promise.resolve()
    })))
  )
})

// Helper: network-first for navigation and API; cache-first for static
self.addEventListener('fetch', (event) => {
  const req = event.request
  const url = new URL(req.url)

  // navigation requests (SPA) -> network-first then cache fallback
  if (req.mode === 'navigate'){
    event.respondWith(
      fetch(req)
        .then(res => {
          if (res.ok) {
            const copy = res.clone()
            caches.open(CACHE_DYNAMIC).then(c=>c.put(req, copy))
          }
          return res
        })
        .catch(err => {
          console.error('[SW] Navigation fetch failed:', err)
          return caches.match('/index.html').then(cached => {
            if (cached) return cached
            // 最終フォールバック: オフラインページ
            return new Response('オフラインです。ネットワークを確認してください。', {
              status: 503,
              headers: { 'Content-Type': 'text/html; charset=utf-8' }
            })
          })
        })
    )
    return
  }

  // Static assets: cache-first
  if(url.pathname.startsWith('/assets') || url.pathname.endsWith('.js') || url.pathname.endsWith('.css') || url.pathname.endsWith('.png') || url.pathname.endsWith('.jpg')){
    event.respondWith(
      caches.match(req).then(cacheRes => {
        if (cacheRes) return cacheRes
        return fetch(req).then(res => {
          if (res.ok) {
            caches.open(CACHE_STATIC).then(c=>c.put(req,res.clone()))
          }
          return res
        })
      })
    )
    return
  }

  // For other requests (APIs): try network then cache
  event.respondWith(fetch(req).catch(()=> caches.match(req)))
})
