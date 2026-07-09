# Checklist de rollout — rodada de melhorias 09/07/2026

## O que precisa de ação SUA (fora do código)

1. **Family Controls (Distribution) para as extensões** — sem isso o shield
   matinal continua falhando em TestFlight. Passo a passo e texto pronto em
   [family-controls-entitlement-request.md](family-controls-entitlement-request.md).
   ⚠️ Até a Apple aprovar e as capabilities serem habilitadas nos App IDs, o
   *archive de distribuição* falha com os novos entitlements. Para subir build
   antes disso, remova temporariamente a chave `com.apple.developer.family-controls`
   dos 3 arquivos `Limiar/Extensions/*/*.entitlements`.

2. **Blob Store para o cache de TTS** — no painel do Vercel: projeto `limiar`
   → Storage → Create → Blob. Ao conectar ao projeto, o env
   `BLOB_READ_WRITE_TOKEN` é criado sozinho e o cache passa a funcionar no
   próximo deploy. Sem o store, o endpoint segue funcionando sem cache.

3. **Segredo da API (`LIMIAR_APP_SECRET`)** — o app novo já envia o header
   `X-Limiar-App-Key`. **NÃO configure o env ainda**: builds antigos do
   TestFlight não enviam o header e passariam a receber 401. Quando a base
   estiver no build novo, configure no Vercel:
   `LIMIAR_APP_SECRET = ecd84911de218255c18e6551955558dbf09df77d26490f07`
   (mesmo valor de `RemoteAIBackendClient.appKey` no app).

## Como validar depois do deploy

- **Backend**: os testes rodam no CI (`.github/workflows/ci.yml`) a cada push.
  Teste manual: POST em `https://limiar-five.vercel.app/api/reading-session`.
- **Shield**: build de desenvolvimento via Xcode → concluir a travessia à noite
  → manter o app fechado → conferir de manhã se o shield voltou. A tela
  **Configurações → Sobre → Diagnóstico técnico** mostra os eventos
  (`monitor.interval_did_start` às 5h = extensão viva; `monitor.shield_reapplied`
  = shield rearmado).
- **Catálogo**: `python3 scripts/validate_passages.py` (também roda no CI).

## Mudanças que já estão no código (resumo)

- Shield: entitlement nas 3 extensões, stop→start no monitoring, timezone do
  dispositivo, botão do shield com `.close` + copy, eventos logados.
- Catálogo em `Limiar/Resources/passages.json` (expandido, balanceado por livro).
- Backend: região `gru1`, segredo opcional, cache de TTS via Blob.
- App: ContentView dividido por feature, código morto removido, histórico
  limitado a 365, versões das extensões unificadas via `MARKETING_VERSION`.
