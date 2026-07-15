# Fase 0 — Limitações conhecidas e riscos de política

## Diferença estrutural vs. iOS

No iOS, o shield (FamilyControls/ManagedSettings) é aplicado **pelo sistema**: o app pode
morrer que o bloqueio continua. No Android não existe equivalente para apps comuns — o
bloqueio é uma construção (serviço observando o foreground + overlay), e sua robustez
depende do serviço estar vivo. Consequências honestas:

1. **Janela de corrida**: há até ~1s entre abrir o app bloqueado e o overlay cobrir a
   tela (poll de 800ms). Aceitável para o propósito (fricção contemplativa), inaceitável
   se o objetivo fosse segurança.
2. **Fabricantes agressivos** (Xiaomi/MIUI-HyperOS, Samsung One UI, Huawei): matam
   serviços em background à noite. Mitigações implementadas: foreground service com
   notificação persistente, isenção de bateria solicitada no onboarding, alarme exato no
   início do ciclo, watchdog WorkManager de 15 min, boot receiver. Mitigações que
   dependem do usuário (documentar no onboarding real): desativar "otimização adicional"
   nos ajustes proprietários (ver dontkillmyapp.com por fabricante).
3. **O usuário pode desinstalar ou revogar permissões** a qualquer momento — como no
   iOS, o compromisso é do usuário consigo mesmo.

## Riscos de política da Play Store (mapeados, não bloqueantes)

- `SYSTEM_ALERT_WINDOW` e `PACKAGE_USAGE_STATS` exigem **declaração de permissões
  sensíveis** no Play Console com justificativa de uso. Apps de bem-estar digital /
  bloqueio por foco são uma categoria reconhecida (há dezenas no ar: Forest, Stay
  Focused, AppBlock) — a justificativa do Limiar (o usuário escolhe bloquear os próprios
  apps até a leitura devocional) se encaixa.
- Vídeo de demonstração do fluxo de permissão costuma ser exigido na revisão.
- `QUERY_ALL_PACKAGES` foi **evitado** de propósito (usamos `<queries>` por intent de
  launcher) — essa permissão é a mais problemática na revisão e não é necessária.
- FGS `specialUse` (Android 14+) exige subtipo declarado no manifest (feito) e
  explicação no Play Console.

## Critério de go/no-go sugerido

GO se: overlay cobre o app bloqueado de forma confiável no uso normal E o serviço
sobrevive à madrugada em pelo menos Samsung One UI com as mitigações ativas (Xiaomi pode
exigir passo manual documentado — aceitável se for minoria da base).
NO-GO se: mesmo com isenção de bateria, o bloqueio matinal falhar com frequência em
aparelhos mainstream — nesse caso o produto Android precisaria ser repensado (ex.:
lembrete forte em vez de bloqueio real).
