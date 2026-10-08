self.addEventListener("install",()=>self.skipWaiting());
self.addEventListener("fetch",e=>{if(e.request.method!=="GET"||!e.request.url.startsWith(self.location.origin))return;
e.respondWith(fetch(e.request).then(r=>{const c=r.clone();caches.open("md1").then(h=>h.put(e.request,c));return r}).catch(()=>caches.match(e.request)))});
