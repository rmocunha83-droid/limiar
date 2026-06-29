# Limiar

Limiar é um app iOS em SwiftUI para criar uma pausa espiritual antes de voltar a apps de distração. A pessoa escolhe quais apps vão ativar o Limiar, lê uma jornada religiosa e, depois de concluir com calma, retoma o uso com mais presença.

## Funcionalidades

- Onboarding com estética visual do Limiar e preferências espirituais.
- Tradições: católica, evangélica, judaica e espírita.
- Seleção de apps que ativam o Limiar usando recursos nativos do iOS.
- Exibição dos apps selecionados apenas por ícones originais, sem nome, horário ou descrição.
- Tela inicial com jornada de leitura e três trechos religiosos por sessão.
- Rotação local de trechos para evitar que o mesmo texto fique preso quando o app permanece aberto.
- IA generativa via backend próprio, com GLM-4.5-Air no servidor, histórico antirrepetição e fallback local.
- Explicação espiritual por trecho, com resumo, aplicação prática e pergunta de meditação.
- Histórico local de leituras e opção individual de salvar cada trecho.
- Narração premium via ElevenLabs no backend seguro, acionada apenas quando a pessoa toca em ouvir.
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

O app iOS chama os endpoints em `api/` e nunca carrega chaves de IA no cliente. Configure `GLM_API_KEY` ou `ZAI_API_KEY` no Vercel para geração textual e `ELEVENLABS_API_KEY` para narração. O modelo textual padrão é `glm-4.5-air`, e a voz usa o modelo econômico `eleven_flash_v2_5`. Usuários em teste gratuito ativo e assinantes usam IA completa; usuários no Modo Essencial não geram chamadas de IA nem narração. A arquitetura está detalhada em `docs/AI_ARCHITECTURE.md`.
