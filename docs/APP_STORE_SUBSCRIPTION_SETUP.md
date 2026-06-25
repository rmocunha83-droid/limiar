# Limiar Premium - App Store Connect

## Modelo

- App gratuito para baixar.
- Assinatura auto-renovável em um único grupo chamado `Limiar Premium`.
- Sem plano semanal.
- Comercialização inicial somente no Brasil.
- Conta comercial como pessoa física do Account Holder.
- Teste gratuito de 7 dias liberado pelo próprio app antes de qualquer compra.
- Oferta introdutória StoreKit opcional: não configurada por padrão. Se for criada no App Store Connect, o app só deve mostrar essa oferta quando o StoreKit retornar a informação.

## Produtos

| Produto | Tipo | Preço | Oferta introdutória |
| --- | --- | --- | --- |
| `limiar_premium_monthly` | Mensal | R$ 9,90/mês | Não configurada por padrão |

Para o lançamento comercial simples, envie somente o produto mensal. Um produto anual pode ser criado depois, se a estratégia comercial pedir uma oferta de melhor valor.

Na primeira submissão, inclua a assinatura mensal junto com uma nova versão do app em App Store Connect. A Apple revisa o app e a assinatura como parte da mesma submissão inicial.

Disponibilidade dos produtos:

- País/região: Brasil.
- Não disponibilizar em outros países/regiões neste lançamento.

## Fluxo no app

1. Usuário abre o app.
2. Passa pelo onboarding.
3. Escolhe tradição espiritual, preferências e apps que ativam o Limiar.
4. Inicia 7 dias grátis com experiência completa.
5. Durante o teste, usa IA, narração e maior variedade de trechos.
6. Depois do teste, se não assinar, entra no Modo Essencial.
7. Toca em `Ver planos` ou `Assinar Premium`.
8. Vê o paywall com mensal, restauração, termos e privacidade.
9. Ao assinar, o app libera recursos Premium.

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

- Marketing: `https://limiar-five.vercel.app/`
- Termos de Uso: `https://limiar-five.vercel.app/terms.html`
- Política de Privacidade: `https://limiar-five.vercel.app/privacy.html`
- Suporte: `https://limiar-five.vercel.app/support.html`

## Notas para revisão

Depois do onboarding, o usuário inicia 7 dias grátis com experiência completa. Para testar a assinatura, toque em `Ver planos` ou `Assinar Premium` e escolha o plano mensal disponível no StoreKit.

Se o revisor não conseguir conceder Tempo de Uso no dispositivo de teste, ele pode tocar em `Fazer isso depois` no onboarding. O teste gratuito e o paywall continuarão acessíveis, e a autorização de Tempo de Uso poderá ser feita depois em Configurações.

## Estado de distribuição

Build `1.0 (22)` foi exportada e enviada ao App Store Connect com sucesso. O pacote de distribuição inclui `com.apple.developer.family-controls` no app principal.

O app usa recursos nativos do Tempo de Uso para aplicar bloqueios escolhidos pelo usuário. As reflexões são para meditação pessoal e não substituem aconselhamento religioso, pastoral, rabínico, psicológico ou médico.

Antes de enviar para revisão, confirme no Sandbox e no TestFlight:

- Produtos retornam corretamente pelo StoreKit.
- Se for configurada oferta introdutória, o teste grátis aparece somente nos produtos que retornarem essa informação pelo StoreKit.
- Alterações de metadados dos produtos já propagaram para o Sandbox.
- Compra libera Premium imediatamente.
- Restauração funciona.
- Cancelamento/expiração leva o usuário ao Modo Essencial.
- Links de Termos, Privacidade e Suporte estão publicados e acessíveis.

## Teste local no Xcode

Crie uma configuração StoreKit local pelo Xcode:

1. File > New > File.
2. Escolha `StoreKit Configuration File`.
3. Nomeie como `Limiar.storekit`.
4. Adicione um grupo `Limiar Premium`.
5. Adicione `limiar_premium_monthly` como assinatura mensal.
6. Opcionalmente, configure oferta introdutória gratuita de 7 dias no produto mensal.
7. No scheme `Limiar`, vá em Run > Options > StoreKit Configuration e selecione `Limiar.storekit`.

Depois disso, rode no simulador e teste compra, restauração, expiração e renovação acelerada pelo Transaction Manager do Xcode.
