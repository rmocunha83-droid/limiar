# App Store Server Notifications V2

O backend do Limiar aceita notificações assinadas da App Store, verifica a cadeia de certificados com a biblioteca oficial da Apple e persiste apenas campos operacionais mínimos. Identificadores brutos de transação e o `signedPayload` não são armazenados.

## Rotas

- `POST /api/app-store-notifications`: destino das notificações V2 da Apple.
- `GET /api/subscription-funnel`: resumo privado do ciclo de assinatura.
- `/subscription-funnel.html`: visualização privada do resumo.

## Variáveis de ambiente

- `APPLE_ROOT_CA_BASE64_JSON`: array JSON com os certificados raiz oficiais da Apple, em DER codificado em base64.
- `SUBSCRIPTION_EVENT_HASH_SECRET`: segredo usado para pseudonimizar a assinatura original antes do armazenamento.
- `SUBSCRIPTION_DASHBOARD_TOKEN`: token Bearer exigido pela API e pela página privada.
- `BLOB_READ_WRITE_TOKEN`: token de um Vercel Blob privado.

Os três segredos devem ser diferentes, gerados aleatoriamente e mantidos somente no gerenciador de variáveis do ambiente. Não registrar seus valores em logs, código ou documentação.

## Ativação

1. Publicar as rotas e confirmar que `POST /api/app-store-notifications` responde sem expor dados internos.
2. Configurar as variáveis nos ambientes Production e Preview aplicáveis.
3. No App Store Connect, cadastrar a URL de produção `https://applimiar.com.br/api/app-store-notifications` em App Store Server Notifications V2.
4. Enviar uma notificação de teste pelo App Store Connect e confirmar a gravação de um registro verificado.
5. Abrir `/subscription-funnel.html`, informar o token privado e conferir os totais agregados.

Não cadastrar a URL no App Store Connect antes de a rota estar publicada e validada: respostas não processadas fazem a Apple tentar novamente.

## Métricas disponíveis

- testes grátis iniciados;
- testes convertidos em assinatura paga;
- taxa de conversão verificada por assinatura pseudonimizada;
- renovações desativadas;
- expirações;
- reembolsos.

Essas métricas representam eventos de servidor confirmados pela Apple. Elas não substituem os eventos de comportamento do Firebase; os dois conjuntos devem ser comparados como fontes complementares.

## BigQuery

A exportação Firebase/Google Analytics para BigQuery deve ser habilitada somente depois de confirmar projeto, região, retenção e faturamento. O vínculo é uma etapa externa separada desta implementação e pode gerar cobrança conforme armazenamento e consultas.
