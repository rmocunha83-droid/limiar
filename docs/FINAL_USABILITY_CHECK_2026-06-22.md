# Verificação final de usabilidade - 2026-06-22

## Estado no iPhone

- Dispositivo: iPhone Romeu (`91B75307-6A73-5D0E-AEF7-D3CC8AB36768`).
- App instalado: `Limiar`, bundle `com.romeucunha.Limiar`, versão `1.0 (1)`.
- App relançado no iPhone com sucesso.
- Processo confirmado pelo Xcode/devicectl com PID `4269`.
- Captura real do aparelho salva em `/tmp/limiar-final-qa/iphone-running.png`.

## Usabilidade visual verificada

- Tela inicial abre com a imagem de fundo correta.
- Logo, `BEM-VINDO`, título `Limiar`, frase e botão aparecem alinhados e legíveis.
- O botão `Continuar` aparece inteiro na tela.
- Não há sobreposição aparente de textos na tela inicial.
- Paleta verde suave do botão permanece aplicada.
- Preview do navegador interno mostra textos com acentuação correta.

## Funcionalidades verificadas por build e inspeção

- Build para aparelho real passou com sucesso.
- App está assinado com Team `L38WCHAWJ9`.
- App tem `FamilyControls` habilitado.
- App usa o App Group `group.com.romeucunha.Limiar`.
- Extensões instaladas e assinadas:
  - `LimiarDeviceActivityMonitorExtension`
  - `LimiarShieldActionExtension`
  - `LimiarShieldConfigurationExtension`
- Seleção nativa de APPs está integrada via `FamilyActivityPicker`.
- Autorização de Tempo de Uso está implementada.
- Escudo do iOS está implementado com texto e cor do Limiar.
- Rotação de trechos ao voltar para o app está implementada.
- Plano de leitura busca aproximadamente 10 minutos quando trechos são curtos.
- Favoritar e remover trechos favoritos está implementado.
- Histórico local está implementado.
- Narração por voz masculina do iOS está implementada com fallback para voz `pt-BR`.
- Reflexão com cache local está implementada.
- Reaplicação do bloqueio após o tempo liberado está implementada.

## Pontos que ainda exigem toque manual no iPhone

Estas etapas dependem de telas protegidas do iOS e não podem ser concluídas integralmente por automação:

- Tocar em `Continuar` e atravessar o onboarding no aparelho.
- Autorizar Tempo de Uso no prompt nativo.
- Selecionar APPs reais no seletor nativo.
- Abrir um APP bloqueado e confirmar o escudo do iOS.
- Fazer uma leitura, liberar o APP e esperar o tempo terminar para confirmar a reaplicação real do bloqueio.
- Ouvir a narração no alto-falante/fone do iPhone para avaliar naturalidade da voz instalada no aparelho.

## Resultado final

O Limiar está instalado e rodando no iPhone. A parte técnica principal está compilando, assinada e presente no app. Para dizer que `todas` as funcionalidades passaram em uso real, ainda falta executar no próprio iPhone os fluxos protegidos do Tempo de Uso listados acima.
