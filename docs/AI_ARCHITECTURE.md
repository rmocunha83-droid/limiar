# Arquitetura de geração do Limiar

## Fluxo

1. O app iOS prepara candidatos de leitura conforme as preferências do usuário (catálogo local `Limiar/Resources/passages.json`, 977 trechos).
2. Para usuários no teste gratuito ativo, assinantes e Modo Essencial, o app chama o backend:
   - `POST /api/reading-session` — sessão diária adaptativa (1 a 3 leituras + reflexão), caminho principal;
   - `POST /api/spiritual-reading` e `POST /api/reflection` — caminhos legados, mantidos por compatibilidade;
   - `POST /api/speech` — narração, somente Premium, quando a pessoa toca em ouvir.
3. **A seleção das leituras é determinística e feita pelo servidor** (`selectSessionPassages`). A quantidade acompanha a profundidade escolhida: Curta = 1, Média = 2 e Mais profunda = 3. O seletor usa tiers livros favoritos → seções → pool completo, rotação LRU dos menos recentes, cotas proporcionais de prioridade e descoberta e garantia de tema favorito quando houver candidato permitido. Livros evitados nunca entram. A IA **não escolhe nem reescreve versículos** — só gera as explicações. Builds antigos sem `itemCount` preservam o caminho legado de 3 itens.
4. O backend gera texto com GPT-5.4 mini (`reasoning effort: none`) usando `OPENAI_API_KEY`, exige JSON estruturado (schema estrito) e valida o resultado; o app valida de novo.
5. Se a geração falhar por rede, backend, resposta inválida ou quantidade inesperada, o app monta imediatamente uma sessão local com os mesmos 1 a 3 trechos selecionados do catálogo. As explicações ficam vazias, mas a leitura continua concluível, entra no histórico e libera os apps normalmente. A tela preserva essa sessão enquanto tenta atualizá-la, uma única vez, no retorno ao primeiro plano ou por ação manual; nunca substitui a travessia depois que ela começou ou foi concluída. A tela de erro bloqueante só aparece se até o catálogo local estiver indisponível.
6. O app pré-gera a sessão em tempo morto (passo de ativação do onboarding e após concluir a travessia, para o ciclo seguinte) — a hora do turno escolhido abre sem espera; o padrão de migração é 5h.

Usuários com teste expirado e sem assinatura entram no **Modo Essencial**: continuam vendo a travessia no ritmo escolhido, com explicações essenciais **geradas pelo backend de texto (esse custo de IA existe e está no plano de negócio)**, mas sem narração, sem a reflexão breve completa (aparece só um teaser trancado) e com anúncios. Toques em recursos Premium abrem o paywall.

## Narração (TTS)

- **Provedor padrão: Azure Cognitive Services Speech**, voz `pt-BR-AntonioNeural`, tom devocional sereno (`rate=-10%`, `pitch=-3%` e pausa de `500ms` entre referência e texto), saída MP3 24kHz. ElevenLabs (`eleven_flash_v2_5`) permanece como alternativa: `TTS_PROVIDER=elevenlabs` reverte sem deploy.
- No caminho Azure, a voz e a velocidade enviadas pelo app são **ignoradas** — só as envs do servidor definem a voz efetiva (o app publicado ainda envia um voice ID do ElevenLabs; isso é esperado).
- A referência do trecho é proclamada no SSML (`"Mateus 11, 28-30"` vira `"Mateus 11, versículos 28 a 30"`) sem alterar a referência exibida, o texto canônico ou o hash do texto.
- **Cache no Vercel Blob**: cada áudio (provedor+modelo+voz+assinatura de tom+texto) é sintetizado uma vez; acertos respondem 302 para o Blob. A assinatura inclui rate, pitch, pausa e versão da fala da referência. Qualquer novo elemento SSML que mude o som precisa entrar nessa assinatura. Conexão via OIDC (`BLOB_STORE_ID`) ou token estático (`BLOB_READ_WRITE_TOKEN`).
- **Narração segmentada**: o app narra por segmentos — o versículo usa a string canônica `"{reference}.\n{text}"` (formato fixado por teste; mudou = cache pré-aquecido invalidado) e a explicação é um segmento separado, sintetizado ao vivo.
- **Prévia e pré-aquecimento**: `npm run tone:preview` gera seis MP3 locais para aprovação humana, sem escrever no Blob. Depois da aprovação e do deploy, `npm run prewarm:narration` narra o catálogo inteiro para a assinatura ativa (idempotente; rodar de novo quando catálogo, voz ou tom mudar). Ou seja, a narração dos versículos **é pré-gerada por design**; só as explicações são sintetizadas sob demanda.

## Segurança

- Chaves de provedores nunca ficam no app iOS (`OPENAI_API_KEY`, `ELEVENLABS_API_KEY`, `AZURE_SPEECH_KEY` só no Vercel).
- O app não envia seleção dos apps bloqueados, email, localização, contatos ou identificadores pessoais — apenas tradição, preferências, profundidade, trechos candidatos e histórico recente resumido.
- A telemetria da contingência registra apenas `ai_local_session_shown` (motivo técnico e quantidade) e `ai_local_session_upgraded` (gatilho e quantidade), sem PII nem perfil religioso.
- `LIMIAR_APP_SECRET` (opcional): quando setado no Vercel, os endpoints exigem o header `X-Limiar-App-Key` (injetado no build via xcconfig, nunca commitado — o repositório é público). Ativar somente quando a frota de builds antigos permitir.
- Todos os endpoints têm rate limit por cliente/janela; `api/meta-capi` (site) tem rate limit próprio por IP.

## Variáveis no Vercel

- `OPENAI_API_KEY` · `OPENAI_MODEL` (padrão `gpt-5.4-mini`) · `OPENAI_BASE_URL` · `OPENAI_REASONING_EFFORT` (padrão `none`) · `OPENAI_TIMEOUT_MS` (padrão `25000`).
- `TTS_PROVIDER` (padrão `azure`; `elevenlabs` para reversão).
- `AZURE_SPEECH_KEY` · `AZURE_SPEECH_REGION` (ex.: `brazilsouth`) · `AZURE_SPEECH_VOICE` (padrão `pt-BR-AntonioNeural`) · `AZURE_SPEECH_RATE` (padrão `-10%`) · `AZURE_SPEECH_PITCH` (padrão `-3%`) · `AZURE_SPEECH_BREAK_MS` (padrão `500`) · `AZURE_SPEECH_TIMEOUT_MS`.
- `ELEVENLABS_API_KEY` · `ELEVENLABS_TTS_MODEL` (padrão `eleven_flash_v2_5`) · `ELEVENLABS_VOICE_ID` · `ELEVENLABS_TTS_SPEED` (padrão `0.92`) · `ELEVENLABS_TTS_TIMEOUT_MS`.
- `BLOB_READ_WRITE_TOKEN` / `BLOB_STORE_ID` (cache de áudio; criado ao conectar o Blob Store).
- `LIMIAR_APP_SECRET` (opcional, ver Segurança).
- `LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS` (padrão `24`) · `LIMIAR_AI_RATE_LIMIT_WINDOW_MS` (padrão `900000`).
- `META_CAPI_ACCESS_TOKEN` (rastreamento do site).

## Testes

```bash
npm run test:ai-backend
```

Valida contrato JSON, quantidade adaptativa 1/2/3, seleção determinística (cota de prioridade, garantia de tema, compatibilidade com perfis antigos sem `priorityBooks` e `itemCount`), formato canônico da narração, chaves de cache do speech e limites de perfil. O target `LimiarTests` cobre a fábrica local, compatibilidade do snapshot diário e a política de atualização. Para QA no app, testar:

- geração remota com `OPENAI_API_KEY` configurada;
- modo avião: sessão local concluível, histórico/recente atualizados e apps liberados; reconexão antes e depois da conclusão;
- backend retornando erro, JSON inválido ou quantidade inesperada;
- profundidades curta, média e grande;
- retorno ao app depois da pausa; repetição reduzida com histórico recente;
- narração Premium: versículo (cache, início imediato) + explicação (ao vivo), pausa/retomada no meio da fila;
- Modo Essencial: leituras e explicações essenciais via backend, sem narração, teaser trancado da reflexão breve, anúncios, e todo toque em recurso Premium abrindo o paywall (inclusive salvar).
