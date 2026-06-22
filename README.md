# Limiar

Limiar é um app iOS em SwiftUI para criar uma pausa espiritual antes de voltar a apps de distração. A pessoa escolhe quais APPs quer bloquear, lê um trecho religioso selecionado pelo app e, depois da leitura, libera um período de uso configurável.

## Funcionalidades

- Onboarding com estética visual do Limiar e preferências espirituais.
- Tradições: católica, evangélica, judaica e espírita.
- Seleção de APPs bloqueados usando recursos nativos do iOS.
- Rotação local de trechos para evitar que o mesmo texto fique preso quando o app permanece aberto.
- Plano de leitura com trechos suficientes para uma pausa de aproximadamente dez minutos.
- Reflexões geradas por `AIReflectionService`, com cache local para economizar chamadas de IA.
- Histórico local de leituras e opção de salvar trechos favoritos.
- Narração do trecho com voz masculina do iOS quando disponível.
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
