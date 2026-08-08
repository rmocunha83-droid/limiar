# Rótulo de privacidade — App Store Connect (1.13)

Checklist para atualizar a ficha "Privacidade do App" no App Store Connect
depois da integração de Firebase Analytics + Crashlytics (modo completo) e do
Meta SDK. Aplicável em: App Store Connect → Limiar → Privacidade do App →
Editar.

Fonte da verdade: `Limiar/PrivacyInfo.xcprivacy` (app) + manifests dos SDKs
(Firebase, Crashlytics, FacebookCore, GoogleMobileAds). A política publicada em
`applimiar.com.br/privacy` já descreve esta coleta.

## Pergunta inicial

"Você ou seus parceiros terceirizados coletam dados deste app?" → **Sim**.

## Categorias a marcar

### 1. Identificadores → Identificador do dispositivo
- Coletado por: Meta SDK (IDFA, somente com autorização do ATT) e AdMob.
- Uso: **Publicidade de terceiros** (atribuição de campanhas).
- Vinculado à identidade do usuário? **Não**.
- Usado para rastreamento? **Sim** (é exatamente o caso do ATT; o app já
  exibe o prompt do ATT e funciona sem autorização).

### 2. Dados de uso → Interação com o produto
- Coletado por: Firebase Analytics (eventos de onboarding, travessia,
  narração, portão/paywall) e Meta SDK (eventos de app).
- Uso: **Análises** e **Funcionalidade do app**.
- Vinculado à identidade? **Não** (nenhum login; IDs de instância apenas).
- Usado para rastreamento? **Não** para o Firebase. (O rastreamento já está
  coberto pela categoria de identificador acima; não marcar aqui.)

### 3. Diagnóstico → Dados de falha
- Coletado por: Crashlytics.
- Uso: **Funcionalidade do app**.
- Vinculado à identidade? **Não**. Rastreamento? **Não**.

### 4. Diagnóstico → Dados de desempenho
- Coletado por: Crashlytics/Firebase (métricas de inicialização, ANRs).
- Uso: **Funcionalidade do app**.
- Vinculado à identidade? **Não**. Rastreamento? **Não**.

### 5. Outros dados
- Manter a categoria já existente (preferências de leitura no app group),
  uso **Funcionalidade do app**, não vinculado, sem rastreamento.

## O que NÃO marcar

- Nome, e-mail, telefone, endereço, contatos, fotos, localização, saúde,
  histórico de navegação, informações financeiras: o app não coleta nada
  disso.
- "Conteúdo do usuário": os trechos salvos ficam no aparelho (app group) e
  não são enviados a servidores próprios com identificação.
- Importante: a tradição religiosa escolhida é tratada como preferência de
  conteúdo de leitura (user property `reading_tradition` no Firebase), nunca
  como dado vinculado à identidade nem audiência de anúncio. Ela está coberta
  pela categoria "Dados de uso" acima e descrita na política de privacidade.

## Depois de salvar

1. Conferir o resumo gerado pela Apple: deve exibir "Dados usados para
   rastrear você: Identificadores" + "Dados não vinculados a você: Dados de
   uso, Diagnóstico, Outros dados".
2. A mudança de rótulo pode ser salva a qualquer momento; ela entra no ar
   junto com a próxima versão aprovada (1.13).
