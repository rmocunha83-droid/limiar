# Arquitetura de geração do Limiar

## Fluxo

1. O app iOS prepara candidatos de leitura conforme as preferências do usuário (catálogo local `Limiar/Resources/passages.json`, 1.800 trechos). A expansão adiciona 823 entradas de fonte BLIVRE identificada, mantendo as 977 anteriores intactas. O catálogo continua empacotado e disponível sem rede; o ZIP de origem e a curadoria ficam apenas nas ferramentas de desenvolvimento. Consulte `scripts/catalog-sources/README.md` para licença e reprodução.
2. Para usuários no teste gratuito ativo, assinantes e Modo Essencial, o app chama o backend:
   - `POST /api/reading-session` — sessão diária adaptativa (1 a 3 leituras + reflexão), caminho principal;
   - `POST /api/spiritual-reading` e `POST /api/reflection` — caminhos legados, mantidos por compatibilidade;
   - `POST /api/speech` — narração, somente Premium, quando a pessoa toca em ouvir.
3. **A seleção das novas builds é feita no app** (`PassageRecommendationService`), usando o histórico persistente completo: inéditos dos temas escolhidos → inéditos de outros temas → apresentados há mais tempo. Apenas os temas podem expandir; tradição, livros e seções continuam restringindo o catálogo, sem alterar o perfil salvo. Livros refinados e variedade temática desempatam candidatos sem superar essa ordem. A quantidade acompanha a profundidade: Curta = 1, Média = 2 e Mais profunda = 3, limitada aos trechos elegíveis disponíveis. O app envia somente a seleção final ao servidor, que preserva essa ordem na geração dos cards e da reflexão conjunta. O app valida IDs, referências, texto canônico, quantidade e ordem; uma resposta divergente aciona a sessão local. A IA **não escolhe nem reescreve versículos** — só gera as explicações. O seletor legado do servidor permanece compatível com builds antigas que enviam pools de candidatos.
4. O backend gera texto com GPT-5.4 mini (`reasoning effort: none`) usando `OPENAI_API_KEY`, exige JSON estruturado (schema estrito) e valida o resultado; o app valida de novo.
5. Se a geração falhar por rede, backend, resposta inválida ou quantidade inesperada, o app monta imediatamente uma sessão local com os mesmos 1 a 3 trechos selecionados do catálogo. As explicações ficam vazias, mas a leitura continua concluível, entra no histórico e libera os apps normalmente. A atualização após reconexão explica esses mesmos trechos, sem consumir outra seleção. O registro persistente de apresentação é atualizado quando a sessão é aplicada para exibição, não durante a pré-geração. Ele não é mais cortado em 60 entradas e incorpora as conclusões antigas ainda disponíveis; registros já descartados não podem ser reconstruídos. A sessão diária em cache permanece estável ao reabrir. A tela de erro bloqueante só aparece se não houver sessão local elegível.
   Caches anteriores com dois ou três trechos preservam os versículos e as homilias individuais; a reflexão conjunta potencialmente fora de ordem é ocultada até a atualização remota desses mesmos trechos. Uma pré-geração tardia não substitui uma sessão já salva para o dia e o perfil.
6. O app pré-gera a sessão em tempo morto (passo de ativação do onboarding e após concluir a travessia, para o ciclo seguinte) — a hora do turno escolhido abre sem espera; o padrão de migração é 5h.

Usuários com teste expirado e sem assinatura entram no **Modo Essencial**: continuam vendo a travessia no ritmo escolhido, com explicações essenciais **geradas pelo backend de texto (esse custo de IA existe e está no plano de negócio)**, mas sem narração, sem a reflexão breve completa (aparece só um teaser trancado) e com anúncios. Toques em recursos Premium abrem o paywall.

## Qualidade e compatibilidade

- O diagnóstico local agrega solicitações, falhas, sessões locais exibidas e P95 de duração dentro do buffer de 200 eventos. Não representa a base inteira de usuários. Logs de IA são filtrados por campos permitidos; preferências, referências, prompts, histórico e identificadores pessoais não entram. Registros de IA antigos também são filtrados ao consultar/copiar o diagnóstico.
- O backend emite `limiar_reading_delivery` com resultado, quantidade, duração e status HTTP, sem conteúdo religioso. Esses eventos permitem agregação operacional após publicação; não há alerta remoto ou rotina agendada criada por esta mudança.
- Feedback é reversível e fica somente no aparelho (`readingFeedback.v1`). Não altera onboarding, sessão em andamento, permissões, conclusão ou cache pré-gerado. Preferências positivas orientam desempates temáticos nas próximas gerações, sem superar temas escolhidos, livros refinados ou LRU. Pedir outros trechos não faz chamada adicional e não elimina conteúdo elegível permanentemente.
- `explanationDiversityVersion: 1` ativa instruções adicionais de variedade no backend, usando aberturas e aplicações recentes limitadas a três amostras de 180 caracteres por sessão e oito sessões por requisição. Ausência do campo mantém o prompt legado. Há uma única chamada ao provedor, sem retry extra por estilo. A variedade é uma orientação de geração, não garantia de unicidade textual.
- Favoritos novos guardam explicação, aplicação e pergunta, quando disponíveis. Os campos são opcionais: favoritos antigos continuam legíveis, sem inventar explicações que não foram salvas. Busca e releitura são locais e não tocam no histórico de apresentação nem geram IA. As regras atuais de acesso aos favoritos permanecem.
- Publicação não é automática. Validar primeiro em ambiente de testes com builds antigas e novas, preservar o backend compatível e o fallback, e só liberar uma atualização após aprovação. A parte de diversidade do backend exige seu futuro deploy; uma build nova continua funcionando com o backend anterior, que ignora os campos adicionais.

## Narração (TTS)

- **Provedor padrão: Azure Cognitive Services Speech**, voz `pt-BR-AntonioNeural`, tom devocional sereno (`rate=-10%`, `pitch=-3%` e pausa de `500ms` entre referência e texto), saída MP3 24kHz. ElevenLabs (`eleven_flash_v2_5`) permanece como alternativa: `TTS_PROVIDER=elevenlabs` reverte sem deploy.
- No caminho Azure, o cliente pode escolher entre as vozes pt-BR autorizadas; valores antigos do ElevenLabs usam a voz configurada no servidor. Velocidade e tom continuam definidos no servidor.
- A referência do trecho é proclamada no SSML (`"Mateus 11, 28-30"` vira `"Mateus 11, versículos 28 a 30"`) sem alterar a referência exibida, o texto canônico ou o hash do texto.
- **Cache no Vercel Blob**: cada áudio (provedor+modelo+voz+assinatura de tom+texto) é sintetizado uma vez; acertos respondem 302 para o Blob. A assinatura inclui rate, pitch, pausa e versão da fala da referência. Qualquer novo elemento SSML que mude o som precisa entrar nessa assinatura. Conexão via OIDC (`BLOB_STORE_ID`) ou token estático (`BLOB_READ_WRITE_TOKEN`).
- **Narração segmentada**: o app narra por segmentos — o versículo usa a string canônica `"{reference}.\n{text}"` (formato fixado por teste; mudou = cache pré-aquecido invalidado) e cada parágrafo da explicação vira um segmento separado, sintetizado ao vivo e pré-carregado durante o segmento anterior.
- **Crédito BLIVRE na narração**: o sufixo ` · BLIVRE` permanece na referência exibida e no texto canônico enviado pelo app. Somente a preparação da fala remove esse sufixo, reconhece os versículos e insere a pausa configurada. A assinatura ganha `blivre-reference:v1` apenas nesses casos, evitando reutilizar eventual áudio que tenha lido o crédito; os 977 áudios legados preservam entrada, SSML e assinatura. Nenhuma mudança de voz, velocidade ou tom.
- **Lote de expansão**: em ambiente com credenciais Azure/Blob disponíveis, executar `npm run prewarm:narration -- --new-only --check-only` para verificar faltantes, depois `npm run prewarm:narration -- --new-only` para gerar e repetir a consulta para confirmar `missing: 0`. O lote deduplica textos iguais entre tradições e consulta o cache antes de sintetizar. Erros de autenticação/consulta de cache interrompem o lote; não são tratados como áudios inexistentes. Credenciais de produção marcadas como Secret na Vercel não são exportadas pelo CLI: esse caso requer execução no ambiente com acesso aos segredos. Não colocar chaves no repositório nem no app. Publicar a correção do backend antes de liberar o novo catálogo no iOS.
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
