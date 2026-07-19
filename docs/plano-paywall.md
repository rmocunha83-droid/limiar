# Plano — Novo Paywall do Limiar (carrossel de depoimentos + copy de perda)

Documento de planejamento. Nada implementado. Base: `PaywallView.swift` atual, produtos
`limiar_premium_monthly` e `limiar_premium_annual_2026`.

## Contexto de exibição (definido pelo produto)

- **Teste grátis: 7 dias** com acesso completo.
- **O paywall NÃO aparece no fim do trial.** Ele aparece **1 dia depois** — o usuário passa o dia 8
  no Modo Essencial, sentindo as diferenças na prática, e só então vê esta tela.
- Consequência para a copy: **não há urgência de prazo** ("termina em N dias" não se aplica).
  A alavanca central vira a **perda já vivida**: a pessoa acabou de experimentar um dia sem
  narração, sem a reflexão completa e com anúncios. A tela nomeia o que ela sentiu ontem.

## O que o Essencial mantém e o que perde (fatos — base da copy)

**A pessoa AINDA TEM:**
- a pausa diária e o bloqueio de apps;
- escolha/edição dos apps bloqueados;
- uma travessia diária no ritmo escolhido;
- explicações essenciais nos trechos;
- salvar trechos enquanto lê.

**A pessoa PERDE:**
- narração dos trechos (voz natural);
- a seção completa de reflexão — "Entenda o significado": sentido espiritual, aplicação prática e
  pergunta de meditação;
- edição de tradição, profundidade e estilos/livros;
- acesso às telas de **histórico** e de **trechos salvos** (ela até salva, mas não consegue abrir
  a lista);
- experiência sem anúncios — há publicidade **após os trechos e no dashboard**.

---

## 1. Estrutura da tela (ordem vertical)

1. **Header — perda já vivida** (ver §3)
2. **Painel de investimento pessoal**: "Você concluiu N travessias e leu M trechos" (dados reais
   de `model.history`; reaproveita o `TrialMetricsPanel`)
3. **Carrossel de depoimentos** (5 cards, autoplay suave, dots)
4. **Contraste honesto**: 1 linha do que continua + bloco "Desde ontem, você está sem:"
5. **Seletor de planos** — Anual pré-selecionado (R$ 89,90/ano) com âncora; Mensal abaixo
6. **CTA primário** + linha de segurança ("Cancele quando quiser · A App Store confirma antes de cobrar")
7. Restaurar compra + links legais (como hoje)

---

## 2. Carrossel de depoimentos (5 cards, sem rosto)

Formato: ★★★★★ (warmGold) · texto · primeiro nome + inicial. Sem foto.

1. ★★★★★ — "Eu abria o Instagram antes mesmo de levantar da cama. Agora a primeira coisa que leio
   todo dia é a Palavra. Mudou minhas manhãs." — **Mariana S.**
2. ★★★★★ — "Voltei a ler a Bíblia todos os dias depois de anos tentando criar o hábito. O 'Entenda
   o significado' faz o texto conversar comigo." — **Carlos E.**
3. ★★★★★ — "As distrações diminuíram muito. O bloqueio me dá aquele segundo de consciência antes
   de cair no automático." — **Patrícia R.**
4. ★★★★★ — "Faço a travessia no café da manhã ouvindo os trechos. A narração parece alguém lendo
   pra mim, com calma." — **João P.**
5. ★★★★★ — "Cada dia vem um trecho diferente, nos temas que eu escolhi. Sinto que o app respeita a
   minha fé." — **Ana L.**

> **⚠️ Conformidade:** estes 5 são *placeholders de layout*. Depoimentos inventados apresentados
> como reais violam as diretrizes da App Store (marketing enganoso) e o CDC. Substituir por
> citações reais (TestFlight, avaliações, mensagens com permissão) antes de produção — o layout
> não muda. Alternativa até lá: rótulo institucional ("O que o Limiar proporciona").

**Comportamento:** `TabView` + `.tabViewStyle(.page)`, auto-avanço ~5s, dots em sage, altura fixa.

---

## 3. Copy de perda (o coração da tela)

### Header (contexto: 1 dia após o fim do trial)

- Eyebrow: `LIMIAR PREMIUM`
- Título: **"Ontem, sua travessia ficou menor."**
- Sub: "Sua pausa diária continua — mas desde ontem ela vem sem a parte que fazia a diferença."

*(Variante para o upsell a partir do Essencial, semanas depois: título "Sua pausa pode voltar a
ser completa" — mesma tela, header trocado.)*

### Contraste honesto (1 linha antes das perdas)

> "Você continua com a pausa, o bloqueio e sua travessia diária. O que mudou:"

Nomear o que fica é deliberado: honestidade gera confiança e torna a lista de perdas mais crível.

### Bloco "Desde ontem, você está sem:" (as perdas, na ordem de dor)

1. ✕ **A reflexão completa** — o "Entenda o significado", com sentido espiritual, aplicação
   prática e pergunta de meditação
2. ✕ **A narração** dos trechos com voz natural
3. ✕ **Leituras do seu jeito** — tradição, profundidade, estilos e livros travados
4. ✕ **Seu histórico e seus trechos salvos** — você salva, mas a lista fica trancada
5. ✕ **Pausa limpa** — agora há anúncios depois dos trechos e no dashboard

Regra de ouro: cada linha nomeia algo que a pessoa **usou por 7 dias e perdeu ontem** — perda de
posse vivida, não promessa.

---

## 4. Técnicas de alavancagem (todas honestas)

1. **Perda já vivida** (principal): a pessoa passou 24h no Essencial. A tela não ameaça — descreve
   o ontem dela. "Desde ontem" > "você vai perder".
2. **Investimento pessoal:** "Você concluiu N travessias" — não perca o ritmo construído em 7 dias.
3. **Ancoragem de preço:** Anual **R$ 89,90** pré-selecionado, exibido como **R$ 7,49/mês**
   (equivalente) + "menos de R$ 0,25 por dia". Mensal abaixo como âncora (economia % calculada em
   runtime via StoreKit — nunca hardcodar).
4. **Reenquadramento:** "menos de R$ 0,25 por dia para começar o dia com a Palavra em vez de
   notificações".
5. **Prova social:** carrossel + linha "Junte-se a quem transformou as manhãs".
6. **Sem urgência falsa:** nenhum contador. O prazo do trial já passou; escassez inventada seria
   antiética e reprovável pela Apple.
7. **Redução de risco no CTA:** "Cancele quando quiser. A App Store confirma o valor antes de
   qualquer cobrança."

### CTA
- **"Voltar ao Limiar completo"** (a pessoa está restaurando algo que era dela).
- Secundário discreto: "Continuar no Essencial" (manter acessível — sem dark pattern).

---

## 5. Notas de implementação (para quando aprovar)

- Tudo em `PaywallView.swift`; sem mudança de backend/StoreKit.
- Carrossel: `TabView` + `.page` + `Timer`; depoimentos em array estático (trocáveis por citações
  reais sem mexer no layout).
- Perdas: lista com `xmark.circle` (coral suave); linha de contraste com `checkmark.circle`.
- "N travessias / M trechos": de `model.history` (como o `TrialMetricsPanel` atual).
- Preços/economia: sempre de `displayPrice(for:)` do StoreKit; o equivalente mensal do anual
  (R$ 89,90 ÷ 12 = R$ 7,49) e o %, calculados em runtime.
- Gate de exibição (paywall D+1 pós-trial): já é responsabilidade do `SubscriptionManager`
  (`shouldShowPostTrialPaywall`) — conferir se o atraso de 1 dia está implementado lá; se não,
  entra no escopo.
- A/B futuro: título "Ontem, sua travessia ficou menor" vs variante aspiracional; com/sem carrossel.
- Medir funil: visualização → seleção de plano → compra.

## 6. O que NÃO fazer (guard-rails)

- Escassez/contador falso.
- Depoimentos fabricados como reais em produção (§2).
- Esconder preço ou cancelamento.
- Dificultar o "Continuar no Essencial" — a confiança é o produto.
