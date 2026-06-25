# Verificar status da build no App Store Connect

Use este guia para confirmar pelo terminal se a build `1.0 (23)` já terminou o processamento no App Store Connect/TestFlight.

## Estado atual

- App Apple ID: `6783115468`
- Versão: `1.0`
- Build: `23`
- Plataforma: iOS
- Upload comprovado localmente: `Uploaded to Apple` em `2026-06-25T21:41:47Z`

## O que é necessário

Uma App Store Connect API Key criada na conta Apple.

Você precisa de:

- API Key ID
- Issuer ID
- arquivo `.p8` da chave privada

Não salve esses valores no Git.

## Como rodar

No terminal, a partir da raiz do projeto:

```bash
ASC_API_KEY_ID=ABC123DEF4 \
ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000 \
ASC_P8_FILE=/caminho/seguro/AuthKey_ABC123DEF4.p8 \
scripts/check_app_store_build_status.sh
```

O script consulta:

- App Apple ID `6783115468`
- versão `1.0`
- build `23`
- plataforma `ios`

## Ajustar valores, se necessário

```bash
APP_APPLE_ID=6783115468 \
APP_VERSION=1.0 \
BUILD_NUMBER=23 \
PLATFORM=ios \
ASC_API_KEY_ID=ABC123DEF4 \
ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000 \
ASC_P8_FILE=/caminho/seguro/AuthKey_ABC123DEF4.p8 \
scripts/check_app_store_build_status.sh
```

## Interpretação

Se a Apple retornar que a build está processada/disponível, o próximo passo é entrar no App Store Connect, selecionar a build `1.0 (23)` na versão iOS `1.0` e enviar o app com a assinatura mensal para revisão.

Se a build ainda estiver em processamento, aguarde e tente novamente depois.
