# Próximas ações no App Store Connect - Limiar

Atualizado em 25/06/2026, após o envio da build `1.0 (23)`.

## Estado comprovado agora

- GitHub está atualizado no commit `bf48582`.
- Site público está no ar: `https://limiar-five.vercel.app/`.
- Build enviada para Apple/TestFlight: `1.0 (23)`.
- App Apple ID: `6783115468`.
- Bundle ID: `com.romeucunha.Limiar`.
- Archive local: `build/TestFlight/Limiar-1.0-23.xcarchive`.
- O Xcode registrou:
  - `Prepared archive for uploading`: sucesso.
  - `Uploaded to Apple`: sucesso.
  - Data do upload: `2026-06-25T21:41:47Z`.
- Screenshots prontos:
  - `app-store/upload-ready/` para iPhone 6.7".
  - `app-store/upload-ready-6.5/` para iPhone 6.5".
- URLs publicadas:
  - Marketing: `https://limiar-five.vercel.app/`
  - Privacidade: `https://limiar-five.vercel.app/privacy.html`
  - Termos: `https://limiar-five.vercel.app/terms.html`
  - Suporte: `https://limiar-five.vercel.app/support.html`

## O que fazer agora na Apple

### 1. Confirmar processamento da build

1. Abra o App Store Connect.
2. Entre em `Apps > Limiar > TestFlight`.
3. Procure a build `1.0 (23)`.
4. Aguarde até ela sair de `Processing`.
5. Quando aparecer como disponível, selecione essa build para teste interno ou para a versão iOS `1.0`.

Se a build `1.0 (23)` ainda não aparecer, aguarde mais alguns minutos e atualize a página.

Opcionalmente, se houver App Store Connect API Key disponível, use `scripts/check_app_store_build_status.sh` seguindo `docs/APP_STORE_BUILD_STATUS_CHECK.md` para consultar esse status pelo terminal.

### 2. Conferir contrato para vender

1. Abra `Business` ou `Agreements, Tax, and Banking`.
2. Confirme que o `Paid Apps Agreement` está ativo.
3. Confirme dados bancários preenchidos.
4. Confirme dados fiscais preenchidos para pessoa física.

Sem isso, o app pode até ser submetido, mas a assinatura não fica plenamente pronta para venda.

### 3. Configurar disponibilidade Brasil

Em `Apps > Limiar > Pricing and Availability`:

- Distribuição: pública na App Store.
- País/região: somente Brasil.
- Não ativar outros países.
- Não marcar disponibilidade automática para novos países, se essa opção aparecer.

### 4. Criar assinatura mensal

Criar ou revisar o grupo:

- Grupo: `Limiar Premium`
- Nome exibido do grupo: `Limiar Premium`

Produto mensal:

- Product ID: `limiar_premium_monthly`
- Reference Name: `Limiar Premium Monthly`
- Display Name: `Limiar Premium Mensal`
- Duration: `1 Month`
- Price: `R$ 9,90`
- Availability: somente Brasil

Não criar plano anual para o lançamento inicial.

### 5. Preencher metadados

Use estes arquivos como fonte:

- `app-store/app-store-copy.md`
- `app-store/app-store-connect-fields.md`
- `docs/APP_STORE_MANUAL_SUBMISSION_BRASIL.md`

Campos principais:

- Nome: `Limiar`
- Subtítulo: `Pausa espiritual antes de apps`
- Política de Privacidade: `https://limiar-five.vercel.app/privacy.html`
- Suporte: `https://limiar-five.vercel.app/support.html`
- Marketing URL: `https://limiar-five.vercel.app/`

### 6. Enviar app e assinatura juntos para revisão

Antes de clicar em enviar:

- Build `1.0 (23)` selecionada.
- Assinatura mensal `limiar_premium_monthly` incluída na submissão.
- Disponibilidade do app somente Brasil.
- Disponibilidade da assinatura somente Brasil.
- Screenshots enviados.
- App Privacy preenchido.
- Age Rating preenchido.
- Export Compliance respondido.
- Review Notes coladas.

## Review Notes recomendadas

```text
O Limiar usa recursos nativos do iOS relacionados ao Tempo de Uso para criar pausas escolhidas pelo usuário antes de apps selecionados. As reflexões são para meditação pessoal e não substituem aconselhamento religioso ou profissional.

Depois do onboarding, o usuário inicia 7 dias grátis com experiência completa. Se o teste terminar sem assinatura, o app entra no Modo Essencial: mantém os 3 trechos principais e o fluxo de pausa, mas sem narração, reflexões por IA e maior variedade.

Para testar a assinatura, toque em "Ver planos" ou "Assinar Premium" e escolha o plano mensal disponível no StoreKit.

Se o revisor não conseguir conceder Tempo de Uso no dispositivo de teste, ele pode tocar em "Fazer isso depois" no onboarding. O teste gratuito e o paywall continuarão acessíveis, e a autorização de Tempo de Uso poderá ser feita depois em Configurações.

Recursos Premium: geração completa por IA, narração, personalização contínua por tradição/temas/livros, histórico, baixa repetição de leituras e experiência completa do Limiar.
```

## Status real

O projeto está tecnicamente enviado para TestFlight/App Store Connect na build `1.0 (23)`.

A venda pública ainda depende das confirmações manuais no App Store Connect: processamento da build, seleção da build na versão, contrato pago, dados bancários/fiscais, assinatura mensal e envio para revisão.
