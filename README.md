# Limiar

Limiar é um app iOS em SwiftUI para criar uma pausa espiritual antes de voltar a apps de distração. A pessoa escolhe quais apps vão ativar o Limiar, lê uma jornada religiosa e, depois de concluir com calma, retoma o uso com mais presença.

## Funcionalidades

- Onboarding com estética visual do Limiar e preferências espirituais.
- Tradições: católica, evangélica, judaica e espírita.
- Seleção de apps que ativam o Limiar usando recursos nativos do iOS.
- Exibição dos apps selecionados apenas por ícones originais, sem nome, horário ou descrição.
- Tela inicial com jornada de leitura e três trechos religiosos por sessão.
- Rotação local de trechos para evitar que o mesmo texto fique preso quando o app permanece aberto.
- IA generativa via backend próprio, com OpenAI no servidor, cache, histórico antirrepetição e fallback local.
- Explicação espiritual por trecho, com resumo, aplicação prática e pergunta de meditação.
- Histórico local de leituras e opção individual de salvar cada trecho.
- Narração premium via backend seguro, sem expor a chave da OpenAI no app iOS.
- Botão “Li com calma, continuar” com ícone positivo e retorno temporário aos apps selecionados.
- Modo Essencial após o teste gratuito: mantém os 3 trechos principais e o fluxo de pausa, sem IA e sem narração.
- Preview web e materiais de marketing/App Store.

## Requisitos

- Xcode 26.5 ou superior.
- iOS 17 ou superior.
- Conta Apple Developer adicionada no Xcode.
- Perfis de desenvolvimento para o app e extensões:
  - `com.romeucunha.Limiar`
  - `com.romeucunha.Limiar.DeviceActivityMonitorExtension`
  - `com.romeucunha.Limiar.ShieldActionExtension`
  - `com.romeucunha.Limiar.ShieldConfigurationExtension`

## Observação de linguagem

Todos os textos visíveis e textos gerados para o usuário devem usar português brasileiro com acentuação correta.

## IA generativa

O app iOS chama os endpoints em `api/` e nunca carrega a chave da OpenAI no cliente. Configure `OPENAI_API_KEY` no Vercel e, opcionalmente, `OPENAI_MODEL` para trocar o modelo sem alterar o app. O modelo padrão é `gpt-4.1-mini`. Usuários em teste gratuito ativo e assinantes usam IA completa; usuários no Modo Essencial não geram chamadas de IA. A arquitetura está detalhada em `docs/AI_ARCHITECTURE.md`.
