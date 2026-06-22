# Limiar

Limiar é um app iOS em SwiftUI para criar uma pausa espiritual antes de voltar a APPs de distração. A pessoa escolhe quais APPs quer bloquear, lê uma jornada religiosa diretamente na tela inicial e, depois de concluir com calma, libera um período de uso configurável.

## Funcionalidades

- Onboarding com estética visual do Limiar e preferências espirituais.
- Tradições: católica, evangélica, judaica e espírita.
- Seleção de APPs bloqueados usando recursos nativos do iOS.
- Exibição dos APPs bloqueados apenas por ícones originais, sem nome, horário ou descrição.
- Tela inicial com jornada de leitura e pelo menos cinco trechos religiosos por sessão.
- Rotação local de trechos para evitar que o mesmo texto fique preso quando o app permanece aberto.
- Serviço `AISpiritualReadingService`, preparado para IA leve, cache local e fallback local quando necessário.
- Explicação espiritual por trecho, com resumo, aplicação prática e pergunta de meditação.
- Histórico local de leituras e opção individual de salvar cada trecho.
- Narração do trecho com voz masculina do iOS quando disponível.
- Botão “Li com calma, liberar acesso” com cadeado animado e liberação temporária pelo período escolhido.
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
