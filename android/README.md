# Limiar Android — Fase 0: protótipo do bloqueio

Prova de conceito do recurso central do Limiar no Android: bloquear apps escolhidos a
partir das 5h até a conclusão da travessia. **Esta fase decide (go/no-go) se o port
Android continua.** Nada aqui é UI final.

## O que o protótipo faz

1. Fluxo guiado das 3 permissões especiais: Acesso de uso (`PACKAGE_USAGE_STATS`),
   Sobreposição (`SYSTEM_ALERT_WINDOW`) e isenção de economia de bateria.
2. Seleção de apps instalados para bloquear.
3. Serviço em foreground observa o app em primeiro plano (`UsageEvents`, poll de 800ms)
   e cobre apps bloqueados com um overlay em tela cheia na identidade do Limiar.
4. "Travessia simulada": concluir libera os apps até o próximo ciclo (5h, ancorado na
   hora do ciclo como no iOS).
5. Resiliência em 3 camadas: alarme exato no início do ciclo + watchdog WorkManager
   (15 min) + receiver de boot/atualização.

## Build

- Android Studio: abrir a pasta `android/`. CLI: `./gradlew assembleDebug`
  (JDK 17; `local.properties` com `sdk.dir` é gerado pelo Studio).
- CI: o workflow `.github/workflows/android.yml` publica o APK de debug como artifact
  em cada push — baixe em Actions → Android → artifact `limiar-prototype-debug-apk`.

## Como testar (roteiro do go/no-go)

1. Instalar o APK (emulador API 34, Samsung Remote Test Lab ou aparelho real).
2. Conceder as 3 permissões pelo fluxo guiado; escolher 1-2 apps (ex.: YouTube).
3. "Ativar agora" → abrir o app bloqueado → o overlay do Limiar deve cobrir a tela.
4. "Fazer minha travessia" → concluir → o app bloqueado abre livre.
5. Reiniciar o aparelho → o serviço deve voltar sozinho (notificação persistente).
6. Teste de madrugada (decisivo, apenas em aparelho real Samsung/Xiaomi): ativar à
   noite, dormir, verificar às 5h+ se o bloqueio está de pé.

Limitações conhecidas e riscos de política da Play Store: `docs/fase0-limitacoes.md`.
