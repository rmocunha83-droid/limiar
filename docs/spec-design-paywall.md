# Limiar — Especificação de design: funil de conversão (3 telas)

Documento para o designer executar os layouts finais (Figma). Contém: contexto, tokens visuais,
anatomia e copy completa de cada tela, comportamento dos componentes e regras do que não fazer.
Referência de estilo: as telas atuais do app (fundo escuro com a imagem do portal, título serif
creme, eyebrow dourado, ações em verde-sálvia).

---

## 1. Contexto do funil

Trial gratuito de 7 dias com acesso completo. Três momentos de conversão, cada um com uma
alavanca psicológica própria. **A ordem dos blocos muda por tela — é intencional.**

| Momento | Tela (já existe no código) | Alavanca | Tom |
|---|---|---|---|
| D6 — véspera do fim | `TrialConversionView` | Urgência real + perda iminente | Direto, acolhedor |
| D7 — dia do fim | `EssentialModeIntroView` | Nenhuma venda — honestidade | Suave, informativo |
| D8 — um dia depois | `PaywallView` | Perda já vivida + recuperação | Empático, concreto |

---

## 2. Tokens visuais (usar os do app)

| Token | Uso | Referência aproximada |
|---|---|---|
| `deepInk` | Fundo das telas | #0A1112 (fundo com a imagem do portal ao fundo, como nas telas atuais) |
| `ivory` | Títulos serif e textos fortes | #F2EAD9 |
| `softText` | Subtítulos e textos de apoio | #A9B0AD |
| `sageButton` | CTA primário, seleção, dots ativos, badge | #B3CFB8 (texto sobre ele: deepInk) |
| `warmGold` | Eyebrow, ícone de ritmo (chama), estrelas | #C98D4B / estrelas #E3B34C |
| coral suave | Ícones ✕ das perdas | #D88A7A (não usar vermelho puro — é aviso, não erro) |
| Painéis | Cards internos | fundo #111B1C, borda 1px #24312F, raio 12 |
| Tipografia | Título: serif (a mesma do app), 26-27pt. Corpo: sistema, 13pt. Eyebrow: 11pt, tracking 2, caixa alta |

Espaçamentos: padding lateral da tela 20-22; gap entre blocos 14-18; itens de lista 9 vertical
com divisor 1px #1D2827.

---

## 3. TELA D6 — Véspera ("Continue sem interrupção")

**Ordem dos blocos (de cima para baixo):**

1. **Eyebrow (warmGold):** `SEU ACESSO COMPLETO TERMINA AMANHÃ`
2. **Título (serif ivory):** `Continue sem interrupção.`
3. **Subtítulo (softText):** `Você não precisa perder nada do que construiu nestes 7 dias.`
4. **Painel de ritmo** (card com ícone de chama warmGold):
   `7 dias, **6 travessias**, **18 trechos**. Seu ritmo está no melhor momento.`
   *(números dinâmicos, vêm do app)*
5. **Bloco de perdas — rótulo:** `Amanhã, sem o Premium, você perde:`
   Lista em card, cada linha com ✕ coral à esquerda:
   - `A reflexão completa: significado, aplicação e pergunta`
   - `A narração com voz natural`
   - `Tradição, profundidade e livros do seu jeito`
   - `Histórico e a lista de trechos salvos`
   - `Pausa limpa — passará a ver anúncios`
6. **Carrossel de depoimentos** (ver §6) — card 1 visível + dots
7. **Planos** (ver §7) — Anual selecionado
8. **CTA primário (sage):** `Continuar minha travessia`
9. **Escape (texto discreto):** `Decidir amanhã`
10. **Linha de segurança (11pt, softText):** `Cancele quando quiser · A App Store confirma antes de cobrar`

---

## 4. TELA D7 — Fim do trial ("Seu acesso inicial terminou")

**Única tela SEM venda agressiva.** Papel: transição honesta, preservar confiança.

1. **Eyebrow:** `MODO ESSENCIAL`
2. **Título:** `Seu acesso inicial terminou.`
3. **Subtítulo:** `Sua pausa diária continua funcionando, gratuita. Veja o que fica com você:`
4. **Lista do que FICA** (✓ sage):
   - `Pausa diária e bloqueio dos seus apps`
   - `3 trechos por leitura, com explicações essenciais`
   - `Salvar trechos enquanto lê`
5. **Nota discreta (12pt, softText):** `O Essencial exibe anúncios e não inclui narração, a
   reflexão completa nem personalização. Você pode voltar ao completo quando quiser.`
6. **CTA primário (sage):** `Entendi, continuar`
7. **Link secundário:** `Conhecer o Limiar completo`

Sem carrossel, sem planos, sem contador. O botão primário é seguir grátis — de propósito.

---

## 5. TELA D8 — Recuperação ("Ontem, sua travessia ficou menor")

**As perdas vêm ANTES dos planos** (inverso da D6): aqui o trabalho é nomear a dor já sentida.

1. **Eyebrow:** `LIMIAR PREMIUM`
2. **Título:** `Ontem, sua travessia ficou menor.`
3. **Subtítulo:** `Sua pausa continua — mas desde ontem ela vem sem a parte que fazia a diferença.`
4. **Linha de contraste honesto** (✓ sage, 12pt): `Você continua com a pausa, o bloqueio e os 3 trechos.`
5. **Bloco de perdas — rótulo:** `Desde ontem, você está sem:`
   Mesma lista da D6 (✕ coral), com a última linha no passado:
   `Pausa limpa — anúncios nos trechos e no dashboard`
6. **Carrossel de depoimentos** — iniciar no card 2 (Carlos, que cita o "Entenda o significado")
7. **Planos** — Anual selecionado
8. **CTA primário:** `Voltar ao Limiar completo`
9. **Escape:** `Continuar no Essencial`
10. **Linha de segurança** (igual à D6)

---

## 5b. Momento visual — paisagem (lua sobre montanhas e água)

Para quebrar o fundo escuro, cada tela ganha UMA cena contemplativa na linha da identidade do app
(lua dourada com halo, silhuetas de montanhas, água com reflexo — mesma família da imagem do
portal). Regras de posicionamento para não brigar com o texto:

- **D6 e D8 (telas de venda):** a cena é o FUNDO do bloco de depoimento — full-bleed (sem borda de
  card), ~230pt de altura, posicionada entre a lista de perdas e os planos. A lua fica no terço
  superior da cena; estrelas ★, citação e nome assentam no terço inferior (sobre a água escura),
  centralizados. Fade vertical nas bordas superior e inferior da cena para fundir com o fundo
  `deepInk` da tela.
- **D7 (transição):** a cena é uma VINHETA DE TOPO (~150pt), acima do eyebrow, SEM texto por cima
  — puro respiro. Fade só na borda inferior.
- **Contraste é inegociável:** texto sobre a cena apenas na área mais escura (água/base). Se a
  arte final tiver áreas claras onde há texto, aplicar véu escuro sutil (overlay ~30-40%).
- **Uma cena por tela, sempre a mesma família visual.** Não competir com a imagem do portal usada
  no resto do app — é a mesma "noite", outro enquadramento.
- Asset: ilustração/foto tratada em tons #0C1418–#101A1A com lua #D9C39A e halo dourado suave;
  exportar em 3x com as duas máscaras de fade.

## 6. Componente: carrossel de depoimentos

- Card: fundo #111B1C, borda #24312F, raio 12. Conteúdo: ★★★★★ (dourado #E3B34C, 5 estrelas
  sempre) → citação em **serif** ivory 13-14pt, entre aspas → nome discreto (`Mariana S.`,
  12pt softText). **Sem foto/rosto** — se precisar de âncora visual, monograma em círculo.
- Dots abaixo, centralizados: ativo = pílula 16×5 sage; inativos = 5×5 #3A4643.
- Comportamento: swipe horizontal + auto-avanço a cada ~5s; altura FIXA (dimensionar pelo maior
  depoimento) para a tela não pular.
- **5 depoimentos (reais — TestFlight, 5 estrelas, autorizados em julho/2026):**
  1. "Eu queria ler mais a Bíblia, mas sempre me distraía. O Limiar me ajuda a fazer essa pausa no momento certo." — Mariana, São Paulo
  2. "Simples, bonito e direto. Em poucos segundos, o Limiar me ajuda a trocar a distração por uma Palavra de Deus." — Rafael, Curitiba
  3. "Gostei porque as leituras são curtas, claras e aparecem bem quando eu mais preciso parar." — Ana Clara, Belo Horizonte
  4. "Gostei porque é rápido e profundo ao mesmo tempo. Uma pausa pequena, mas que muda o começo do dia." — Fernanda, Brasília
  5. "O Limiar virou um lembrete simples de colocar Deus antes das distrações." — João, Belo Horizonte

## 7. Componente: seletor de planos

- **Anual (pré-selecionado):** borda 2px sage, fundo levemente esverdeado (#16211F). Badge
  flutuante no topo-esquerdo: `MAIS ESCOLHIDO` (sage, texto deepInk, 10pt, tracking 1).
  Linha principal: `Anual` ↔ `R$ 7,49/mês`. Linha secundária (11pt softText):
  `R$ 89,90 por ano · menos de R$ 0,25 por dia`.
- **Mensal:** borda 1px #2B3735, sem preenchimento. `Mensal` ↔ preço (vem da App Store).
- Nota para o dev (o designer não precisa resolver): preços e % de economia SEMPRE dinâmicos via
  StoreKit; o badge pode ganhar `· ECONOMIZE X%` quando o mensal estiver confirmado.
- Estado de seleção alternável (tocar no Mensal move a borda sage para ele).

## 8. Componente: bloco de perdas / ganhos

- Card padrão (#111B1C / borda #24312F / raio 12), linhas com divisor interno 1px #1D2827.
- Perda: ícone ✕ (15pt, coral #D88A7A) + texto 13pt #C9CEC9.
- Ganho (D7 e linha de contraste): ✓ sage.
- Máximo 5 linhas; texto de cada linha em 1 linha só (encurtar copy antes de quebrar linha).

---

## 9. Guard-rails (inegociáveis)

1. **Depoimentos:** usar SOMENTE citações reais com autorização registrada. As 5 do §6 são
   reais (TestFlight, julho/2026) — manter o registro das autorizações arquivado. Depoimento
   inventado apresentado como real = risco de rejeição da Apple e problema com CDC.
2. **Zero escassez falsa:** nenhum contador artificial, nenhuma "oferta por tempo limitado"
   inventada. A única urgência permitida é o prazo real do trial (D6).
3. **Saída sempre visível:** "Decidir amanhã" / "Continuar no Essencial" com contraste legível —
   sem dark pattern de botão escondido.
4. **Preço claro:** valor anual integral (R$ 89,90) sempre visível junto do equivalente mensal;
   linha de cancelamento em todas as telas de venda.
5. **D7 não vende:** o CTA primário do D7 é continuar grátis. Não transformar em paywall.

## 10. Entregáveis esperados do designer

- Frames iPhone (390×844) das 3 telas, light não necessário (app é dark-only).
- Estados: anual selecionado / mensal selecionado; carrossel nos 5 cards; D6 com 1-2 linhas de
  ritmo (usuário com poucas travessias vs muitas).
- Componentes exportáveis: card de depoimento, dots, linha de perda/ganho, card de plano, badge.
- Specs de espaçamento/auto-layout para handoff ao dev (as telas serão construídas em SwiftUI).
