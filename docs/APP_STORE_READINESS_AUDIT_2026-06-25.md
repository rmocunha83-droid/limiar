# Auditoria de prontidão App Store - Limiar

Data: 25/06/2026.

Objetivo: publicar o Limiar na App Store, com vendas e distribuição somente no Brasil, comercializado pela pessoa física do Account Holder.

## Resultado resumido

O projeto está tecnicamente preparado e a build `1.0 (23)` foi enviada com sucesso para a Apple/TestFlight.

A venda pública ainda não pode ser considerada concluída porque depende de confirmações manuais no App Store Connect: processamento da build, seleção da build na versão, contrato de apps pagos, banco/impostos, assinatura mensal e envio para revisão.

## Evidências verificadas

| Item | Estado | Evidência |
| --- | --- | --- |
| GitHub atualizado | Pronto | `main` sincronizado com `origin/main`, commit `219d00b` antes desta auditoria. |
| Build enviada à Apple | Pronto | Archive `build/TestFlight/Limiar-1.0-23.xcarchive` registra `Uploaded to Apple`, build `23`, em `2026-06-25T21:41:47Z`. |
| Bundle ID | Pronto | `com.romeucunha.Limiar`. |
| App Apple ID | Pronto | `6783115468`. |
| Versão | Pronto | `1.0`. |
| Build number | Pronto | `23`. |
| Site público | Pronto | `https://limiar-five.vercel.app/` retornou HTTP 200. |
| Política de Privacidade | Pronto | `https://limiar-five.vercel.app/privacy.html` retornou HTTP 200. |
| Termos e suporte | Pronto | URLs publicadas no site e listadas no pacote de submissão. |
| Screenshots 6.7" | Pronto | `app-store/upload-ready/`, arquivos `1290x2796`. |
| Screenshots 6.5" | Pronto | `app-store/upload-ready-6.5/`, arquivos `1284x2778`. |
| Subtítulo | Pronto | `Pausa espiritual antes de apps`, 30 caracteres. |
| Texto promocional | Pronto | 166 caracteres. |
| Palavras-chave | Pronto | 85 caracteres. |
| Descrição | Pronto | 1641 caracteres. |
| Assinatura inicial | Pronto no código | App busca somente `limiar_premium_monthly`. |
| Plano anual | Removido do app | Busca por `limiar_premium_yearly`, `R$ 79,90`, `Melhor oferta` e `Economize no plano anual` não retornou no app. |
| Verificação de processamento via terminal | Preparado | `scripts/check_app_store_build_status.sh` permite consultar a build com App Store Connect API Key, sem versionar credenciais. |
| Distribuição somente Brasil | Preparado | Documentado em `app-store/submission-ready-2026-06-25/` e guias. Precisa ser confirmado na interface da Apple. |
| Comercialização pessoa física | Preparado | Documentado nos guias. Precisa de Paid Apps Agreement, banco e impostos ativos na conta. |

## Campos finais preparados

Pacote para copiar e colar:

- `app-store/submission-ready-2026-06-25/01-metadados-app.md`
- `app-store/submission-ready-2026-06-25/02-assinatura-mensal.md`
- `app-store/submission-ready-2026-06-25/03-review-notes.txt`
- `app-store/submission-ready-2026-06-25/04-app-privacy.md`
- `app-store/submission-ready-2026-06-25/05-checklist-final.md`

## Pendências obrigatórias no App Store Connect

Estas pendências não podem ser concluídas apenas pelo repositório local:

1. Confirmar se a build `1.0 (23)` terminou o processamento.
2. Selecionar a build `1.0 (23)` na versão iOS `1.0`.
3. Confirmar distribuição pública somente para Brasil.
4. Confirmar que novos países/regiões não serão ativados automaticamente.
5. Aceitar ou confirmar o `Paid Apps Agreement`.
6. Preencher ou confirmar dados bancários do Account Holder.
7. Preencher ou confirmar dados fiscais da pessoa física.
8. Criar ou confirmar o grupo `Limiar Premium`.
9. Criar ou confirmar o produto `limiar_premium_monthly`.
10. Definir preço em `R$ 9,90/mês`.
11. Definir disponibilidade da assinatura somente Brasil.
12. Incluir a assinatura mensal na submissão da versão.
13. Preencher App Privacy.
14. Preencher classificação etária.
15. Responder Export Compliance.
16. Enviar app e assinatura juntos para revisão.

## Decisão de prontidão

Pronto para continuar no App Store Connect.

Não marcar como publicado/vendido ainda. A publicação comercial só estará concluída quando a Apple processar a build, a versão for enviada para revisão, a assinatura for aprovada e o app estiver disponível na App Store do Brasil.
