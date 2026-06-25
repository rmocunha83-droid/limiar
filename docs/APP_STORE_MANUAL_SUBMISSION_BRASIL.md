# Guia manual de submissão App Store - Limiar Brasil

Última atualização: 25/06/2026.

Este guia consolida o que falta fazer no App Store Connect para vender o Limiar no Brasil como pessoa física. Ele usa o estado atual do projeto, do site e da build enviada ao TestFlight.

## Estado atual comprovado

- Repositório GitHub: `main` estava atualizado até `208444c` no início desta checagem.
- Site público: `https://limiar-five.vercel.app/`.
- Build enviada à Apple: `1.0 (23)`.
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

## 3. Assinatura mensal

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

Não criar nem enviar plano anual no lançamento inicial. O plano anual pode ser criado depois, se a estratégia comercial mudar.

Sobre teste gratuito: o teste de 7 dias atual é uma experiência interna do app antes da compra. Não configure oferta introdutória StoreKit agora, salvo decisão posterior de produto.

## 4. Build para selecionar

Na versão iOS `1.0`, selecione:

- Build: `1.0 (23)`

Se a build ainda aparecer como processando, aguarde o processamento terminar no App Store Connect/TestFlight.

## 5. Metadados da App Store

Use como fonte:

- `app-store/app-store-copy.md`
- `app-store/app-store-connect-fields.md`

Campos principais:

- Nome: `Limiar`
- Subtítulo: `Pausa espiritual antes dos apps`
- Palavras-chave: `foco,tempo de uso,pausa,espiritualidade,bíblia,devocional,atenção,disciplina,hábitos`
- Marketing URL: `https://limiar-five.vercel.app/`
- Política de Privacidade: `https://limiar-five.vercel.app/privacy.html`
- Suporte: `https://limiar-five.vercel.app/support.html`
- Termos: `https://limiar-five.vercel.app/terms.html`

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

Depois do onboarding, o usuário inicia 7 dias grátis com experiência completa. Se o teste terminar sem assinatura, o app entra no Modo Essencial: mantém os 3 trechos principais e o fluxo de pausa, mas sem narração, reflexões por IA e maior variedade.

Para testar a assinatura, toque em "Ver planos" ou "Assinar Premium" e escolha o plano mensal disponível no StoreKit.

Se o revisor não conseguir conceder Tempo de Uso no dispositivo de teste, ele pode tocar em "Fazer isso depois" no onboarding. O teste gratuito e o paywall continuarão acessíveis, e a autorização de Tempo de Uso poderá ser feita depois em Configurações.

Recursos Premium: geração completa por IA, narração, personalização contínua por tradição/temas/livros, histórico, baixa repetição de leituras e experiência completa do Limiar.
```

## 10. Antes de enviar para revisão

Checklist final:

- Paid Apps Agreement ativo.
- Dados bancários e fiscais preenchidos.
- App disponível somente no Brasil.
- Assinatura mensal disponível somente no Brasil.
- Produto `limiar_premium_monthly` em estado pronto para submissão.
- Build `1.0 (23)` selecionada.
- Assinatura mensal selecionada na seção de In-App Purchases/Subscriptions da versão.
- App Privacy preenchido.
- Age Rating preenchido.
- Export Compliance respondido.
- Screenshots enviados.
- URLs de suporte, privacidade e termos abrindo corretamente.
- TestFlight/Sandbox validado com teste grátis, paywall, assinatura, restauração e Modo Essencial.

## Status

O projeto está tecnicamente pronto para submissão, mas a venda pública ainda depende das ações manuais acima no App Store Connect.
