# Status de publicação App Store - 25/06/2026

## Estado comprovado no projeto

- Repositório local limpo em `main`.
- Último commit enviado ao GitHub antes desta checagem: `83d6ab0 Alinha assinatura inicial ao plano mensal`.
- Site publicado na Vercel em `https://limiar-five.vercel.app/`.
- Site público já reflete:
  - apps que ativam o Limiar;
  - 3 trechos;
  - experiência completa no teste gratuito e Premium;
  - Modo Essencial após o teste;
  - Política de Privacidade, Termos e Suporte.
- Assets de App Store existem em:
  - `app-store/upload-ready/` para 6.7";
  - `app-store/upload-ready-6.5/` para 6.5".
- Os cards visuais atuais usam a linguagem positiva do produto, como `apps que ativam o Limiar`, `pausa`, `leitura com IA` e `retomar com presença`.

## Estado comprovado do build

- App: Limiar.
- Bundle ID: `com.romeucunha.Limiar`.
- Versão: `1.0`.
- Build: `22`.
- App Apple ID: `6783115468`.
- Archive local: `build/TestFlight/Limiar-1.0-22.xcarchive`.
- Export local: `build/TestFlight/export-22/Limiar.ipa`.
- O registro local do Xcode mostra `Uploaded to Apple` em `2026-06-25T19:17:26Z`.
- O pacote exportado tem assinatura de distribuição `Cloud Managed Apple Distribution`.
- O pacote exportado inclui:
  - `com.apple.developer.family-controls = true`;
  - `group.com.romeucunha.Limiar`;
  - `beta-reports-active = true`;
  - `get-task-allow = false`.

## O que ainda precisa ser confirmado no App Store Connect

Estas etapas dependem da interface do App Store Connect ou de uma chave App Store Connect API, que não está configurada no projeto.

1. Confirmar se o build `1.0 (22)` já terminou o processamento.
2. Selecionar o build `1.0 (22)` na versão iOS `1.0`.
3. Confirmar distribuição pública pela App Store.
4. Definir disponibilidade do app somente para o Brasil.
5. Confirmar que novas regiões/países não serão ativados automaticamente.
6. Confirmar disponibilidade das assinaturas somente para o Brasil.
7. Como pessoa física, aceitar o Paid Apps Agreement.
8. Como pessoa física, preencher dados bancários e fiscais do Account Holder.
9. Configurar/submeter somente o produto mensal `Limiar Premium Mensal` por `R$ 9,90/mês`.
10. Testar assinatura no Sandbox/TestFlight.
11. Revisar App Privacy, classificação etária, export compliance e notas para revisão.
12. Enviar app e assinatura para revisão juntos.

Guia operacional para executar as etapas acima: `docs/APP_STORE_MANUAL_SUBMISSION_BRASIL.md`.

## Observação importante sobre o teste grátis

O teste gratuito de 7 dias está implementado como experiência interna do app antes da assinatura. A assinatura StoreKit não precisa ter oferta introdutória para o lançamento inicial, salvo decisão posterior de produto.

## Status final deste arquivo

O projeto está tecnicamente pronto para a etapa de submissão, mas a publicação comercial na App Store ainda não está concluída enquanto as confirmações acima não forem feitas no App Store Connect.
