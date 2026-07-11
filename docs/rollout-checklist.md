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

3. **Proteção da API** — manter o rate limit ativo. Se `LIMIAR_APP_SECRET`
   for usado temporariamente, seu valor deve ser injetado no build por uma
   configuração local não versionada e rotacionado no Vercel. Uma chave
   embutida no aplicativo não substitui App Attest e não deve ser tratada como
   segredo permanente.

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
