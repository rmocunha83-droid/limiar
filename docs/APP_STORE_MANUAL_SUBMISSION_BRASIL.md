# Guia manual de submissão App Store - Limiar Brasil

Última atualização: 25/06/2026.

Este guia consolida o que falta fazer no App Store Connect para vender o Limiar no Brasil como pessoa física. Ele usa o estado atual do projeto, do site e da build enviada ao TestFlight.

## Estado atual comprovado

- Repositório GitHub: `main` estava atualizado até `208444c` no início desta checagem.
- Site público: `https://applimiar.com.br`.
- Versão em preparação: `1.13`; o número de build será atribuído pelo Xcode Cloud.
- App Apple ID: `6783115468`.
- Bundle ID: `com.romeucunha.Limiar`.
- Archive local: `build/TestFlight/Limiar-1.0-23.xcarchive`.
- Registro local do Xcode: `Uploaded to Apple` em `2026-06-25T21:41:47Z`.
- Produto de assinatura preparado para lançamento: somente plano mensal.

Fontes oficiais úteis:

- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [Agreements, Tax, and Banking](https://appstoreconnect.apple.com/agreements/)
- [In-App Purchases overview](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/)
- [Manage app availability](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store/)
- [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Submit an In-App Purchase](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/)

## 1. Conta, contratos e recebimento

No App Store Connect, entre como Account Holder da conta de pessoa física.

1. Acesse `Business` ou `Agreements, Tax, and Banking`.
2. Aceite o `Paid Apps Agreement`.
3. Preencha os dados bancários.
4. Preencha os dados fiscais exigidos para pessoa física.
5. Confirme que o Paid Apps Agreement está `Active`.

Observação: In-App Purchases exigem Paid Apps Agreement ativo, dados bancários e dados fiscais. Sem isso, a assinatura pode não ficar disponível para teste/submissão.

## 2. Disponibilidade do app

Em `Apps > Limiar > Pricing and Availability`:

- Distribution method: `Public`.
- App Availability: somente `Brazil`.
- Não ativar outros países/regiões.
- Se houver opção para novos países adicionados futuramente, manter desativada quando possível.

## 3. Assinaturas Premium

Criar apenas um grupo de assinatura para o lançamento:

- Grupo: `Limiar Premium`
- Nome exibido do grupo: `Limiar Premium`

Produto mensal:

- Product ID: `limiar_premium_monthly`
- Reference Name: `Limiar Premium Monthly`
- Display Name: `Limiar Premium Mensal`
- Duration: `1 Month`
- Price: `R$ 9,90`
- Availability: somente `Brazil`
- Review submission: enviar junto com a versão `1.0`

Produto anual:

- Product ID: `limiar_premium_annual_2026`
- Reference Name: `Limiar Premium Anual`
- Display Name: `Limiar Premium Anual`
- Duration: `1 Year`
- Price: `R$ 89,90`
- Availability: somente `Brazil`
- Review submission: enviar junto com a nova versão do app

Os dois produtos devem ficar no mesmo grupo de assinatura `Limiar Premium`.

Oferta introdutória: teste grátis de 1 semana nos dois produtos, somente Brasil, início em 06/08/2026 e sem data final. Usuários novos só entram no dashboard com entitlement StoreKit ativo; usuários legados preservam o trial local anterior.

## 4. Build para selecionar

Na versão iOS `1.0`, selecione:

- Build: a compilação `1.13` gerada pelo Xcode Cloud após autorização de release

Se a build ainda aparecer como processando, aguarde o processamento terminar no App Store Connect/TestFlight.

## 5. Metadados da App Store

Use como fonte:

- `app-store/app-store-copy.md`
- `app-store/app-store-connect-fields.md`

Campos principais:

- Nome: `Limiar`
- Subtítulo: `Pausa espiritual antes de apps`
- Palavras-chave: `foco,tempo de uso,pausa,espiritualidade,bíblia,devocional,atenção,disciplina,hábitos`
- Marketing URL: `https://applimiar.com.br`
- Política de Privacidade: `https://applimiar.com.br/privacy`
- Suporte: `https://applimiar.com.br/support`
- Termos: `https://applimiar.com.br/terms`

Screenshots:

- `app-store/upload-ready/` para 6.7"
- `app-store/upload-ready-6.5/` para 6.5"

## 6. App Privacy

Declaração sugerida com base no app atual:

- Tracking: `No`.
- IDFA: `No`.
- Dados usados para rastrear: `No`.
- Dados vinculados à identidade do usuário: `No`.
- Dados coletados: declarar apenas os dados mínimos usados para funcionalidade do app.

Sugestão prática:

- Categoria: `Other Data Types`.
- Uso: `App Functionality`.
- Vinculado à identidade: `No`.
- Tracking: `No`.

Justificativa: o app pode enviar ao backend apenas preferências espirituais e contexto mínimo para gerar conteúdo, como tradição, temas, livros/seções, profundidade, trecho selecionado e resumo recente para evitar repetição. O app não envia seleção dos apps que ativam o Limiar, email, contatos, localização precisa, dados de publicidade ou identificadores pessoais para a geração por IA.

Se o fluxo do App Store Connect perguntar de forma diferente, responda sempre de forma conservadora e alinhada à Política de Privacidade publicada.

## 7. Classificação etária

Resposta sugerida:

- Violência: `None`.
- Conteúdo sexual: `None`.
- Jogos de azar: `None`.
- Acesso irrestrito à web: `No`.
- Conteúdo médico: `No`.
- Compras fora do app: `No`.
- Conteúdo religioso/espiritual: leve, voltado a meditação pessoal.

## 8. Export Compliance

O app usa comunicação HTTPS padrão para falar com o backend e serviços da Apple. Não há criptografia proprietária no projeto.

No App Store Connect, responda conforme a pergunta exibida sobre uso de criptografia. Se a pergunta oferecer a opção equivalente a uso de criptografia padrão de sistema/HTTPS, use essa opção. Se houver dúvida no formulário, pare e valide antes de enviar para revisão.

## 9. Notas para revisão

Cole este texto em `App Review Notes`:

```text
O Limiar usa recursos nativos do iOS relacionados ao Tempo de Uso para criar pausas escolhidas pelo usuário antes de apps selecionados. As reflexões são para meditação pessoal e não substituem aconselhamento religioso ou profissional.

Depois do onboarding, usuários novos encontram um portão de assinatura sem opção de pular. Clientes elegíveis podem iniciar 7 dias grátis no plano mensal ou anual; durante o teste, o entitlement ativo libera o dashboard. Sem entitlement, usuários novos voltam ao portão. Usuários legados preservam o fluxo anterior, inclusive o Modo Essencial.

Para testar a assinatura, escolha o plano mensal ou anual no portão ou toque em "Restaurar compras".

Se o revisor não conseguir conceder Tempo de Uso no dispositivo de teste, ele pode tocar em "Fazer isso depois" no onboarding. O portão continuará acessível, e a autorização de Tempo de Uso poderá ser feita depois em Configurações.

Recursos Premium: reflexões completas, narração, personalização contínua por tradição/temas/livros, histórico, baixa repetição de leituras e experiência completa do Limiar.
```

## 10. Antes de enviar para revisão

Checklist final:

- Paid Apps Agreement ativo.
- Dados bancários e fiscais preenchidos.
- App disponível somente no Brasil.
- Assinaturas mensal e anual disponíveis somente no Brasil.
- Produto `limiar_premium_monthly` em estado pronto para submissão.
- Build `1.13` do Xcode Cloud selecionada.
- Assinatura mensal selecionada na seção de In-App Purchases/Subscriptions da versão.
- App Privacy preenchido.
- Age Rating preenchido.
- Export Compliance respondido.
- Screenshots enviados.
- URLs de suporte, privacidade e termos abrindo corretamente.
- TestFlight/Sandbox validado com portão, elegibilidade do teste grátis, assinatura, restauração, expiração da coorte nova e regressão do Modo Essencial legado.

## Status

O projeto está tecnicamente pronto para submissão, mas a venda pública ainda depende das ações manuais acima no App Store Connect.
