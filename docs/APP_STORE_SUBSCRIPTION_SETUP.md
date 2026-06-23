# Limiar Premium - App Store Connect

## Modelo

- App gratuito para baixar.
- Assinatura auto-renovável em um único grupo chamado `Limiar Premium`.
- Sem plano semanal.
- Oferta introdutória opcional: o app só mostra teste grátis quando o StoreKit retornar essa oferta como configurada no App Store Connect.

## Produtos

| Produto | Tipo | Preço | Oferta introdutória |
| --- | --- | --- | --- |
| `limiar_premium_monthly` | Mensal | R$ 9,90/mês | Não configurada por padrão |
| `limiar_premium_yearly` | Anual | R$ 79,90/ano | Não configurada por padrão |

O app destaca o anual como melhor oferta e mantém o mensal visível.

Na primeira submissão, inclua as duas assinaturas junto com uma nova versão do app em App Store Connect. A Apple revisa o app e as assinaturas como parte da mesma submissão inicial.

## Fluxo no app

1. Usuário abre o app.
2. Passa pelo onboarding.
3. Escolhe tradição espiritual, preferências, APPs protegidos e tempo de liberação.
4. Vê uma primeira leitura demonstrativa gratuita.
5. Toca em `Ver Limiar Premium`.
6. Vê o paywall com mensal, anual, restauração, termos e privacidade. Se houver oferta introdutória configurada, o teste grátis aparece automaticamente.
7. Ao assinar, o app libera recursos Premium.

## Recursos Premium

- Geração completa de reflexões espirituais por IA.
- Personalização contínua por religião ou tradição espiritual.
- Escolha de temas espirituais.
- Escolha de livros ou seções preferidas.
- Escolha do tamanho da reflexão.
- Histórico de leituras.
- Geração de novas leituras com baixa repetição.
- Configuração do tempo de liberação dos APPs bloqueados.
- Uso completo do fluxo de bloqueio/desbloqueio com leitura espiritual.

## URLs

- Marketing: `https://limiar-five.vercel.app/`
- Termos de Uso: `https://limiar-five.vercel.app/terms.html`
- Política de Privacidade: `https://limiar-five.vercel.app/privacy.html`
- Suporte: `https://limiar-five.vercel.app/support.html`

## Notas para revisão

O paywall aparece depois do onboarding e depois de uma primeira leitura demonstrativa. Para testar, conclua o onboarding, veja a primeira pausa, toque em `Ver Limiar Premium` e escolha o plano mensal ou anual.

Se o revisor não conseguir conceder Tempo de Uso no dispositivo de teste, ele pode tocar em `Continuar sem autorizar agora` no onboarding. O paywall continuará acessível depois da primeira leitura demonstrativa, e a autorização de Tempo de Uso poderá ser feita depois em Configurações.

## Bloqueio atual de distribuição

O app compila e arquiva, mas a exportação para App Store falha enquanto a Apple não conceder Family Controls para distribuição. Ver:

- `docs/FAMILY_CONTROLS_DISTRIBUTION_REQUEST.md`

O app usa recursos nativos do Tempo de Uso para aplicar bloqueios escolhidos pelo usuário. As reflexões são para meditação pessoal e não substituem aconselhamento religioso, pastoral, rabínico, psicológico ou médico.

Antes de enviar para revisão, confirme no Sandbox e no TestFlight:

- Produtos retornam corretamente pelo StoreKit.
- Se for configurada oferta introdutória, o teste grátis aparece somente nos produtos que retornarem essa informação pelo StoreKit.
- Alterações de metadados dos produtos já propagaram para o Sandbox.
- Compra libera Premium imediatamente.
- Restauração funciona.
- Cancelamento/expiração bloqueia recursos Premium.
- Links de Termos, Privacidade e Suporte estão publicados e acessíveis.

## Teste local no Xcode

Crie uma configuração StoreKit local pelo Xcode:

1. File > New > File.
2. Escolha `StoreKit Configuration File`.
3. Nomeie como `Limiar.storekit`.
4. Adicione um grupo `Limiar Premium`.
5. Adicione `limiar_premium_monthly` como assinatura mensal.
6. Adicione `limiar_premium_yearly` como assinatura anual.
7. Opcionalmente, configure oferta introdutória gratuita de 7 dias nos dois produtos.
8. No scheme `Limiar`, vá em Run > Options > StoreKit Configuration e selecione `Limiar.storekit`.

Depois disso, rode no simulador e teste compra, restauração, expiração e renovação acelerada pelo Transaction Manager do Xcode.
