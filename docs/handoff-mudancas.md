# Limiar — Resumo de mudanças (handoff para o desenvolvedor)

Repositório: `rmocunha83-droid/limiar` · Branch: `main` (push em main = deploy automático do Vercel).
App iOS em `Limiar/` · Backend serverless em `api/` (Vercel, produção `https://limiar-five.vercel.app`).

Todas as mudanças abaixo já estão **commitadas e no `main`**. As de **backend já estão em produção**. As de **app entram na próxima build** que for arquivada para o TestFlight/App Store.

---

## 1. Backend / geração de leituras (Vercel — JÁ EM PRODUÇÃO)

**Arquitetura da geração** (`api/_limiar-ai.js`, `api/reading-session.js`, `spiritual-reading.js`, `reflection.js`):
- O **servidor seleciona os 3 trechos de forma determinística** (`selectSessionPassages`). `favoriteBooks` aceita até 40 livros e permanece como a união das categorias. `priorityBooks` é opcional: até dois trechos frescos por sessão vêm desses livros, e a vaga restante privilegia descoberta fora deles. Se houver tema favorito, o servidor garante um trecho fresco desse tema quando houver candidato permitido. A IA **não escolhe mais** os versículos.
- **Compatibilidade:** builds já publicados, que não enviam `priorityBooks`, continuam no caminho legado de seleção; o novo campo só é usado pelo app atualizado.
- A **IA gera só as explicações** (homily, spiritualMeaning, practicalApplication, conclusion, meditationQuestion), com JSON Schema `strict`. Referência e texto bíblico vêm sempre do trecho selecionado — a IA nunca reescreve versículo.
- **Removido o retry pesado de diversidade** (era a causa dos 422 e da latência de ~24s).
- Modelo: OpenAI `gpt-5.4-mini` via **Responses API**. `reasoning effort = none` (tier mais rápido suportado; ajustável por env `OPENAI_REASONING_EFFORT`). Budget de tokens por profundidade corrigido (evita JSON truncado).

**Endurecimento e performance:**
- `vercel.json`: região **`gru1`** (São Paulo) — funções perto dos usuários.
- **Proteção do backend**: o rate limit permanece obrigatório. `LIMIAR_APP_SECRET` é opcional e, quando usado temporariamente, deve ser injetado no build sem entrar no Git. Uma chave estática no binário não substitui App Attest.
- **Cache de TTS** (`api/speech.js`) via Vercel Blob: cada áudio é sintetizado uma vez e reusado. A chave inclui provedor, voz efetiva e a assinatura completa do tom (`rate`, `pitch`, pausa e versão da fala da referência), então uma troca de motor ou prosódia não entrega áudio antigo. Qualquer parâmetro futuro de SSML que altere o som também deve entrar nessa assinatura. Requer criar um **Blob Store** no painel do Vercel (gera `BLOB_READ_WRITE_TOKEN`). Sem o token, funciona como antes (sintetiza sempre).
- **Tom sereno e referência proclamada:** o Antônio usa por padrão `rate=-10%`, `pitch=-3%` e pausa respirada de `500ms` entre referência e texto. A referência é ajustada somente no SSML (por exemplo, `Mateus 11, 28-30` é falado como `Mateus 11, versículos 28 a 30`); a string canônica `"{reference}.\n{text}"`, a tela e o hash do texto permanecem intocados.
- **Ativação obrigatoriamente em três etapas:** (1) executar `npm run tone:preview` e ouvir/aprovar os seis MP3 locais; (2) fazer merge/deploy; (3) somente então executar `npm run prewarm:narration` para os 977 trechos. **Não executar o prewarm antes da aprovação humana.** O custo único estimado do novo lote é de **R$ 20–30**. Os áudios da assinatura anterior ficam órfãos no Blob, mas são inofensivos; as explicações sintetizadas ao vivo adotam o tom novo automaticamente no deploy. Rode o prewarm novamente sempre que catálogo, voz, tom ou regra de fala mudar.

**Testes:** `tests/ai-backend.test.js` (`npm run test:ai-backend`). CI em `.github/workflows/ci.yml` roda testes + validação do catálogo + build iOS.

**Modo Essencial / conversão:** salvar trechos, histórico e lista de salvos são Premium; no Essencial, o toque abre o paywall e os favoritos antigos permanecem visíveis sem ser apagados. A Reflexão breve mostra um teaser trancado quando há conteúdo. Leituras e explicações essenciais continuam usando o backend de texto (há custo de IA); narração e reflexão completa permanecem bloqueadas. As listas D6/D8 citam “Salvar trechos e rever seu histórico”; a D7 não promete mais salvar no Essencial.

---

## 2. Catálogo de trechos bíblicos

- Migrado de código Swift hardcoded para **`Limiar/Resources/passages.json`** (empacotado no app). Loader em `PassageCatalog` (`PassageServices.swift`) com fallback de emergência embutido.
- Expandido de ~145 → **977 trechos** (católica 314, evangélica 314, judaica 189, espírita 160).
- **18 livros novos** no enum `BibleBook`: Marcos, Jó, Eclesiastes, Cantares, Gálatas, Efésios, Hebreus, Tiago, Pedro, Jeremias, Ezequiel, Daniel, Josué, Juízes, Rute, Ester, Judite, Baruque (nomes hebraicos na tradição judaica).
- **Validador** `scripts/validate_passages.py` (`npm run validate:passages`, roda no CI): IDs/refs únicos, coerência livro↔seção, regras de cânon por tradição (sem NT/deuterocanônico vazando para a judaica, etc.).

---

## 3. Onboarding — passo "Leituras" refeito

- As duas listas sobrepostas ("Tipos de leitura" + "Livros") viraram **um seletor único de categorias de estilo**, dirigido por config (`ReadingStyleCategory` / `TraditionReadingConfig` em `LimiarModels.swift`) — mesmo componente para as 4 tradições, só muda o dado.
- Seleção forte (fill sage + check), contador com mínimo 1 e aviso gentil; título sempre visível (bug do texto cortado corrigido).
- **"Afinar por livros específicos"**: passo opcional recolhido que mostra **todos os livros da tradição** (escolha individual). Quando marcado, os livros escolhidos passam a ter prioridade diária, sem excluir a união das categorias; isso preserva variedade para livros pequenos.
- Espírita: temas saíram do passo Leituras e voltaram ao passo TEMAS (com lista de temas própria da tradição). Todas as tradições passam pelos mesmos passos.
- Perfis antigos migram sozinhos (inferência das categorias pelas escolhas salvas).
- `ContentView.swift` (era ~3k linhas) foi **dividido** em `TrialViews.swift`, `ReadingViews.swift`, `OnboardingViews.swift`, `SettingsViews.swift`, `SharedUI.swift`.

---

## 4. Latência percebida — pré-geração em background

Geração leva ~11-13s; agora ela acontece em tempo morto, não na frente do usuário (`LimiarModels.swift`, `DailyReadingSessionStore` em `PassageServices.swift`):
- **Onboarding:** dispara a geração ao entrar no passo ATIVAÇÃO (enquanto o usuário autoriza o Tempo de Uso). Dashboard abre com conteúdo pronto.
- **Manhã seguinte:** após concluir a travessia do dia, pré-gera a sessão do **próximo ciclo** e persiste (chave do dia seguinte). App abre instantâneo às 5h, mesmo em cold start.
- Fallback: se as preferências mudarem ou a pré-geração falhar, cai no fluxo ao vivo normal.

---

## 5. Shield matinal (Screen Time) — confiabilidade

- **Entitlement Family Controls adicionado às 3 extensões** (DeviceActivityMonitor, ShieldAction, ShieldConfiguration) — era a causa raiz de o shield não rearmar às 5h. **Já aprovado pela Apple** (build 80 aprovada na App Store com isso).
- `ScreenTimeController` / `DeviceActivityMonitorExtension`: timezone do dispositivo (era São Paulo fixo), cálculo do ciclo das 5h robusto a horário de verão, botão do shield com copy correta pré-iOS 26.5.
- **Observabilidade:** `LimiarEventLog` (App Group) grava eventos do app e da extensão; tela **Configurações → Sobre → Diagnóstico técnico** mostra os eventos (`monitor.interval_did_start` às 5h = extensão viva; `monitor.shield_reapplied` = rearmado). `os.Logger` no lugar dos `debugPrint`.
- Fix de cold start: `init()` não limpa mais o shield antes do StoreKit restaurar a assinatura (`SubscriptionManager` cacheia o entitlement no App Group).

## 5b. Release 1.3 · build 110 — correções antes do envio

- **Preço sem ambiguidade:** o plano anual destaca o valor integral localizado pelo StoreKit com `/ano`, informa que a cobrança ocorre uma vez por ano e mantém o equivalente diário como apoio. O mensal usa `/mês`, e a renovação também explicita o período. Esta correção é bloqueadora para o envio à App Store.
- **Modo Essencial / AdMob:** o banner adaptativo agora recebe somente a largura real do container, sem realimentar o layout com o próprio `bounds`. A altura vem do `adSize`, é reservada antes do carregamento e o anúncio não é mais recortado. Validado em iPhone SE e Pro Max sem conteúdo deslocado ou texto cortado.
- **Início dos 7 dias:** a tela virou uma boas-vindas sem preços, cartão ou pressão antecipada. O botão continua chamando o mesmo `startFreeTrial()` e deixa claro que nenhuma assinatura começa nessa etapa.
- **Legibilidade:** FreeTrial, D6, D7 e D8 usam uma única régua escalável com Dynamic Type limitado a `xxLarge`; textos essenciais partem de 14pt, depoimentos usam 16pt e o carrossel cresce para não truncar.
- **Narração:** referências somente com capítulo, como `Salmo 23`, recebem a pausa devocional correta; `break=0` preserva separação. Pausar durante a emenda de 600ms segura a fila e a retomada continua no próximo segmento.
- **Acabamentos:** remoção de foto exige confirmação e o processamento de fotos grandes ocorre fora da MainActor; narração bloqueada ganha cadeado no Essencial; código morto de favoritos foi removido e a busca do catálogo passou a usar índices em memória.
- **Validação:** screenshots ficam em `docs/screenshots/`; testes do backend e build iOS devem estar verdes antes de criar a build no Xcode Cloud.

---

## 6. Marketing / rastreamento Meta (site — JÁ EM PRODUÇÃO)

- Pixel + **Conversions API** (`api/meta-capi.js` + snippet nos HTMLs) com deduplicação navegador/servidor. Estava rodando só em deploys por CLI e sumia a cada push do GitHub; agora está commitado (fonte única = repositório).
- Requer env `META_CAPI_ACCESS_TOKEN` válido no Vercel (token do Events Manager).

---

## AÇÕES PENDENTES (dependem de você / do desenvolvedor)

1. **Arquivar a próxima build** com as mudanças de app (itens 2, 3, 4, 5). Precisa de: certificado de assinatura instalado no keychain do Mac (abrir o Xcode logado e Manage Certificates → criar Apple Development/Distribution).
2. **Vercel → criar Blob Store** para ativar o cache de TTS (item 1).
3. **Vercel → revisar `LIMIAR_APP_SECRET`**. Não ativar uma chave estática versionada; manter o rate limit e planejar App Attest para autenticação real do aplicativo.
4. **Vercel → conferir `META_CAPI_ACCESS_TOKEN`** válido (logs mostraram token inválido em algum momento).
5. Conferir no Vercel que `OPENAI_MODEL`/`OPENAI_BASE_URL` apontam para OpenAI (houve fase antiga com Z.AI GLM).

---

## Fase 2 recomendada (não implementada — projeto à parte)

**Catálogo remoto:** servir `passages.json` por um endpoint do Vercel; o app baixa/atualiza em background e usa o bundle como fallback offline. Permite crescer e corrigir conteúdo **sem release na App Store**. Exige endpoint versionado (ETag), sync no app e validação server-side obrigatória. Detalhe em conversa com a equipe antes de encarar.

---

## Variáveis de ambiente do backend (referência)

`OPENAI_API_KEY`, `OPENAI_MODEL`, `OPENAI_BASE_URL`, `OPENAI_REASONING_EFFORT`, `OPENAI_TIMEOUT_MS`,
`AZURE_SPEECH_KEY`, `AZURE_SPEECH_REGION` (ex.: `brazilsouth`), `AZURE_SPEECH_VOICE` (padrão `pt-BR-AntonioNeural`), `AZURE_SPEECH_RATE` (padrão `-10%`), `AZURE_SPEECH_PITCH` (padrão `-3%`), `AZURE_SPEECH_BREAK_MS` (padrão `500`), `AZURE_SPEECH_TIMEOUT_MS`, `TTS_PROVIDER` (padrão `azure`; use `elevenlabs` para reversão),
`ELEVENLABS_API_KEY`, `ELEVENLABS_VOICE_ID`, `ELEVENLABS_TTS_MODEL`, `ELEVENLABS_TTS_SPEED`, `ELEVENLABS_TTS_TIMEOUT_MS`,
`LIMIAR_APP_SECRET`, `LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS`, `LIMIAR_AI_RATE_LIMIT_WINDOW_MS`,
`BLOB_READ_WRITE_TOKEN` (auto ao criar Blob Store), `META_CAPI_ACCESS_TOKEN`.
