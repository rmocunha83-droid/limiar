# Limiar — Rastreamento da Meta em modo completo (24/07/2026)

Repositório: `rmocunha83-droid/limiar` · Branch: `main` (push em main = deploy automático do Vercel + build no Xcode Cloud).

Documento de handoff das mudanças aplicadas em 24/07/2026. **Tudo descrito aqui já está no `main` e em produção.** O app correspondente é a versão **1.11 (build 157)**, gerada pelo Xcode Cloud, aguardando revisão da Apple.

## Commits

| Commit | Descrição |
|---|---|
| `aab4365` | Metatag de verificação de domínio do Meta |
| `b4d940c` | `meta-capi`: aceita eventos do domínio `applimiar.com.br` |
| `4ac2bb8` | **Meta SDK em modo completo** — a mudança principal |
| `d360985` | Site: e-mail de contato próprio + política de privacidade alinhada |

---

## 1. Meta SDK em modo completo — `Limiar/LimiarApp.swift`

### Problema encontrado

O `enum MetaAppEvents` bloqueava **todo** envio de eventos quando o usuário recusava o prompt do ATT (App Tracking Transparency). Como a maioria recusa, o conjunto de dados do app na Meta registrou apenas **6 eventos em 28 dias**, e a coluna "Resultados" das campanhas de instalação ficava zerada mesmo com dezenas de instalações reais por dia.

Havia um agravante silencioso: sem esses dados a Meta também **otimizava às cegas** — não sabia qual público instalava, então a entrega rendia menos do que o investimento pagaria.

### Alterações

**`requestTrackingPermissionIfNeeded()`**
Antes: `switch` sobre o status do ATT, inicializando o SDK apenas no caso `.authorized`.
Agora: retorna cedo se o status não for `.notDetermined` (o prompt do sistema só pode aparecer uma vez por instalação de qualquer forma) e, no callback, **ignora o status** e chama `activateApp()` para que o próximo lote já carregue o novo estado.

**`initialize(application:launchOptions:)`**
Passou a fixar explicitamente, logo após o `ApplicationDelegate`:

```swift
Settings.shared.isAutoLogAppEventsEnabled = true
Settings.shared.isAdvertiserIDCollectionEnabled = true
```

**`activateApp()`**
Removida a guarda `guard ATTrackingManager.trackingAuthorizationStatus == .authorized else { return }`.

**`trackAfterAuthorization(event:defaultsKey:)`**
O `switch` sobre o status do ATT foi removido; chama `log()` diretamente. A deduplicação por `defaultsKey` (via `UserDefaults`) foi **preservada**.

**`log(_:defaultsKey:)`**
Guarda reduzida de `didInitializeSDK && status == .authorized` para apenas `didInitializeSDK`.

### Racional — não reverter sem entender

O ATT **não controla o envio de eventos**. Ele controla o acesso ao IDFA e, por consequência, a possibilidade de vincular os eventos a um perfil da Meta. Quem recusa continua contribuindo de forma agregada — que é exatamente como a SKAdNetwork conta instalações e como a Meta faz modelagem de conversão.

A implementação anterior confundia as duas coisas e descartava a maior parte do sinal por precaução desnecessária.

### O que **não** mudou

O prompt do ATT continua aparecendo **uma única vez, depois do onboarding**. É chamado em `ContentView.swift` (dentro do `.task`, com guarda `model.hasCompletedOnboarding`). Nenhuma alteração nesse ponto.

---

## 2. `Limiar/Info.plist`

Quatro chaves adicionadas:

```xml
<key>FacebookAutoLogAppEventsEnabled</key><true/>
<key>FacebookAdvertiserIDCollectionEnabled</key><true/>
<key>SKAdNetworkItems</key>
<array>
  <dict><key>SKAdNetworkIdentifier</key><string>v9wttpbfk9.skadnetwork</string></dict>
  <dict><key>SKAdNetworkIdentifier</key><string>n38lu8286q.skadnetwork</string></dict>
  <dict><key>SKAdNetworkIdentifier</key><string>cstr6suwn9.skadnetwork</string></dict>
</array>
```

**O `SKAdNetworkItems` não existia no projeto** — nem os dois identificadores da Meta, nem o do AdMob (`cstr6suwn9`). Sem eles a Apple não entrega os postbacks de atribuição para as redes de anúncios. Era uma lacuna anterior a este trabalho.

`CURRENT_PROJECT_VERSION` foi de 149 → 150 em `Limiar.xcodeproj/project.pbxproj`.

---

## 3. `api/meta-capi.js`

O endpoint validava a origem do evento contra um único prefixo fixo (`https://limiar-five.vercel.app/`) e devolvia **HTTP 400 `invalid_event`** para tudo que viesse do domínio novo. O erro foi confirmado com requisição real antes da correção.

Passou a validar contra uma allowlist:

```js
const ALLOWED_EVENT_SOURCE_PREFIXES = [
  "https://applimiar.com.br/",
  "https://www.applimiar.com.br/",
  "https://limiar-five.vercel.app/"
];
```

Verificado em produção após o deploy:

| Origem | Resultado |
|---|---|
| `https://applimiar.com.br/` | HTTP 204 — aceito |
| `https://www.applimiar.com.br/` | HTTP 204 — aceito |
| domínio arbitrário | `invalid_event` — bloqueado |

O controle negativo importa: a proteção contra terceiros injetando eventos falsos no Pixel permanece intacta.

---

## 4. Site — `index.html`, `privacy.html`, `terms.html`, `support.html`

As cópias em `marketing/site/` receberam as mesmas alterações de e-mail.

**`index.html`** — metatag no `<head>`, responsável pela verificação do domínio no Business Manager:

```html
<meta name="facebook-domain-verification" content="hoi115r1anat7fdl41kk3szi6ty34w" />
```

**E-mail de contato** — as três páginas legais exibiam `suporte@limiar.app`, um **domínio que não existe**, com o `mailto:` apontando para o Gmail pessoal do fundador. Quem copiasse o texto visível escrevia para o vazio; quem clicasse via o endereço pessoal. Trocado para `contato@applimiar.com.br` no texto e no link.

**`privacy.html`** — a seção "Rastreamento e publicidade" afirmava:

> "Se a permissão for negada, o Limiar não disponibiliza o identificador de publicidade nem envia esses eventos personalizados."

Isso deixou de ser verdade com a mudança da seção 1. O parágrafo foi reescrito em dois: o primeiro descreve os eventos enviados e a participação na SKAdNetwork; o segundo explica que o ATT controla o IDFA e o vínculo com o perfil, não o envio em si. Data atualizada para 24/07/2026.

> Política que descreve práticas diferentes das reais é exposição jurídica e motivo comum de rejeição na revisão da Apple, que compara a ficha de privacidade com o comportamento observado do app.

---

## 5. Configurações fora do código

Já aplicadas nos painéis, não versionadas. Registradas aqui para referência.

**Gerenciador de Eventos** — conjunto de dados "Limiar: Pausa Espiritual" (ID `27700219559573880`):
- Registro automático de eventos para o SDK: **Ativado**
- Correspondência avançada automática: **Ativada**

**Business Manager** (`1647419069675467`, portfólio "Limiar.app"):
- Domínio `applimiar.com.br` **verificado** (via metatag)
- Conta de anúncios: `2435295503569905`
- Pixel do site: `1567751021802834`

**App Store Connect** (app `6783115468`):
- Ficha de privacidade atualizada: Identificadores, Informações de uso e Dados de publicidade declarados como **usados para rastreamento**
- URL de suporte: `https://applimiar.com.br/support`
- URL de marketing: `https://applimiar.com.br`

---

## 6. Avisos operacionais

### Nunca compilar localmente para a App Store

O **Xcode Cloud já está configurado** e compila automaticamente a cada push no `main`. É a única fonte confiável de binários submissíveis.

Duas tentativas de build local foram rejeitadas pela Apple, por motivos opostos:

| Build | Origem | Resultado |
|---|---|---|
| 157 | Xcode Cloud | ✅ aceito, em revisão |
| 158 | Máquina local, `Xcode.app` 26.6 | ❌ ITMS-90111 — SDK sem suporte |
| 159 | Máquina local, `Xcode-beta.app` 27.0 | ❌ beta não permitido para submissão |

A causa do 158: o `Xcode.app` da máquina reporta versão 26.6 mas traz o **SDK do iOS 26.5** — instalação incompleta. O Xcode Cloud usa a mesma versão 26.6 com o SDK correto e funciona.

**Fluxo correto:** fazer push no `main` → esperar o Xcode Cloud gerar a compilação → anexá-la à versão em App Store Connect → enviar para revisão.

### Verificar a ficha de privacidade a cada mudança no SDK

Divergência entre o que a ficha declara e o que o app faz é motivo comum de rejeição. A ficha estava desatualizada e foi corrigida hoje; qualquer alteração futura no comportamento de coleta exige revisitá-la.

---

## 7. Expectativa de resultado

A coluna "Resultados" das campanhas de instalação só volta a contar quando a **1.11 (157) for aprovada e instalada** pelos usuários. Instalações da 1.10 continuam invisíveis para a Meta.

Os postbacks da SKAdNetwork chegam com **24 a 48 horas de atraso** por design da Apple — o primeiro dia após a aprovação sempre parece fraco. Convém esperar dois ou três dias antes de avaliar os números.

Eventos de teste podem ser conferidos em: Gerenciador de Eventos → Conjuntos de dados → "Limiar: Pausa Espiritual" → **Eventos de teste**, rodando o app pelo Xcode ou TestFlight.
