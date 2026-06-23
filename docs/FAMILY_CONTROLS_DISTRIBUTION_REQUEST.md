# Family Controls Distribution - Pedido para Apple

## Bloqueio atual

O archive do app foi criado com sucesso, mas a exportação para App Store falhou porque o provisioning profile de distribuição não inclui `com.apple.developer.family-controls`.

Erro observado:

```text
exportArchive Provisioning profile "iOS Team Store Provisioning Profile: com.romeucunha.Limiar" doesn't include the Family Controls (Development) capability.
exportArchive Provisioning profile "iOS Team Store Provisioning Profile: com.romeucunha.Limiar" doesn't include the com.apple.developer.family-controls entitlement.
```

Segundo a Apple, antes de distribuir um app que usa Family Controls, o Account Holder precisa pedir permissão para usar o entitlement de distribuição.

## Link do pedido

https://developer.apple.com/contact/request/family-controls-distribution

## Dados do app

- Nome: Limiar
- Bundle ID principal: `com.romeucunha.Limiar`
- App Group: `group.com.romeucunha.Limiar`
- Team em uso no Xcode: `L38WCHAWJ9`
- Categoria: Productivity
- Site: `https://limiar-five.vercel.app/`
- Política de Privacidade: `https://limiar-five.vercel.app/privacy.html`
- Suporte: `https://limiar-five.vercel.app/support.html`

## Extensions do Screen Time

- `com.romeucunha.Limiar.ShieldConfigurationExtension`
- `com.romeucunha.Limiar.ShieldActionExtension`
- `com.romeucunha.Limiar.DeviceActivityMonitorExtension`

Se o formulário permitir informar extensões ou bundle IDs adicionais, inclua os três acima. Se o formulário aceitar apenas o app principal, envie primeiro o bundle principal e depois confirme no portal se as capacidades de distribuição aparecem para as extensões também.

## Texto sugerido para justificativa

Limiar is a productivity and digital wellbeing app that helps users create a conscious pause before opening distracting apps. The user explicitly selects apps, categories, or websites using the native iOS FamilyControls picker. Limiar then uses Screen Time APIs, ManagedSettings shields, Shield extensions, and DeviceActivity scheduling to temporarily block those selected apps until the user completes a spiritual reading/reflection inside the app.

The app is not designed for surveillance, hidden monitoring, advertising, or third-party control. The selected apps are used only on device to apply the user-requested shield. Limiar does not sell or share the user's app selections, and the privacy policy explains the data practices.

The Family Controls distribution entitlement is required so Limiar can provide its core feature on TestFlight and the App Store: user-controlled blocking and timed release of distracting apps after a reflective reading.

## Depois da aprovação

1. Abrir Apple Developer > Certificates, Identifiers & Profiles.
2. Conferir o App ID `com.romeucunha.Limiar`.
3. Em Additional Capabilities, habilitar Family Controls para distribuição.
4. Recriar/atualizar provisioning profiles de App Store para o app e extensões.
5. Fechar e reabrir Xcode.
6. Rodar novamente:

```sh
xcodebuild -exportArchive -archivePath /tmp/Limiar.xcarchive -exportPath /tmp/LimiarExport -exportOptionsPlist /tmp/LimiarExportOptions.plist -allowProvisioningUpdates
```
