# Limiar - Checklist de App Store Connect

## Estado atual

- App compila em Debug.
- App compila em Release para iOS.
- Archive foi criado com sucesso.
- Export para App Store está bloqueado até a Apple liberar `com.apple.developer.family-controls` para distribuição.
- Conta do Xcode em uso: `Romeu Cunha - L38WCHAWJ9`.
- Bundle ID principal: `com.romeucunha.Limiar`.
- App limitado a iPhone (`TARGETED_DEVICE_FAMILY = 1`).
- Screenshots disponíveis em `app-store/`, tamanho `1290x2796`, aceito pela Apple para iPhone 6.9".
- Ícone disponível em `Limiar/Assets.xcassets/AppIcon.appiconset/app-icon.png`, tamanho `1024x1024`.

## Bloqueio externo

Enviar e aguardar aprovação do pedido:

https://developer.apple.com/contact/request/family-controls-distribution

Na tela atual da Apple, não há campo de justificativa. O fluxo simplificado mostra dados da conta, termos e botão `Get Entitlement`. A justificativa em `docs/FAMILY_CONTROLS_DISTRIBUTION_REQUEST.md` fica pronta para eventual follow-up da Apple.

## App record

- Nome: `Limiar`
- Bundle ID: `com.romeucunha.Limiar`
- SKU sugerido: `limiar-ios-001`
- Plataforma: iOS
- Categoria primária: `Productivity`
- Categoria secundária sugerida: `Lifestyle`
- Preço do app: gratuito
- Disponibilidade: Brasil primeiro, depois expandir se desejado.

## Metadados em português

Fonte principal:

- `app-store/app-store-copy.md`

Campos:

- Nome: `Limiar`
- Subtítulo: `Pausa espiritual antes dos APPs`
- Texto promocional: usar o campo `Texto promocional`.
- Descrição: usar o campo `Descrição`.
- Palavras-chave: `foco,tempo de uso,bloqueio,espiritualidade,bíblia,devocional,atenção,disciplina,hábitos`
- Marketing URL: `https://limiar-five.vercel.app/`
- Política de Privacidade: `https://limiar-five.vercel.app/privacy.html`
- Suporte: `https://limiar-five.vercel.app/support.html`
- Termos: `https://limiar-five.vercel.app/terms.html`

## Screenshots

Usar os arquivos:

1. `app-store/01-pausa-antes-do-impulso.png`
2. `app-store/02-leitura-com-proposito.png`
3. `app-store/03-protecao-nativa.png`
4. `app-store/04-tradicao-espiritual.png`
5. `app-store/05-retome-consciente.png`

Todos estão em PNG `1290x2796`.

## Assinaturas

Criar um único grupo:

- Nome do grupo: `Limiar Premium`
- Nome de exibição do grupo: `Limiar Premium`

Produtos:

| Product ID | Nome de referência | Nome exibido | Duração | Preço | Oferta introdutória |
| --- | --- | --- | --- | --- | --- |
| `limiar_premium_monthly` | `Limiar Premium Monthly` | `Limiar Premium Mensal` | 1 mês | R$ 9,90 | Não configurada por padrão |
| `limiar_premium_yearly` | `Limiar Premium Yearly` | `Limiar Premium Anual` | 1 ano | R$ 79,90 | Não configurada por padrão |

Descrição curta sugerida para os produtos:

- Mensal: `Acesso completo ao Limiar Premium com cobrança mensal.`
- Anual: `Acesso completo ao Limiar Premium com cobrança anual.`

Na primeira submissão, adicionar as duas assinaturas junto com a versão inicial do app.

## Review notes

Usar este texto em `App Review Notes`:

```text
O Limiar usa recursos nativos do iOS relacionados ao Tempo de Uso para aplicar bloqueios escolhidos pelo usuário. As reflexões são para meditação pessoal e não substituem aconselhamento religioso ou profissional.

O paywall aparece depois do onboarding e depois de uma primeira leitura demonstrativa. Para testar: conclua o onboarding, veja a primeira pausa demonstrativa, toque em "Ver Limiar Premium" e escolha o plano mensal ou anual.

Se o revisor não conseguir conceder Tempo de Uso no dispositivo de teste, ele pode tocar em "Continuar sem autorizar agora" no onboarding. O paywall continuará acessível depois da primeira leitura demonstrativa, e a autorização de Tempo de Uso poderá ser feita depois em Configurações.

Recursos pagos: geração completa por IA, personalização contínua por tradição/temas/livros, histórico, baixa repetição de leituras, configuração completa do tempo de liberação e uso completo do fluxo de bloqueio/desbloqueio.
```

## App Privacy

Declaração sugerida com base no app atual:

- Tracking: não.
- Dados usados para rastrear o usuário: não.
- Dados vinculados à identidade do usuário: não.
- Dados coletados: `Other Data Types`, finalidade `App Functionality`, não vinculado à identidade.
- Dados sensíveis, saúde, financeiro, localização precisa, contatos, fotos, áudio, conteúdo do usuário, histórico de navegação: não declarar, salvo se algum recurso novo passar a coletar isso.

O app usa UserDefaults/local storage para preferências, histórico local e estado de assinatura. As seleções de APPs via Screen Time devem permanecer no dispositivo e não ser vendidas ou compartilhadas.

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

- Aceitar o acordo de apps pagos em App Store Connect.
- Preencher dados bancários.
- Preencher dados fiscais.
- Confirmar que `Paid Apps` está ativo.

Sem isso, o app pode até ser preparado, mas não fica livre para vender assinatura.

## Depois da aprovação de Family Controls

1. Abrir Certificates, Identifiers & Profiles.
2. Conferir `com.romeucunha.Limiar`.
3. Habilitar Family Controls Distribution.
4. Conferir se as extensões também precisam do entitlement:
   - `com.romeucunha.Limiar.ShieldConfigurationExtension`
   - `com.romeucunha.Limiar.ShieldActionExtension`
   - `com.romeucunha.Limiar.DeviceActivityMonitorExtension`
5. Regerar perfis de App Store.
6. Rodar export novamente.
7. Upload para App Store Connect.
8. Testar assinaturas no Sandbox/TestFlight.
9. Enviar app e assinaturas juntos para revisão.
