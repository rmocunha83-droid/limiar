# Family Controls (Distribution) — solicitação para as extensões

## Por que isso é necessário

O código já pede o entitlement `com.apple.developer.family-controls` nos 4 targets,
mas para builds de **TestFlight/App Store** a Apple precisa conceder a capability
"Family Controls (Distribution)" **para cada bundle ID individualmente**. Hoje ela
provavelmente está concedida só para o app principal — por isso a extensão que
rearma o shield às 5h não funciona em TestFlight (e funciona em builds de
desenvolvimento via Xcode, que usam o entitlement de dev automático).

## Passo a passo

1. **Solicitar a capability à Apple** (uma solicitação por bundle ID):
   - Formulário: https://developer.apple.com/contact/request/family-controls-distribution
   - Solicitar para os 3 bundle IDs das extensões:
     - `com.romeucunha.Limiar.DeviceActivityMonitorExtension`
     - `com.romeucunha.Limiar.ShieldActionExtension`
     - `com.romeucunha.Limiar.ShieldConfigurationExtension`
   - (O app principal `com.romeucunha.Limiar` já deve ter — confira no portal.)

2. **Texto sugerido para o formulário** (em inglês):

   > Limiar is a faith-based digital wellbeing app that uses the Screen Time API
   > to help users pause before opening distracting apps. The main app
   > (com.romeucunha.Limiar) already has the Family Controls distribution
   > entitlement. We are requesting the same entitlement for its embedded
   > extensions, which are required for the feature to work when the app is not
   > running: a DeviceActivityMonitor extension that re-applies the shield every
   > morning on the user-selected schedule, a ShieldConfiguration extension that
   > renders our custom shield UI, and a ShieldAction extension that handles the
   > shield button. The app uses AuthorizationCenter with `.individual`
   > authorization only (no parental controls over other users).

3. **Depois da aprovação** (a Apple manda e-mail, costuma levar de dias a poucas semanas):
   - No portal (Certificates, Identifiers & Profiles → Identifiers), abra cada um
     dos 3 App IDs das extensões e habilite **Family Controls** em Capabilities.
   - Se usa signing automático, o Xcode regenera os profiles sozinho no próximo
     archive. Se manual, regenere os provisioning profiles de distribuição.
   - Suba um novo build para o TestFlight e valide: concluir a travessia à noite,
     manter o Limiar fechado e conferir se o shield voltou depois das 5h
     (a tela Diagnóstico técnico nas configurações mostra os eventos `monitor.*`).

## Importante até a aprovação chegar

Com o entitlement já declarado nos `.entitlements`, o **archive de distribuição
pode falhar** ("Provisioning profile doesn't include the
com.apple.developer.family-controls entitlement") enquanto a Apple não aprovar e
as capabilities não forem habilitadas nos App IDs. Se precisar subir um build
urgente antes disso, remova temporariamente a chave dos 3 arquivos
`Limiar/Extensions/*/*.entitlements` (e devolva depois).
