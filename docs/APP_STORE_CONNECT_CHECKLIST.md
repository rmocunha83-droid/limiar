# Limiar - Checklist de App Store Connect

## Estado atual

- App compila em Debug.
- App compila em Release para iOS.
- Archive foi criado com sucesso.
- Export para App Store foi concluído com assinatura de distribuição.
- Upload para App Store Connect/TestFlight concluído com sucesso na build `1.0 (23)`.
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
- Marketing URL: `https://limiar-five.vercel.app/`
- Política de Privacidade: `https://limiar-five.vercel.app/privacy.html`
- Suporte: `https://limiar-five.vercel.app/support.html`
- Termos: `https://limiar-five.vercel.app/terms.html`

## Screenshots

Usar os arquivos:

1. Pausa consciente: `app-store/01-pausa-antes-do-impulso.png`
2. Leitura com IA: `app-store/02-leitura-com-proposito.png`
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
| `limiar_premium_monthly` | `Limiar Premium Monthly` | `Limiar Premium Mensal` | 1 mês | R$ 9,90 | Não configurada por padrão |

Descrição curta sugerida para os produtos:

- Mensal: `Acesso completo ao Limiar Premium com cobrança mensal.`

Na primeira submissão, adicionar a assinatura mensal junto com a versão inicial do app. Um produto anual pode ser criado depois, se a estratégia comercial mudar.

Configuração territorial das assinaturas:

- Disponibilidade: somente Brasil.
- Preço mensal: R$ 9,90.
- Oferta introdutória StoreKit: não configurada por padrão. O teste de 7 dias atual é liberado dentro do app antes de qualquer compra.

## Review notes

Usar este texto em `App Review Notes`:

```text
O Limiar usa recursos nativos do iOS relacionados ao Tempo de Uso para criar pausas escolhidas pelo usuário antes de apps selecionados. As reflexões são para meditação pessoal e não substituem aconselhamento religioso ou profissional.

Depois do onboarding, o usuário inicia 7 dias grátis com experiência completa. Se o teste terminar sem assinatura, o app entra no Modo Essencial: mantém os 3 trechos principais e o fluxo de pausa, mas sem narração, reflexões por IA e maior variedade.

Para testar a assinatura, toque em "Ver planos" ou "Assinar Premium" e escolha o plano mensal disponível no StoreKit.

Se o revisor não conseguir conceder Tempo de Uso no dispositivo de teste, ele pode tocar em "Fazer isso depois" no onboarding. O teste gratuito e o paywall continuarão acessíveis, e a autorização de Tempo de Uso poderá ser feita depois em Configurações.

Recursos Premium: geração completa por IA, narração, personalização contínua por tradição/temas/livros, histórico, baixa repetição de leituras e experiência completa do Limiar.
```

## App Privacy

Declaração sugerida com base no app atual:

- Tracking: não.
- Dados usados para rastrear o usuário: não.
- Dados vinculados à identidade do usuário: não.
- Dados coletados: `Other Data Types`, finalidade `App Functionality`, não vinculado à identidade.
- Dados sensíveis, saúde, financeiro, localização precisa, contatos, fotos, áudio, conteúdo do usuário, histórico de navegação: não declarar, salvo se algum recurso novo passar a coletar isso.

O app usa UserDefaults/local storage para preferências, histórico local e estado de assinatura. As seleções de apps via Screen Time devem permanecer no dispositivo e não ser vendidas ou compartilhadas.

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

1. Aguardar a build `1.0 (23)` terminar processamento no App Store Connect.
2. Selecionar a build `23` na versão iOS `1.0`.
3. Conferir distribuição pública somente para Brasil.
4. Conferir disponibilidade das assinaturas somente para Brasil.
5. Aceitar Paid Apps Agreement e preencher banco/impostos como pessoa física.
6. Testar assinatura mensal no Sandbox/TestFlight.
7. Conferir App Privacy, classificação etária, export compliance e review notes.
8. Enviar app e assinaturas juntos para revisão.
