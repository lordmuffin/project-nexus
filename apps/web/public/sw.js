// Service Worker for Project Nexus PWA
// Provides offline capabilities and caching for improved performance

const CACHE_NAME = 'nexus-v1.0.0';
const STATIC_CACHE_NAME = 'nexus-static-v1.0.0';
const DYNAMIC_CACHE_NAME = 'nexus-dynamic-v1.0.0';

// Cache essential files for offline usage
const STATIC_ASSETS = [
  '/',
  '/manifest.json'
];

// Cache API responses temporarily
const API_CACHE_URLS = [
  '/api/chat/sessions',
  '/api/chat/health',
  '/api/notes'
];

// Install service worker
self.addEventListener('install', (event) => {
  console.log('Service Worker: Installing...');
  event.waitUntil(
    caches.open(STATIC_CACHE_NAME)
      .then((cache) => {
        console.log('Service Worker: Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .catch((error) => {
        console.error('Service Worker: Error caching static assets:', error);
      })
  );
  self.skipWaiting();
});

// Activate service worker
self.addEventListener('activate', (event) => {
  console.log('Service Worker: Activating...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== STATIC_CACHE_NAME && cacheName !== DYNAMIC_CACHE_NAME) {
            console.log('Service Worker: Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Fetch event handler - Network first strategy for API calls, Cache first for static assets
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Handle API requests with network-first strategy
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          // Clone response before caching
          const responseClone = response.clone();
          
          // Cache successful API responses
          if (response.status === 200) {
            caches.open(DYNAMIC_CACHE_NAME)
              .then((cache) => {
                cache.put(request, responseClone);
              });
          }
          
          return response;
        })
        .catch(() => {
          // Return cached version if network fails
          return caches.match(request)
            .then((cachedResponse) => {
              if (cachedResponse) {
                return cachedResponse;
              }
              
              // Return offline fallback for critical endpoints
              if (url.pathname.includes('/chat/sessions')) {
                return new Response(JSON.stringify({
                  success: false,
                  error: 'You are offline. Please check your connection to use the AI assistant.',
                  offline: true
                }), {
                  status: 503,
                  headers: {
                    'Content-Type': 'application/json'
                  }
                });
              }
              
              // Return a fallback response instead of throwing error
              return new Response(JSON.stringify({
                success: false,
                error: 'Service temporarily unavailable',
                offline: true
              }), {
                status: 503,
                headers: {
                  'Content-Type': 'application/json'
                }
              });
            });
        })
    );
    return;
  }

  // Handle static assets with cache-first strategy
  event.respondWith(
    caches.match(request)
      .then((cachedResponse) => {
        if (cachedResponse) {
          return cachedResponse;
        }
        
        return fetch(request)
          .then((response) => {
            // Don't cache non-successful responses
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }
            
            // Clone response before caching
            const responseClone = response.clone();
            
            caches.open(DYNAMIC_CACHE_NAME)
              .then((cache) => {
                cache.put(request, responseClone);
              });
            
            return response;
          });
      })
      .catch(() => {
        // Return offline fallback for navigation requests
        if (request.mode === 'navigate') {
          return caches.match('/');
        }
        throw new Error('Request failed and no cache available');
      })
  );
});

// Handle background sync for offline message queue
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync-messages') {
    console.log('Service Worker: Background sync triggered for messages');
    event.waitUntil(syncMessages());
  }
});

// Handle push notifications (for future features)
self.addEventListener('push', (event) => {
  console.log('Service Worker: Push notification received');
  
  const options = {
    body: event.data ? event.data.text() : 'New notification from Nexus',
    icon: '/favicon.ico',
    badge: '/favicon.ico',
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    },
    actions: [
      {
        action: 'explore',
        title: 'Open Nexus',
        icon: '/favicon.ico'
      },
      {
        action: 'close',
        title: 'Close',
        icon: '/favicon.ico'
      }
    ]
  };
  
  event.waitUntil(
    self.registration.showNotification('Project Nexus', options)
  );
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('Service Worker: Notification clicked');
  event.notification.close();
  
  if (event.action === 'explore') {
    event.waitUntil(
      clients.openWindow('/chat')
    );
  }
});

// Sync messages when coming back online
async function syncMessages() {
  try {
    // Get pending messages from IndexedDB
    const db = await openDB();
    const tx = db.transaction(['pendingMessages'], 'readonly');
    const store = tx.objectStore('pendingMessages');
    const pendingMessages = await store.getAll();
    
    // Send pending messages
    for (const message of pendingMessages) {
      try {
        const response = await fetch('/api/chat/sessions/${message.sessionId}/messages', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            content: message.content
          }),
        });
        
        if (response.ok) {
          // Remove from pending queue
          const deleteTx = db.transaction(['pendingMessages'], 'readwrite');
          const deleteStore = deleteTx.objectStore('pendingMessages');
          await deleteStore.delete(message.id);
        }
      } catch (error) {
        console.error('Failed to sync message:', error);
      }
    }
  } catch (error) {
    console.error('Background sync failed:', error);
  }
}

// IndexedDB helpers for offline storage
function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('NexusDB', 1);
    
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      
      // Create stores for offline data
      if (!db.objectStoreNames.contains('pendingMessages')) {
        const store = db.createObjectStore('pendingMessages', { keyPath: 'id' });
        store.createIndex('sessionId', 'sessionId', { unique: false });
      }
      
      if (!db.objectStoreNames.contains('chatMessages')) {
        const store = db.createObjectStore('chatMessages', { keyPath: 'id' });
        store.createIndex('sessionId', 'sessionId', { unique: false });
      }
      
      if (!db.objectStoreNames.contains('notes')) {
        const store = db.createObjectStore('notes', { keyPath: 'id' });
        store.createIndex('title', 'title', { unique: false });
      }
    };
  });
}