# Limiar — Resumo de mudanças (handoff para o desenvolvedor)

Repositório: `rmocunha83-droid/limiar` · Branch principal: `main` (push em main = deploy automático do Vercel).
App iOS em `Limiar/` · Backend serverless em `api/` (Vercel, produção `https://applimiar.com.br`; o antigo `https://limiar-five.vercel.app` continua respondendo).

Este documento combina o histórico já entregue com mudanças ainda em validação. A seção 0 descreve o trabalho da branch adaptativa e ainda não está no `main` nem em produção. As demais seções registram entregas anteriores e devem ser conferidas contra o histórico do Git antes de qualquer publicação.

> **Mudanças de 24/07/2026 — leia antes de mexer nessas áreas:**
> - `docs/DOMINIO_APPLIMIAR_2026-07-24.md` — migração para o domínio próprio `applimiar.com.br` e o e-mail `contato@applimiar.com.br`. Inclui os quatro pontos do app iOS que **ainda apontam para o endereço antigo**.
> - `docs/META_TRACKING_2026-07-24.md` — SDK da Meta, ATT, SKAdNetwork, `api/meta-capi.js` e política de privacidade. Explica por que o envio de eventos deixou de depender da autorização do ATT.

---

## 0a. Portão de assinatura orientado a conversão — 22/08/2026 (branch `codex/paywall-conversao`)

Motivação: no Events Manager da Meta, ~200 `LimiarCheckoutStarted`/semana viravam ~46 `StartTrial`. O código confirmou a causa: o evento de checkout disparava a cada toque (sem dedupe), o portão não preparava a pessoa para a folha da App Store, e quem cancelava só via "Compra cancelada".

- **Portão redesenhado** (`SubscriptionGateView`): eyebrow "ÚLTIMO PASSO", título "Tudo pronto para sua primeira travessia.", destaque "Teste tudo por 7 dias, grátis." seguido de "Você não paga nada hoje.", linha do tempo Hoje / Dia 5 / Dia 7 com mais respiro, planos com mensal pré-selecionado ("Mais escolhido") e anual ancorado ("Equivale a R$ X/mês · Economize R$ Y"). O CTA em largura total e a linha "A Apple pede sua confirmação · R$ 0,00 hoje" agora fazem parte da rolagem, sem paginação nem barra fixa. A prova social de mais de 5 mil pessoas, benefícios e depoimentos vêm depois; Restaurar compras, Termos e Privacidade fecham a página.
- **Tela de recuperação** (`SubscriptionGateRecoveryView`, "SEM PRESSA / A porta continua aberta."): aparece quando `product.purchase()` devolve `.userCancelled` vindo do portão (`SubscriptionManager.showsGateRecovery`). Três verificações (nada foi cobrado, aviso no dia 5, cancelar em 2 toques), plano atual com link para o outro, CTA "Tentar de novo, grátis", "Já sou assinante" (restaurar) e "Ver todos os planos". Flag separada de `state` porque `refreshEntitlements()` sobrescreve `state`.
- **Lembrete do dia 5** (`LimiarNotificationCoordinator.syncTrialReminder`): notificação local 2 dias antes de `currentPeriodEndsAt` enquanto houver entitlement de teste introdutório; removida quando o teste deixa de existir. Só agenda com permissão concedida.
- **Meta:** `LimiarCheckoutStarted` passa a disparar uma vez por aparelho (mesma mecânica do StartTrial); novos eventos `LimiarCheckoutCancelled` (folha fechada) e `LimiarCheckoutFailed` (erro técnico), pensados para o público de remarketing "cancelou o checkout". `privacy.html` atualizado (raiz e `marketing/site`).
- **Firebase:** `gate_recovery_viewed`, `gate_recovery_retry{plan}`, `gate_recovery_dismissed`. Cada tentativa termina em exatamente um `purchase_attempt_result`, com `outcome` exclusivo (`success`, `pending`, `user_cancelled`, `product_unavailable`, `unverified` ou `error`). Os eventos especializados continuam em paralelo para leitura operacional: cancelamento gera `purchase_cancelled`, nunca `purchase_failed`; falha técnica gera `purchase_failed` com `error_code` de baixa cardinalidade.
- **Háptico:** `LimiarHaptics` centraliza três sinais preparados e reutilizados: `tap()` nos CTAs primários e no ajuste Aa, `select()` apenas em escolhas realmente alteradas pelo usuário (tradição, tema, categoria, profundidade, turno e plano) e `complete()` uma única vez ao concluir a travessia. Regra de produto: é respiração, não recompensa; não há vibração durante leitura, narração, rolagem, erros/cancelamentos, links secundários, Essencial/AdMob ou extensões. **Decisão:** liberar os apps após a pausa não recebe outro háptico — a conclusão já é o único momento cheio e a liberação permanece como o próprio prêmio.
- **Tipografia do onboarding:** textos de corpo passam a 17 pt e apoios a 15 pt, com piso de 14 pt nos contadores, explicações compactas e nomes de depoimentos. Chips, subtítulos de seleção e depoimentos foram ampliados sem alterar eyebrow, títulos serifados, títulos de cartão ou botões. Os apoios em `softText` deixam de usar opacidade `0.86`; o onboarding preserva o teto de Dynamic Type em `.large`. Paywall e superfície de leitura permanecem fora desta revisão.
- **QA:** `-LimiarForceSubscriptionGate -LimiarGateTrialEligible` abre o portão; `-LimiarForceGateRecovery` abre a recuperação (DEBUG). Sem arquivo `.storekit` no projeto, o simulador mostra "Carregando oferta" nos preços — validar preços em TestFlight.
- Ver no Meta após publicar: total semanal de `StartTrial` no Events Manager (meta: sair de ~46 para 60+) e usuários únicos de `LimiarCheckoutCancelled` versus `LimiarCheckoutStarted`. Para taxa por tentativa, use os desfechos terminais do Firebase; `CheckoutStarted` é deduplicado por aparelho e não serve como denominador bruto de tentativas repetidas.

---

## 0. Travessia adaptada ao ritmo escolhido — EM VALIDAÇÃO

- A profundidade agora determina também a quantidade: **Curta = 1 leitura, Média = 2 e Mais profunda = 3**.
- O app envia `itemCount` ao backend; requisições de builds antigos sem esse campo continuam recebendo 3 itens e o comportamento legado.
- Cache diário, chave de perfil e chave da requisição remota incluem a quantidade, evitando reaproveitar uma sessão feita para outro ritmo.
- O onboarding exige no mínimo 2 estilos. Católica e evangélica abrem com 3 categorias representativas; judaica e espírita abrem com pelo menos 2. Ao ficar exatamente em 2, uma dica suave incentiva variedade sem bloquear. Perfis legados com 1 categoria continuam funcionando normalmente e precisam chegar ao mínimo apenas ao editar a seleção.
- Site, metadados e cards da App Store deixam de prometer uma quantidade fixa. O card antigo com referência a IA passa a usar `Leitura com propósito` e copy centrada na travessia.
- **A App Store fica bloqueada até uma semana de validação humana no TestFlight.** Pergunta recomendada aos testadores: `A travessia está do tamanho certo para fazer todo dia?`

---

## 1. Backend / geração de leituras (histórico já entregue)

**Arquitetura da geração** (`api/_limiar-ai.js`, `api/reading-session.js`, `spiritual-reading.js`, `reflection.js`):
- O **servidor seleciona os trechos de forma determinística** (`selectSessionPassages`). `favoriteBooks` aceita até 40 livros e permanece como a união das categorias. `priorityBooks` é opcional e equilibra afinamento e descoberta conforme a quantidade pedida. Se houver tema favorito, o servidor garante um trecho fresco desse tema quando houver candidato permitido. A IA **não escolhe mais** os versículos.
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
- **Próximo ciclo:** após concluir a travessia, pré-gera a sessão do **próximo ciclo** e persiste pela chave ancorada na hora do turno escolhido (padrão 5h). O app abre instantaneamente mesmo em cold start.
- Fallback: se as preferências mudarem ou a pré-geração falhar, cai no fluxo ao vivo normal.

---

## 5. Shield matinal (Screen Time) — confiabilidade

- **Entitlement Family Controls adicionado às 3 extensões** (DeviceActivityMonitor, ShieldAction, ShieldConfiguration) — era a causa raiz de o shield não rearmar no início do ciclo. **Já aprovado pela Apple** (build 80 aprovada na App Store com isso).
- `ScreenTimeController` / `DeviceActivityMonitorExtension`: timezone do dispositivo (era São Paulo fixo), cálculo do ciclo na hora do turno escolhido robusto a horário de verão, botão do shield com copy correta pré-iOS 26.5.
- **Observabilidade:** `LimiarEventLog` (App Group) grava eventos do app e da extensão; tela **Configurações → Sobre → Diagnóstico técnico** mostra os eventos (`monitor.interval_did_start` na hora escolhida = extensão viva; `monitor.shield_reapplied` = rearmado). `os.Logger` no lugar dos `debugPrint`.
- Fix de cold start: `init()` não limpa mais o shield antes do StoreKit restaurar a assinatura (`SubscriptionManager` cacheia o entitlement no App Group).

## 5b. Release 1.3 · build 110 — correções antes do envio

- **Preço sem ambiguidade:** o plano anual destaca o valor integral localizado pelo StoreKit com `/ano`, informa que a cobrança ocorre uma vez por ano e mantém o equivalente diário como apoio. O mensal usa `/mês`, e a renovação também explicita o período. Esta correção é bloqueadora para o envio à App Store.
- **Modo Essencial / AdMob:** o banner adaptativo agora recebe somente a largura real do container, sem realimentar o layout com o próprio `bounds`. A altura vem do `adSize`, é reservada antes do carregamento e o anúncio não é mais recortado. Validado em iPhone SE e Pro Max sem conteúdo deslocado ou texto cortado.
- **Início dos 7 dias:** a tela virou uma boas-vindas sem preços, cartão ou pressão antecipada. O botão continua chamando o mesmo `startFreeTrial()` e deixa claro que nenhuma assinatura começa nessa etapa.
- **Legibilidade:** FreeTrial, D6, D7 e D8 usam uma única régua escalável com Dynamic Type limitado a `xxLarge`; textos essenciais partem de 14pt, depoimentos usam 16pt e o carrossel cresce para não truncar.
- **Narração:** referências somente com capítulo, como `Salmo 23`, recebem a pausa devocional correta; `break=0` preserva separação. Pausar durante a emenda de 600ms segura a fila e a retomada continua no próximo segmento.
- **Cache da narração:** a correção da pausa adiciona `chapter-break-fix:v1` somente à chave de referências só de capítulo. Assim os quatro MP3 afetados são regenerados sob demanda sem reaquecer nem invalidar os outros 973 trechos.
- **Acabamentos:** remoção de foto exige confirmação e o processamento de fotos grandes ocorre fora da MainActor; narração bloqueada ganha cadeado no Essencial; código morto de favoritos foi removido e a busca do catálogo passou a usar índices em memória.
- **Validação:** screenshots ficam em `docs/screenshots/`; testes do backend e build iOS devem estar verdes antes de criar a build no Xcode Cloud.

## 5c. Turno da pausa diária — build 114

- O usuário escolhe **Manhã (5h)**, **Tarde (13h)** ou **Noite (19h)** no novo passo do onboarding e pode alterar depois em Configurações.
- A preferência `cycleStartHour` fica no App Group `group.com.romeucunha.Limiar`, acessível ao app e à extensão de `DeviceActivity`. Perfis existentes ou sem a chave continuam em **Manhã/5h**.
- Uma troca de turno é futura: a seleção é salva imediatamente, mas o corte efetivo só ocorre no próximo ciclo. O shield corrente e uma travessia já concluída não são reabertos.
- `currentCycleStart`, a chave da sessão diária, a pré-geração e o monitor usam a mesma hora efetiva. No turno da noite, 23h e 1h pertencem ao mesmo ciclo; a chave só vira às 19h seguintes.
- Não existe hoje um lembrete diário independente no app; portanto não há outro agendamento de notificação a sincronizar.
- Copy ajustada: “Sua travessia de cada manhã, sempre gratuita” → “Sua travessia diária, sempre gratuita”; “disponíveis até a próxima manhã” → “disponíveis até o próximo ciclo”; os horários de retorno da pausa agora derivam do turno escolhido.

## 5d. Retry do banner ancorado — build 114

- O banner ancorado do Modo Essencial tenta novamente após **30s**, depois **60s** e, persistindo a falha, a cada **120s** enquanto o dashboard estiver visível.
- Os timers são cancelados ao sair da tela e nunca rodam depois de um anúncio carregado; atualização de anúncio ativo continua sob responsabilidade exclusiva do auto-refresh do AdMob.
- O MREC preserva o comportamento anterior: uma única nova tentativa suave após 4s.
- `admob_banner_failed` e `admob_banner_loaded` registram `position` e número da tentativa; falhas também registram o próximo intervalo previsto.

## 5e. Estado dos blocos no AdMob — 16/07/2026

- O app **Limiar Gratuito | iOS** já estava vinculado à App Store pelo ID **6783115468**, com status pronto e veiculação habilitada. Nenhum vínculo foi forçado ou recriado.
- **Banner ancorado (Essencial)** — `ca-app-pub-7717198050770102/7996436288`: atualização automática já estava em **Otimizado pelo Google**. A configuração foi conferida e mantida, sem salvar alteração.
- **Retângulo final (Essencial)** — `ca-app-pub-7717198050770102/2565100496`: atualização automática observada em **Otimizado pelo Google**. O estado foi apenas registrado; nenhuma configuração do MREC foi modificada.
- O bloco antigo `ca-app-pub-7717198050770102/8580637095` continua existente no painel e não foi apagado. Ele não é mais usado no código e só deve ser arquivado depois da validação em produção.
- Não houve mudança em pagamentos, verificação, consentimento/GDPR, mediação, configurações do app ou exclusões.

## 5f. Ponte do Shield para o Limiar — build 120

- **Resultado real que ativou a contingência:** no iPhone 16 conectado, com **iOS 27.0** e Limiar comercial **1.4 (117)**, tocar em “Fazer a travessia” fechou o Instagram e voltou à tela inicial. Portanto, `.openParentalControlsApp` não abriu o app mesmo acima do iOS 26.5 no cenário de autorização individual.
- **Comportamento final em todas as versões (iOS 17+):** o Shield mostra o título “Seu acesso está em pausa”, orienta “Abra o app Limiar para fazer sua travessia e liberar seus apps.” e usa o botão **“Entendi”**. A copy continua válida mesmo sem permissão de notificações.
- Ao tocar no botão, a `ShieldActionExtension` verifica a permissão. Quando autorizada ou provisória, agenda em 1 segundo uma única notificação `shield.bridge` — “Sua travessia está pronta” — e fecha o app bloqueado apenas no completion do agendamento. O identificador fixo remove pedidos/entregas anteriores e impede empilhamento. Sem permissão, apenas fecha; a orientação manual do Shield permanece correta.
- O onboarding ganhou um pré-prompt explícito antes do prompt do sistema: **“Um atalho para sua travessia”**, com “Ativar” e “Agora não”. O sistema só recebe `requestAuthorization(.alert, .sound, .badge)` após “Ativar” e uma negativa não é repetida.
- Configurações mostra o estado real da permissão. Quando negada, oferece **“Abrir Ajustes do iOS”**; quando ainda não determinada, reutiliza o mesmo pré-prompt. Esta é a única permissão de notificações e será compartilhada com o futuro lembrete diário.
- O delegate é instalado no `UIApplicationDelegate` antes do fim do lançamento. O toque em uma notificação com `source=shield_bridge` entra diretamente no dashboard, acima dos gates automáticos do funil, limpa badge/pedido entregue e não mostra banner redundante se o app já estiver em primeiro plano.
- **QA real disponível:** o caminho nativo iOS 26.5+ foi reprovado no iPhone 16/iOS 27.0/build 117 e substituído pela contingência. A build 120 foi instalada nesse mesmo aparelho e o Shield real exibiu corretamente a nova copy autossuficiente e o botão “Entendi”, confirmando o empacotamento das extensões. A entrega e o toque da notificação ainda precisam ser exercitados no aparelho com a permissão autorizada. Não havia aparelho físico abaixo do iOS 26.5 disponível; essa faixa permanece sem validação real. Family Controls não pode ser validado no simulador.
- **QA em simulador (iOS 26.5):** Configurações exibiu o estado “Ainda não configuradas” e o botão “Ativar notificações”; o toque abriu o pré-prompt com a copy e as ações previstas. Esse teste valida UI/estado, não o Shield, que exige aparelho real.

## 5g. Pré-geração resiliente e Shield híbrido — build 121

- **Foreground como gatilho principal:** a cada entrada em primeiro plano, o app verifica uma única vez se a sessão do próximo ciclo já existe. Se estiver ausente, inicia a mesma pré-geração idempotente já usada no onboarding e na conclusão. A tentativa é silenciosa e é pulada durante uma travessia em andamento.
- **BGAppRefresh como reforço oportunista:** o app registra `com.romeucunha.Limiar.prewarm`, com Background fetch habilitado, e pede execução aproximadamente 45 minutos antes do próximo ciclo ao entrar em background e após concluir a leitura. O iOS não garante horário nem execução; por isso o foreground continua sendo a proteção principal e a geração ao vivo continua sendo o fallback.
- Quando o sistema entrega a BG task depois da virada, ela prioriza a sessão corrente ausente; caso a atual já exista, prepara a próxima. A expiração cancela a geração com segurança, não muda a UI e a tarefa sempre é reagendada ao terminar.
- Os três gatilhos compartilham a mesma trava em memória e a mesma consulta ao `DailyReadingSessionStore`, evitando sessão duplicada. Os eventos `prewarm_foreground_started`, `prewarm_foreground_skipped`, `prewarm_bg_scheduled` e `prewarm_bg_run` registram apenas resultado/motivo técnico, sem PII.
- **QA de BG task em aparelho:** usar no LLDB `e -l objc -- [[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.romeucunha.Limiar.prewarm"]` e conferir `prewarm_bg_run` no Diagnóstico técnico. Os cenários de conclusão normal e de abertura noturna sem concluir também devem ser verificados no ciclo seguinte.
- **Shield:** o botão agora diz **“Fechar”**. A notificação `shield.bridge` continua sendo agendada primeiro e permanece como rede de segurança. Somente no completion do agendamento, o Shield responde com `.openParentalControlsApp` no iOS 26.5+ e com `.close` nas versões anteriores. Sem permissão de notificação, a tentativa direta ainda ocorre no iOS 26.5+.
- Se a abertura direta funcionar, a ativação do app remove pedidos pendentes e notificações entregues da ponte; `willPresent` continua suprimindo seu banner no primeiro plano. A copy só deve voltar a **“Fazer a travessia”** depois de uma versão estável do iOS comprovar a abertura direta em teste manual com autorização individual.
- **QA disponível nesta entrega:** o projeto e as três extensões compilam no simulador com o SDK iOS 26.5. Family Controls, execução real de BGAppRefresh e o resultado de `.openParentalControlsApp` não podem ser validados no simulador. Permanecem pendentes no iPhone 16/iOS 27: botão “Fechar”, permissão concedida/negada, toque repetido sem empilhamento e registro do comportamento da tentativa direta.

## 5h. Sessão local de contingência — build 132

- Falhas de rede, backend, payload inválido ou `unexpected_item_count` não deixam mais a travessia vazia. O app usa o recomendador existente e monta 1, 2 ou 3 leituras com o catálogo empacotado, sem explicações inventadas.
- A sessão local é persistida com `source=local`, permanece concluível e reutiliza o fluxo existente de histórico, recentes e liberação do Screen Time. O Modo Essencial e o Premium recebem a mesma proteção; a narração mantém as regras atuais e a avaliação da App Store não é solicitada após uma sessão degradada.
- Antes do início ou da conclusão da travessia, o retorno ao primeiro plano e o botão `Tentar novamente` podem trocar a sessão local por uma resposta remota válida. A leitura local nunca é apagada durante a tentativa e não é substituída depois da conclusão.
- Diagnóstico sem PII: `ai_local_session_shown` registra apenas motivo técnico/quantidade; `ai_local_session_upgraded`, gatilho/quantidade. O prewarm do próximo ciclo continua independente.
- Cobertura automática no target `LimiarTests`: quantidade e campos vazios da fábrica local, migração de snapshots antigos e política de atualização. Para QA visual em Debug, usar `-LimiarForceLocalSession`; combinar com `-LimiarForceEssential` para o Modo Essencial.
- **QA ainda obrigatório em iPhone físico:** concluir em modo avião, confirmar histórico/recentes e liberação dos apps; reconectar antes do início e depois da conclusão; repetir no Modo Essencial. Family Controls não é validável no simulador.

## 5i. Tela de conclusão por turno — build 146

- Após “Despausar apps”, a confirmação agora diz **“Travessia concluída”** e deixa explícito que a pessoa pode fechar o Limiar e seguir o dia. A ação **“Permanecer no Limiar”** continua com o mesmo comportamento.
- O ícone acompanha o turno configurado: nascer do sol pela manhã, sol pleno à tarde e lua à noite. Um selo verde-sálvia com check confirma visualmente a conclusão.
- A referência do próximo ciclo usa a data real calculada pelo mesmo `nextCycleStart` do agendamento: **“hoje às …”** quando o ciclo seguinte começa no mesmo dia e **“amanhã às …”** quando começa no dia seguinte. Isso cobre corretamente o turno noturno concluído depois da meia-noite.
- QA visual em Debug: `-LimiarForceCompletionScreen -LimiarCompletionTurn morning|afternoon|evening -LimiarCompletionTiming today|tomorrow`. Esses argumentos alteram somente a apresentação de teste.
- Evidências visuais: [`morning-tomorrow.jpg`](qa/completion-build-142/morning-tomorrow.jpg), [`afternoon-tomorrow.jpg`](qa/completion-build-142/afternoon-tomorrow.jpg), [`evening-tomorrow.jpg`](qa/completion-build-142/evening-tomorrow.jpg) e [`evening-today.jpg`](qa/completion-build-142/evening-today.jpg).

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
