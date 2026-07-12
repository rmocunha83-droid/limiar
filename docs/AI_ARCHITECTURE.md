# Arquitetura de geração do Limiar

## Fluxo

1. O app iOS prepara candidatos de leitura conforme as preferências do usuário (catálogo local `Limiar/Resources/passages.json`, 977 trechos).
2. Para usuários no teste gratuito ativo, assinantes e Modo Essencial, o app chama o backend:
   - `POST /api/reading-session` — sessão diária completa (3 trechos + reflexão), caminho principal;
   - `POST /api/spiritual-reading` e `POST /api/reflection` — caminhos legados, mantidos por compatibilidade;
   - `POST /api/speech` — narração, somente Premium, quando a pessoa toca em ouvir.
3. **A seleção dos 3 trechos é determinística e feita pelo servidor** (`selectSessionPassages`): tiers livros favoritos → seções → pool completo, rotação LRU dos menos recentes, cota de prioridade (até 2 trechos dos `priorityBooks` afinados + 1 de descoberta) e garantia de tema favorito (mínimo 1 trecho por sessão, apenas para perfis que enviam `priorityBooks`, sem sair dos livros escolhidos). Livros evitados nunca entram. A IA **não escolhe nem reescreve versículos** — só gera as explicações.
4. O backend gera texto com GPT-5.4 mini (`reasoning effort: none`) usando `OPENAI_API_KEY`, exige JSON estruturado (schema estrito) e valida o resultado; o app valida de novo.
5. Se qualquer etapa falhar, o app usa o fallback local e mostra mensagem simples, sem expor erro técnico.
6. O app pré-gera a sessão em tempo morto (passo de ativação do onboarding e após concluir a travessia, para o ciclo seguinte) — a manhã abre sem espera.

Usuários com teste expirado e sem assinatura entram no **Modo Essencial**: continuam vendo 3 trechos com explicações essenciais **gerados pelo backend de texto (esse custo de IA existe e está no plano de negócio)**, mas sem narração, sem a reflexão breve completa (aparece só um teaser trancado) e com anúncios. Toques em recursos Premium abrem o paywall.

## Narração (TTS)

- **Provedor padrão: Azure Cognitive Services Speech**, voz `pt-BR-AntonioNeural`, cadência `-8%`, saída MP3 24kHz. ElevenLabs (`eleven_flash_v2_5`) permanece como alternativa: `TTS_PROVIDER=elevenlabs` reverte sem deploy.
- No caminho Azure, a voz e a velocidade enviadas pelo app são **ignoradas** — só as envs do servidor definem a voz efetiva (o app publicado ainda envia um voice ID do ElevenLabs; isso é esperado).
- **Cache no Vercel Blob**: cada áudio (provedor+modelo+voz+cadência+texto) é sintetizado uma vez; acertos respondem 302 para o Blob. Conexão via OIDC (`BLOB_STORE_ID`) ou token estático (`BLOB_READ_WRITE_TOKEN`).
- **Narração segmentada**: o app narra por segmentos — o versículo usa a string canônica `"{reference}.\n{text}"` (formato fixado por teste; mudou = cache pré-aquecido invalidado) e a explicação é um segmento separado, sintetizado ao vivo.
- **Pré-aquecimento**: `npm run prewarm:narration` narra o catálogo inteiro uma única vez para o Blob (idempotente; rodar de novo quando o catálogo crescer ou a voz mudar). Ou seja, a narração dos versículos **é pré-gerada por design**; só as explicações são sintetizadas sob demanda.

## Segurança

- Chaves de provedores nunca ficam no app iOS (`OPENAI_API_KEY`, `ELEVENLABS_API_KEY`, `AZURE_SPEECH_KEY` só no Vercel).
- O app não envia seleção dos apps bloqueados, email, localização, contatos ou identificadores pessoais — apenas tradição, preferências, profundidade, trechos candidatos e histórico recente resumido.
- `LIMIAR_APP_SECRET` (opcional): quando setado no Vercel, os endpoints exigem o header `X-Limiar-App-Key` (injetado no build via xcconfig, nunca commitado — o repositório é público). Ativar somente quando a frota de builds antigos permitir.
- Todos os endpoints têm rate limit por cliente/janela; `api/meta-capi` (site) tem rate limit próprio por IP.

## Variáveis no Vercel

- `OPENAI_API_KEY` · `OPENAI_MODEL` (padrão `gpt-5.4-mini`) · `OPENAI_BASE_URL` · `OPENAI_REASONING_EFFORT` (padrão `none`) · `OPENAI_TIMEOUT_MS` (padrão `25000`).
- `TTS_PROVIDER` (padrão `azure`; `elevenlabs` para reversão).
- `AZURE_SPEECH_KEY` · `AZURE_SPEECH_REGION` (ex.: `brazilsouth`) · `AZURE_SPEECH_VOICE` (padrão `pt-BR-AntonioNeural`) · `AZURE_SPEECH_TIMEOUT_MS`.
- `ELEVENLABS_API_KEY` · `ELEVENLABS_TTS_MODEL` (padrão `eleven_flash_v2_5`) · `ELEVENLABS_VOICE_ID` · `ELEVENLABS_TTS_SPEED` (padrão `0.92`) · `ELEVENLABS_TTS_TIMEOUT_MS`.
- `BLOB_READ_WRITE_TOKEN` / `BLOB_STORE_ID` (cache de áudio; criado ao conectar o Blob Store).
- `LIMIAR_APP_SECRET` (opcional, ver Segurança).
- `LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS` (padrão `24`) · `LIMIAR_AI_RATE_LIMIT_WINDOW_MS` (padrão `900000`).
- `META_CAPI_ACCESS_TOKEN` (rastreamento do site).

## Testes

```bash
npm run test:ai-backend
```

Valida contrato JSON, seleção determinística (cota de prioridade, garantia de tema, compatibilidade com perfis antigos sem `priorityBooks`), formato canônico da narração, chaves de cache do speech e limites de perfil. Para QA no app, testar:

- geração remota com `OPENAI_API_KEY` configurada;
- mensagem simples sem internet; backend retornando erro; JSON inválido;
- profundidades curta, média e grande;
- retorno ao app depois da pausa; repetição reduzida com histórico recente;
- narração Premium: versículo (cache, início imediato) + explicação (ao vivo), pausa/retomada no meio da fila;
- Modo Essencial: leituras e explicações essenciais via backend, sem narração, teaser trancado da reflexão breve, anúncios, e todo toque em recurso Premium abrindo o paywall (inclusive salvar).
