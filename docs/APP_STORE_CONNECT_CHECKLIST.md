# Limiar - Checklist de App Store Connect

## Estado atual

- App compila em Debug.
- App compila em Release para iOS.
- Archive foi criado com sucesso.
- Export para App Store foi concluído com assinatura de distribuição.
- O App Store Connect contém a versão `1.12 (165)`; a build `1.13` ainda não deve ser enviada.
- O entitlement `com.apple.developer.family-controls` aparece no pacote exportado de distribuição.
- Conta do Xcode em uso: `Romeu Cunha - L38WCHAWJ9`.
- Bundle ID principal: `com.romeucunha.Limiar`.
- App limitado a iPhone (`TARGETED_DEVICE_FAMILY = 1`).
- Screenshots disponíveis em `app-store/`, tamanho `1290x2796`, aceito pela Apple para iPhone 6.9".
- Ícone disponível em `Limiar/Assets.xcassets/AppIcon.appiconset/app-icon.png`, tamanho `1024x1024`.

## Distribuição e vendas

- Método de distribuição: pública na App Store.
- Países/regiões: selecionar somente `Brasil`.
- Não marcar a opção para disponibilizar automaticamente em novos países/regiões.
- O app em si deve continuar gratuito para baixar.
- As vendas acontecem por assinatura dentro do app.
- As assinaturas também devem ficar disponíveis somente no Brasil.
- Comercialização pela pessoa física do Account Holder, usando os dados bancários e fiscais pessoais exigidos no App Store Connect.

Referências oficiais da Apple:

- Distribuição pública: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/set-distribution-methods/
- Disponibilidade do app por país/região: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store/
- Disponibilidade de compras dentro do app: https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-availability-for-in-app-purchases/
- Paid Apps Agreement: https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/
- Informações bancárias: https://developer.apple.com/help/app-store-connect/manage-banking-information/enter-banking-information/
- Acordos, impostos e banco: https://developer.apple.com/help/app-store-connect/manage-tax-information/provide-tax-information/

## App record

- Nome: `Limiar`
- Bundle ID: `com.romeucunha.Limiar`
- SKU sugerido: `limiar-ios-001`
- Plataforma: iOS
- Categoria primária: `Productivity`
- Categoria secundária sugerida: `Lifestyle`
- Preço do app: gratuito
- Disponibilidade: somente Brasil.

## Metadados em português

Fonte principal:

- `app-store/app-store-copy.md`

Campos:

- Nome: `Limiar`
- Subtítulo: `Pausa espiritual antes de apps`
- Texto promocional: usar o campo `Texto promocional`.
- Descrição: usar o campo `Descrição`.
- Palavras-chave: `foco,tempo de uso,pausa,espiritualidade,bíblia,devocional,atenção,disciplina,hábitos`
- Marketing URL: `https://applimiar.com.br`
- Política de Privacidade: `https://applimiar.com.br/privacy`
- Suporte: `https://applimiar.com.br/support`
- Termos: `https://applimiar.com.br/terms`

## Screenshots

Usar os arquivos:

1. Pausa consciente: `app-store/01-pausa-antes-do-impulso.png`
2. Leitura com propósito: `app-store/02-leitura-com-proposito.png`
3. Tempo de Uso: `app-store/03-protecao-nativa.png`
4. Leitura pessoal: `app-store/04-tradicao-espiritual.png`
5. Continue melhor: `app-store/05-retome-consciente.png`

Todos estão em PNG `1290x2796`.

## Assinaturas

Criar um único grupo:

- Nome do grupo: `Limiar Premium`
- Nome de exibição do grupo: `Limiar Premium`

Produtos:

| Product ID | Nome de referência | Nome exibido | Duração | Preço | Oferta introdutória |
| --- | --- | --- | --- | --- | --- |
| `limiar_premium_monthly` | `Limiar Premium Monthly` | `Limiar Premium Mensal` | 1 mês | R$ 9,90 | 1 semana grátis no Brasil, sem data final |
| `limiar_premium_annual_2026` | `Limiar Premium Anual` | `Limiar Premium Anual` | 1 ano | R$ 89,90 | 1 semana grátis no Brasil, sem data final |
| `limiar_premium_monthly_welcome` | `Limiar Premium Mensal Boas-vindas` | `Limiar Premium Mensal` | 1 mês | **R$ 7,50 confirmado pelo Romeu em 23/08/2026** | 1 semana grátis, somente Brasil, sem data final |

Descrição curta sugerida para os produtos:

- Mensal: `Acesso completo ao Limiar Premium com cobrança mensal.`
- Anual: `Acesso completo ao Limiar Premium com cobrança anual e economia em relação ao plano mensal.`

Na submissão da nova versão, adicionar os produtos de assinatura usados por ela junto com a versão do app. Para a oferta de boas-vindas, fazer isso somente depois de concluir preço, localização, captura e oferta introdutória — e apenas com autorização explícita do Romeu.

Configuração territorial das assinaturas:

- Disponibilidade dos produtos atuais mensal e anual: somente Brasil.
- Preço mensal: R$ 9,90.
- Preço anual: R$ 89,90.
- Oferta introdutória StoreKit atual: teste grátis de 1 semana nos produtos mensal e anual, Brasil, início em 06/08/2026 e sem data final. O produto separado de boas-vindas também fica restrito ao Brasil.

### Oferta de boas-vindas após cancelamento

- Produto novo e separado: `limiar_premium_monthly_welcome`.
- Mesmo grupo e mesmo nível de serviço de `limiar_premium_monthly`; período de 1 mês.
- Produto criado em 23/08/2026 no grupo `Limiar Premium`, Apple ID `6804473230`, no mesmo nível do mensal normal. Status atual: `Preparar para envio`; não foi adicionado para revisão.
- Localização pt-BR: nome `Limiar Premium Mensal`; descrição salva `Acesso completo ao Limiar. Mensal pelo preço do anual.`. O texto originalmente proposto excedia em 34 caracteres o limite de 55 caracteres do App Store Connect.
- Preço Brasil: o price point oficial mais próximo de `R$ 89,90 ÷ 12` é **R$ 7,50**, confirmado pelo Romeu em 23/08/2026.
- Disponibilidade e oferta introdutória do produto de boas-vindas: somente Brasil (1 de 175 territórios), teste grátis na primeira semana com início em 23/08/2026 e sem data final. Isso não altera os dois produtos existentes.
- O produto não é apresentado em nenhum seletor público do app; só é alcançável pelo código depois do primeiro cancelamento do portão.
- Captura de revisão: pendente. O simulador iOS 26.5 ficou preso no `00LaunchServicesMigrator` após o reset e não concluiu a instalação. Gerar com `-LimiarForceSubscriptionGate -LimiarGateTrialEligible -LimiarForceGateRecovery -LimiarForceWelcomeOffer` depois que os três produtos carregarem.
- Notas ao revisor salvas no produto em 23/08/2026: `Esta assinatura é uma oferta única de boas-vindas exibida somente após o usuário cancelar a primeira tentativa de compra no portão. Ela não pode ser aberta pela loja nem pelos seletores normais do aplicativo.`
- Não alterar os produtos mensal e anual existentes. Não enviar o produto ou a versão para revisão sem confirmação explícita do Romeu.

## Review notes

Usar este texto em `App Review Notes` (incluindo a oferta somente depois que o novo produto estiver configurado e a submissão tiver sido autorizada):

```text
O Limiar usa recursos nativos do iOS relacionados ao Tempo de Uso para criar pausas escolhidas pelo usuário antes de apps selecionados. As reflexões são para meditação pessoal e não substituem aconselhamento religioso ou profissional.

Depois do onboarding, usuários novos encontram um portão de assinatura sem opção de pular. Clientes elegíveis podem iniciar 7 dias grátis no plano mensal ou anual; durante o teste, o entitlement ativo libera o dashboard. Sem entitlement, usuários novos voltam ao portão. Usuários legados preservam o fluxo anterior, inclusive o Modo Essencial.

Para testar a assinatura, escolha o plano mensal ou anual no portão ou toque em "Restaurar compras".

O produto `limiar_premium_monthly_welcome` é uma oferta única de boas-vindas exibida somente após o usuário cancelar a primeira tentativa de compra no portão. Ele não pode ser aberto pela loja nem pelos seletores normais do aplicativo.

Se o revisor não conseguir conceder Tempo de Uso no dispositivo de teste, ele pode tocar em "Fazer isso depois" no onboarding. O portão de assinatura continuará acessível, e a autorização de Tempo de Uso poderá ser feita depois em Configurações.

Recursos Premium: reflexões completas, narração, personalização contínua por tradição/temas/livros, histórico, baixa repetição de leituras e experiência completa do Limiar.
```

## App Privacy

Declaração conferida para a versão 1.13:

- Tracking: sim.
- Dados usados para rastrear o usuário: `Identifiers`, `Usage Data` e `Advertising Data`; a ficha publicada também marca `Purchase History` para rastreamento.
- A versão 1.13 não adiciona novas categorias de coleta; confirmar que a ficha preserva essas declarações antes da submissão.
- A URL da política ainda aparece no App Store Connect como `https://limiar-five.vercel.app/privacy.html`; atualizar para `https://applimiar.com.br/privacy` ao criar a versão 1.13.
- Dados sensíveis, saúde, financeiro, localização precisa, contatos, fotos, áudio, conteúdo do usuário e histórico de navegação: não declarar, salvo se algum recurso futuro passar a coletar isso.

O app usa UserDefaults/local storage para preferências, histórico local e estado de assinatura. As seleções de apps via Screen Time permanecem no dispositivo e não são usadas para publicidade ou medição.

## Age Rating

Resposta sugerida:

- Sem violência.
- Sem conteúdo sexual.
- Sem jogos de azar.
- Sem compras fora do app.
- Sem acesso irrestrito à web.
- Sem conteúdo médico.
- Conteúdo religioso/espiritual: leve, voltado a meditação pessoal.

## Export Compliance

Resposta sugerida:

- O app usa HTTPS/infraestrutura padrão do sistema e APIs da Apple.
- Não implementa criptografia proprietária.
- Não é app de segurança, VPN, mensageria criptografada, armazenamento criptografado independente ou similar.

Confirmar no App Store Connect conforme as perguntas exatas exibidas no momento da submissão.

## Banking, Tax and Agreements

Antes de vender assinatura:

- Account Holder deve aceitar o acordo de apps pagos em App Store Connect.
- Preencher dados bancários pessoais.
- Preencher dados fiscais pessoais exigidos pela Apple para pessoa física.
- Confirmar que `Paid Apps` está ativo.
- Confirmar que o banco informado recebe pagamentos da Apple.

Sem isso, o app pode até ser preparado, mas não fica livre para vender assinatura.

## Próximos passos no App Store Connect

1. Depois da autorização de release, aguardar a build `1.13` do Xcode Cloud terminar o processamento no App Store Connect.
2. Selecionar a build `23` na versão iOS `1.0`.
3. Conferir distribuição pública somente para Brasil.
4. Conferir disponibilidade das assinaturas somente para Brasil.
5. Aceitar Paid Apps Agreement e preencher banco/impostos como pessoa física.
6. Testar assinatura mensal no Sandbox/TestFlight.
7. Conferir App Privacy, classificação etária, export compliance e review notes.
8. Enviar app e assinaturas juntos para revisão.
