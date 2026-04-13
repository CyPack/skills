# MCP Ortak Pattern'ler

## Hata Recovery

| MCP Hatasi | Anlami | Recovery |
|------------|--------|----------|
| Tool returned error | Server-side failure | error.message kontrol, per-skill fix |
| Tool call timeout | Server unresponsive | 5s bekle, retry. Basarisiz → restart |
| Tool not found | MCP server baslamadi | claude mcp restart {server} |
| Invalid parameters | Yanlis arg tipi | SKILL.md parametre tablosu kontrol |
| 429 Too Many Requests | Rate limit asimi | Exponential backoff (1s→2s→4s). Free plan'da persistent olabilir → image/export fallback |
| 401/403 Token expired | Auth gecersiz | Token yenile, config guncelle, session restart |
| ECONNREFUSED Docker IP | Container IP degisti | `docker inspect` ile IP bul, config guncelle |

## Ortak Pattern'ler

- **Pre-auth:** Ilk tool call oncesi status/get_status cagir (varsa)
- **Session recovery:** Auth error → re-login → retry
- **Graceful degradation:** MCP unavailable → kullaniciya bildir
- **Progressive depth:** Once depth=1 (genel bakis), sonra depth=2+ (detay). Rate limit riskini azaltir
- **Image export fallback:** API rate limit'te image/screenshot export kullan (genellikle ayri rate limit bucket)
- **Visual inspection fallback:** API verisi alinamazsa export edilen goruntuleri multimodal analiz ile incele — design token extraction mumkun
- **Paralel cagri yasagi:** Rate-limited API'lerde ASLA paralel cagri yapma. Sirayla, tek tek cagir
- **MCP server stdout kirlilik:** stderr'e JSON yazan server'lar icin `bash -c "node server.js 2>/dev/null"` wrapper kullan

## Rate Limit Stratejisi

| Seviye | Aksiyon |
|--------|---------|
| Ilk 429 | 5s bekle, retry |
| 2. 429 | 15s bekle, retry |
| 3. 429 | Fallback stratejiye gec (image export, visual inspection) |
| Persistent 429 | Kullaniciya bildir, mevcut verilerle devam et |

## MCP Tool Discovery

```
1. ToolSearch ile araclari bul (keyword veya select:)
2. Tool BULUNDUYSA → hemen kullan (tekrar select: YAPMA)
3. Tool BULUNAMADIYSA → MCP server durumu kontrol et
4. Server DOWN → restart / config kontrol
```
