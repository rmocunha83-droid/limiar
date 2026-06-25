# Roteiro tela por tela - App Store Connect

Use este roteiro depois que estiver logado no App Store Connect.

Objetivo: publicar o Limiar na App Store somente no Brasil, com assinatura mensal de R$ 9,90, comercializado pela pessoa física do Account Holder.

## Ordem recomendada

1. Contratos, banco e impostos.
2. Verificar build `1.0 (23)`.
3. Criar/confirmar assinatura mensal.
4. Configurar disponibilidade Brasil.
5. Preencher página da versão.
6. Preencher privacidade/compliance.
7. Enviar app e assinatura juntos para revisão.

## 1. Business / Agreements, Tax, and Banking

Onde ir:

- `Business`
- ou `Agreements, Tax, and Banking`

O que confirmar:

- `Paid Apps Agreement`: ativo.
- Dados bancários: preenchidos.
- Dados fiscais: preenchidos para pessoa física.

Se algum item estiver pendente, resolva antes de enviar para revisão. Sem isso, a assinatura pode ficar indisponível para venda.

## 2. Apps > Limiar > TestFlight

Onde ir:

- `Apps`
- `Limiar`
- `TestFlight`

O que procurar:

- Build `1.0 (23)`.

Estados esperados:

- Se aparecer `Processing`, aguarde.
- Se aparecer disponível para teste, prossiga.

Se quiser testar internamente:

- Adicione a build a um grupo de teste interno.
- Instale pelo TestFlight.
- Abra o app e confira onboarding, teste grátis e paywall mensal.

## 3. Apps > Limiar > Subscriptions / In-App Purchases

Criar grupo:

- Reference Name: `Limiar Premium`
- Display Name: `Limiar Premium`

Criar produto mensal:

- Product ID: `limiar_premium_monthly`
- Reference Name: `Limiar Premium Monthly`
- Display Name: `Limiar Premium Mensal`
- Type: auto-renewable subscription
- Duration: `1 Month`
- Price: `R$ 9,90`
- Availability: somente `Brazil`
- Review screenshot: usar um print do paywall, se a Apple pedir.

Descrição do produto:

```text
Acesso completo ao Limiar Premium com cobrança mensal.
```

Não criar plano anual no lançamento inicial.

## 4. Apps > Limiar > Pricing and Availability

Configurar:

- Distribution method: pública na App Store.
- App price: gratuito.
- App availability: somente `Brazil`.
- Novos países/regiões adicionados automaticamente: desativado, se a opção aparecer.

Conferência:

- Nenhum outro país selecionado.
- Brasil selecionado.

## 5. Apps > Limiar > iOS App 1.0

Selecionar build:

- Build: `1.0 (23)`

Metadados:

- Nome: `Limiar`
- Subtítulo: `Pausa espiritual antes de apps`
- Texto promocional:

```text
Crie uma pausa antes de abrir apps que puxam sua atenção. Leia uma jornada com trechos e explicações espirituais, conclua com calma e retome o uso com mais presença.
```

- Palavras-chave:

```text
foco,tempo de uso,pausa,espiritualidade,bíblia,devocional,atenção,disciplina,hábitos
```

- Descrição: usar `app-store/submission-ready-2026-06-25/01-metadados-app.md`.

URLs:

- Marketing URL: `https://limiar-five.vercel.app/`
- Privacy Policy URL: `https://limiar-five.vercel.app/privacy.html`
- Support URL: `https://limiar-five.vercel.app/support.html`

Categorias:

- Primária: `Produtividade`
- Secundária: `Estilo de vida`

Screenshots:

- iPhone 6.7": usar `app-store/upload-ready/`.
- iPhone 6.5": usar `app-store/upload-ready-6.5/`, se a Apple pedir.

## 6. App Privacy

Responder:

- Tracking: `Não`.
- IDFA: `Não`.
- Dados usados para rastrear: `Não`.
- Dados vinculados à identidade: `Não`.

Se precisar declarar dados para a geração por IA:

- Categoria: `Other Data Types`.
- Uso: `App Functionality`.
- Vinculado à identidade: `Não`.
- Usado para tracking: `Não`.

Justificativa resumida:

```text
O app pode enviar ao backend apenas preferências espirituais e contexto mínimo para gerar reflexões, como tradição, temas, livros/seções e profundidade. O app não envia seleção dos apps que ativam o Limiar, email, contatos, localização precisa ou dados de publicidade.
```

## 7. Age Rating

Responder de forma conservadora:

- Violência: nenhuma.
- Conteúdo sexual: nenhum.
- Jogos de azar: não.
- Acesso irrestrito à web: não.
- Conteúdo médico: não.
- Compras fora do app: não.
- Conteúdo religioso/espiritual: leve, voltado a meditação pessoal.

## 8. Export Compliance

Resposta sugerida:

- O app usa HTTPS e APIs padrão do sistema.
- Não implementa criptografia proprietária.
- Não é app de VPN, segurança, mensageria criptografada ou armazenamento criptografado independente.

Responder conforme as opções exatas exibidas pela Apple.

## 9. App Review Notes

Cole o texto de:

- `app-store/submission-ready-2026-06-25/03-review-notes.txt`

## 10. In-App Purchases na versão

Antes de enviar:

- Confirme que `limiar_premium_monthly` foi adicionado à submissão da versão.
- Envie app e assinatura juntos para revisão.

## 11. Enviar para revisão

Antes do botão final:

- Build `1.0 (23)` selecionada.
- Produto mensal incluído.
- Brasil como único país.
- Screenshots enviados.
- App Privacy preenchido.
- Age Rating preenchido.
- Export Compliance preenchido.
- Review Notes coladas.
- Paid Apps Agreement ativo.
- Banco/impostos preenchidos.

Se tudo estiver completo, envie para revisão.
