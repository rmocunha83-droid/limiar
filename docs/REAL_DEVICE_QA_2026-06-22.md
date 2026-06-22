# QA em aparelho real - 2026-06-22

Dispositivo usado: iPhone Romeu (`91B75307-6A73-5D0E-AEF7-D3CC8AB36768`), iPhone 16, Developer Mode ativo.

## Validado automaticamente

- App compilado para aparelho real com Xcode 26.5.
- App instalado no iPhone físico como `com.romeucunha.Limiar`.
- App aberto no iPhone sem erro de instalação ou lançamento.
- Tela inicial capturada no aparelho real.
- Botão `Continuar` aparece inteiro na tela inicial.
- Entitlements do app confirmados:
  - Family Controls ativo.
  - App Group `group.com.romeucunha.Limiar`.
  - Team `L38WCHAWJ9`.
- Entitlements das extensões confirmados:
  - `LimiarDeviceActivityMonitorExtension`
  - `LimiarShieldActionExtension`
  - `LimiarShieldConfigurationExtension`
- Preview do navegador atualizado e revisado com acentuação correta.
- Varredura de textos principais sem ocorrências visíveis como `voce`, `nao`, `tradicao`, `reflexao`, `meditacao`, `liberacao`, `consciencia`, `narracao`, `concluida`.

## Correções feitas durante o QA

- Corrigida a acentuação de textos visíveis e textos usados em reflexão:
  - `TRADIÇÃO`
  - `Parar narração`
  - `Equilíbrio recomendado para começar.`
  - `Nenhuma leitura concluída ainda.`
  - `Presença`
  - `Coríntios`
  - `consciência`
  - `Referência`
- Corrigido trecho de Isaías:
  - `Então a tua luz romperá como a aurora, e a tua cura brotará sem demora.`
- Ajustada a cor do botão do escudo do iOS para a mesma paleta verde suave do botão principal.
- Implementado agendamento de reaplicação do bloqueio quando o tempo liberado termina. Assim, depois da leitura, o APP bloqueado volta a ser protegido mesmo se o Limiar ficar em segundo plano.

## Ainda precisa de teste manual no iPhone

Estes pontos dependem de interação com telas nativas protegidas do iOS e precisam ser tocados no aparelho:

- Autorizar Tempo de Uso.
- Abrir o seletor nativo de APPs.
- Escolher um APP real para bloquear.
- Confirmar o escudo do iOS ao abrir esse APP.
- Confirmar o fluxo completo: APP bloqueado -> Limiar -> leitura -> liberação temporária -> bloqueio reaplicado depois do tempo.
- Confirmar a narração em voz masculina disponível no aparelho.

## Resultado

A versão instalada no iPhone está pronta para teste real do fluxo completo. O projeto compila, instala e abre no aparelho, e a principal falha encontrada no QA automático, a reaplicação do bloqueio após o tempo liberado, foi corrigida.
