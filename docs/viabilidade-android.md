# Limiar Android — Estudo de viabilidade (para orçamento com desenvolvedor Android)

Documento de planejamento. Objetivo: descrever o que é reaproveitável do app iOS, o que precisa ser
refeito, e onde estão o esforço e o risco reais — para pedir estimativa a um desenvolvedor Android
com precisão.

**Resumo em uma frase:** a inteligência do Limiar (backend + conteúdo) é ~100% reaproveitável; a
"mágica" do bloqueio matinal de apps precisa ser reconstruída de forma nativa e diferente no Android —
é aí que vivem ~80% do esforço e praticamente todo o risco.

---

## 1. O que reaproveita quase de graça

| Item | Situação |
|---|---|
| **Backend (Vercel)** | Nenhuma mudança. O app Android chama os mesmos endpoints: `POST /api/reading-session`, `POST /api/speech` (TTS), etc. Geração de leituras, seleção determinística dos trechos, IA — tudo compartilhado. |
| **Catálogo de 977 trechos** (`passages.json`) | É só um JSON. Serve os dois apps. (Reforça o valor da Fase 2 — catálogo remoto: um só lugar para iOS + Android.) |
| **Regras de negócio** | Categorias por tradição, temas, profundidade, anti-repetição, chaves de sessão diária. A lógica é portável; muda só a linguagem (Swift → Kotlin). |

**Implicação:** ~60% do produto (o "cérebro") já está pronto para servir Android. É o que mais desrisca o projeto.

---

## 2. O que precisa ser reescrito — trabalho padrão, sem surpresa

- **Toda a UI** em Kotlin + Jetpack Compose: onboarding (tradição → estilos de leitura → temas →
  profundidade → ativação), tela da travessia (1 a 3 leituras + explicação + "ouvir"), configurações,
  histórico, favoritos.
- **Assinatura**: StoreKit → **Google Play Billing** (produto de assinatura equivalente).
- **Reprodução de áudio** do ElevenLabs (vem do mesmo endpoint `/api/speech`).
- **AdMob** (SDK Android para o modo essencial com anúncio).
- **Notificações**, deep links, telemetria.

Nada aqui é difícil — é volume de app normal.

---

## 3. O ponto duro — o bloqueio de apps (o coração do produto)

O shield do iOS usa três frameworks da Apple (**FamilyControls, DeviceActivity, ManagedSettings**) que
**não têm equivalente oficial no Android**. O Android não oferece a um app de terceiros uma API de
sistema para bloquear outros apps com uma "tela por cima".

### Como se faz no Android (abordagem dos concorrentes: Opal, Freedom, AppBlock)

1. **Detectar** quando um app bloqueado vai para o primeiro plano — via **AccessibilityService** (mais
   confiável) ou polling de `UsageStatsManager`.
2. **Cobrir** com uma janela de **overlay** em tela cheia (`SYSTEM_ALERT_WINDOW` — "desenhar sobre
   outros apps"), que renderiza a tela da travessia do Limiar.
3. **Agendar** o ciclo das 5h com `WorkManager`/`AlarmManager` para (re)armar o bloqueio de manhã.

### Permissões que o usuário precisa conceder (fricção no onboarding)
- Acesso ao **Serviço de Acessibilidade** (tela de sistema, assustadora para o usuário leigo).
- **Desenhar sobre outros apps** (overlay).
- **Acesso a dados de uso** (`PACKAGE_USAGE_STATS`).
- Provavelmente **ignorar otimização de bateria** (para o serviço sobreviver).

### Riscos reais (precisam entrar na conversa de orçamento)
1. **Política do Google Play.** O Google restringe fortemente o uso da Accessibility API para fins que
   não sejam acessibilidade. Apps de bloqueio/bem-estar digital operam numa zona cinzenta e passam por
   revisão criteriosa — há risco concreto de reprovação/remoção. Precisa de justificativa clara no
   formulário de declaração de permissões.
2. **Fragmentação de fabricante.** Xiaomi, Samsung, Huawei, Oppo etc. matam serviços em segundo plano de
   forma agressiva (ver dontkillmyapp.com). A garantia "o shield volta às 5h" é bem mais difícil de
   manter no Android do que no iOS — exige código específico por fabricante e telas guiando o usuário a
   desativar a otimização de bateria.
3. **Menos elegante.** Costuma haver um "flash" do app bloqueado antes do overlay cobrir; o bloqueio é
   reativo (detecta e cobre), não preventivo como no iOS.

**Conclusão desta seção:** dá para fazer, e apps sérios fazem — mas é **outra arquitetura**, mais
frágil, com risco regulatório, e não se comporta de forma idêntica ao iOS. É aqui que a estimativa
precisa ser realista.

---

## 4. Sobre frameworks cross-platform (Flutter / React Native)

Tentação natural: "faço em Flutter e sirvo os dois". Ajuda a compartilhar UI e lógica de negócio, **mas
não resolve o ponto duro** — o bloqueio de apps continua exigindo código nativo específico em cada
plataforma (nenhum framework abstrai Screen Time / app-blocking). Ou seja: cross-platform economiza na
parte fácil, não na difícil. Para um app cuja essência é o bloqueio nativo, o ganho é limitado; um
Android nativo (Kotlin/Compose) tende a ser mais previsível.

---

## 5. Recomendação de sequência

1. **NÃO tratar como "portar o iOS".** Tratar como **um segundo app** que compartilha o backend, sabendo
   que o mecanismo de bloqueio será nativo, diferente e mais delicado.
2. **Primeiro passo antes de qualquer investimento grande: um protótipo só do bloqueio** — Accessibility
   + overlay + reaplicação às 5h com WorkManager — testado num **Xiaomi/Samsung real** (não só emulador).
   Objetivo: medir a confiabilidade do re-arme matinal e sentir o risco do Google Play. Essa peça é o
   gargalo; se ela se provar sólida o suficiente para o seu padrão de qualidade, o resto é execução.
3. Só depois do protótipo validar, construir o app completo em volta do backend existente.

---

## 6. Perguntas para fazer ao desenvolvedor Android (na cotação)

- Você já publicou app que usa **AccessibilityService para bloqueio** e passou pela revisão do Google Play?
- Como garante a sobrevivência do serviço em segundo plano em **Xiaomi/Samsung/Huawei**?
- Qual a estratégia para o re-arme confiável às 5h (WorkManager + AlarmManager exato + boot receiver)?
- Como lida com o "flash" do app antes do overlay?
- Estimativa separada para: (a) UI + billing + integração com o backend; (b) o módulo de bloqueio nativo.
  *(Peça as duas separadas — é o (b) que carrega o risco.)*
