# Limiar Premium - App Store Connect

## Modelo

- App gratuito para baixar.
- Assinatura auto-renovável em um único grupo chamado `Limiar Premium`.
- Sem plano semanal.
- Comercialização inicial somente no Brasil.
- Conta comercial como pessoa física do Account Holder.
- Para usuários novos, o teste gratuito de 7 dias é uma oferta introdutória do StoreKit e exige início de assinatura.
- Usuários legados preservam o trial local anterior e o Modo Essencial.

## Produtos

| Produto | Tipo | Preço | Oferta introdutória |
| --- | --- | --- | --- |
| `limiar_premium_monthly` | Mensal | R$ 9,90/mês | 1 semana grátis no Brasil, sem data final |
| `limiar_premium_annual_2026` | Anual | R$ 89,90/ano | 1 semana grátis no Brasil, sem data final |

Para a estratégia atual, mantenha os dois produtos no mesmo grupo de assinatura `Limiar Premium`. O plano anual deve aparecer como melhor oferta, com economia em relação ao plano mensal.

Na submissão da nova versão, inclua a assinatura mensal e a anual junto com o app em App Store Connect. A Apple revisa o app e as assinaturas como parte da mesma submissão.

Disponibilidade dos produtos:

- País/região: Brasil.
- Não disponibilizar em outros países/regiões neste lançamento.

## Fluxo no app

1. Usuário abre o app.
2. Passa pelo onboarding.
3. Escolhe tradição espiritual, preferências e apps que ativam o Limiar.
4. Se for novo e não tiver entitlement ativo, encontra o portão obrigatório de assinatura.
5. Escolhe o plano mensal ou anual; se elegível, vê e inicia 7 dias grátis pelo StoreKit.
6. Durante o teste, o entitlement ativo libera IA, narração e a experiência completa.
7. Ao expirar ou ser reembolsado, volta ao portão sem Modo Essencial ou anúncios.
8. Se for legado, preserva o trial local, funil e Modo Essencial anteriores.

## Recursos Premium

- Geração completa de reflexões espirituais por IA.
- Personalização contínua por religião ou tradição espiritual.
- Escolha de temas espirituais.
- Escolha de livros ou seções preferidas.
- Escolha do tamanho da reflexão.
- Histórico de leituras.
- Geração de novas leituras com baixa repetição.
- Narração dos trechos.
- Experiência completa do fluxo de pausa com leitura espiritual.

## URLs

- Marketing: `https://applimiar.com.br`
- Termos de Uso: `https://applimiar.com.br/terms`
- Política de Privacidade: `https://applimiar.com.br/privacy`
- Suporte: `https://applimiar.com.br/support`

## Notas para revisão

Depois do onboarding, usuários novos encontram o portão de assinatura. Para testar, escolha o plano mensal ou anual ou use `Restaurar compras`. O teste de 7 dias aparece somente para contas elegíveis, conforme o StoreKit.

Se o revisor não conseguir conceder Tempo de Uso no dispositivo de teste, ele pode tocar em `Fazer isso depois` no onboarding. O portão continuará acessível, e a autorização de Tempo de Uso poderá ser feita depois em Configurações.

## Estado de distribuição

A versão local está em `1.13`; o envio deve ocorrer somente após autorização explícita, usando a build gerada pelo Xcode Cloud. O pacote de distribuição precisa preservar `com.apple.developer.family-controls` no app principal.

O app usa recursos nativos do Tempo de Uso para criar pausas escolhidas pelo usuário antes dos apps selecionados. As reflexões são para meditação pessoal e não substituem aconselhamento religioso, pastoral, rabínico, psicológico ou médico.

Antes de enviar para revisão, confirme no Sandbox e no TestFlight:

- Produtos retornam corretamente pelo StoreKit.
- O teste grátis aparece somente nos produtos com oferta confirmada de exatamente 7 dias e para contas elegíveis segundo o StoreKit.
- Alterações de metadados dos produtos já propagaram para o Sandbox.
- Compra libera Premium imediatamente.
- Restauração funciona.
- Cancelamento mantém acesso até o fim do entitlement; expiração leva usuários novos ao portão e legados ao fluxo anterior.
- Links de Termos, Privacidade e Suporte estão publicados e acessíveis.

## Teste local no Xcode

Crie uma configuração StoreKit local pelo Xcode:

1. File > New > File.
2. Escolha `StoreKit Configuration File`.
3. Nomeie como `Limiar.storekit`.
4. Adicione um grupo `Limiar Premium`.
5. Adicione `limiar_premium_monthly` como assinatura mensal.
6. Adicione `limiar_premium_annual_2026` como assinatura anual.
7. Configure oferta introdutória gratuita de 7 dias nos dois produtos.
8. No scheme `Limiar`, vá em Run > Options > StoreKit Configuration e selecione `Limiar.storekit`.

Depois disso, rode no simulador e teste compra, restauração, expiração e renovação acelerada pelo Transaction Manager do Xcode.
