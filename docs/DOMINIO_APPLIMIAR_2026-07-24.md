# Limiar — migração para o domínio applimiar.com.br (24/07/2026)

O projeto passou a ter domínio próprio. Este documento registra o que mudou, o que continua funcionando pelo endereço antigo e **o que ainda falta migrar**.

## Situação

| | Antes | Agora |
|---|---|---|
| Site | `https://limiar-five.vercel.app` | **`https://applimiar.com.br`** |
| E-mail | nenhum (Gmail pessoal) | **`contato@applimiar.com.br`** |

**O endereço antigo continua respondendo normalmente.** O `limiar-five.vercel.app` segue apontando para o mesmo deploy do Vercel — nada quebra por causa da migração. A troca é de posicionamento e credibilidade, não de infraestrutura.

## Infraestrutura

**Domínio:** registrado no Registro.br, zona DNS em modo avançado. Servidores autoritativos: `d.sec.dns.br` e `e.sec.dns.br` (não são os `auto.dns.br` do modo básico — atenção ao diagnosticar DNS).

Zona publicada:

| Tipo | Nome | Valor |
|---|---|---|
| A | applimiar.com.br | 216.150.1.1 (Vercel) |
| CNAME | www | applimiar.com.br |
| MX | applimiar.com.br | 10 mx01.mail.icloud.com. |
| MX | applimiar.com.br | 10 mx02.mail.icloud.com. |
| TXT | applimiar.com.br | "apple-domain=nV6zrK4qg7PRVMIF" |
| TXT | applimiar.com.br | "v=spf1 include:icloud.com ~all" |
| CNAME | sig1._domainkey | sig1.dkim.applimiar.com.br.at.icloudmailadmin.com. |

**E-mail:** iCloud+ com domínio personalizado. Endereço `contato@applimiar.com.br` criado e definido como remetente padrão. SPF e DKIM ativos.

**HTTPS:** certificado Let's Encrypt emitido pelo Vercel, válido até 22/10/2026, renovação automática.

**Vercel:** o `vercel.json` não tem configuração de domínio — o apontamento é feito no painel do projeto. O `cleanUrls: true` significa que `/privacy` funciona sem a extensão `.html`.

## Já migrado

- Site institucional servido pelo domínio novo
- Metatag de verificação do Meta em `index.html` (domínio verificado no Business Manager)
- `api/meta-capi.js` aceita eventos das duas origens — ver `docs/META_TRACKING_2026-07-24.md`
- E-mail de contato nas três páginas legais (`privacy.html`, `terms.html`, `support.html` e as cópias em `marketing/site/`)
- App Store Connect: URL de suporte (`/support`) e de marketing atualizadas

## ⚠️ Ainda aponta para o domínio antigo

Quatro pontos no código do app iOS. **Nenhum está quebrado**, porque o endereço antigo continua ativo — mas convém migrar na próxima versão, por consistência e para não depender indefinidamente de um domínio de plataforma:

| Arquivo | Linha | O que é |
|---|---|---|
| `Limiar/PassageServices.swift` | ~346 | `baseURL` do backend — **o mais sensível** |
| `Limiar/SettingsViews.swift` | ~22 | URL da política de privacidade |
| `Limiar/SettingsViews.swift` | ~23 | URL do suporte |
| `Limiar/PaywallView.swift` | ~46 | URL da política de privacidade |

### Cuidados ao migrar

O `baseURL` do `PassageServices` é carga viva: é por ele que o app chama `api/reading-session`, `api/reflection` e `api/speech`. Trocar exige:

1. Confirmar que os endpoints respondem no domínio novo antes de mudar (o `api/meta-capi` já foi verificado retornando 204)
2. Nova versão do app, com build gerada pelo **Xcode Cloud** (ver `docs/META_TRACKING_2026-07-24.md`, seção 6)
3. Testar em aparelho real, especialmente o pré-aquecimento (`LimiarPrewarmCoordinator`), que roda em background e falha em silêncio

As URLs de privacidade e suporte são de baixo risco — abrem no navegador e podem ser trocadas junto.

### Documentos históricos

Vários arquivos em `docs/` com data no nome (`APP_STORE_NEXT_ACTIONS_2026-06-25.md`, `APP_STORE_SUBMISSION_STATUS_2026-06-25.md`, `FAMILY_CONTROLS_DISTRIBUTION_REQUEST.md`) citam o domínio antigo. São **registros de época** e devem permanecer como estão — reescrevê-los apagaria o histórico.

## Também vale saber

O `applimiar.com.br` está verificado no Meta Business Manager, o que autoriza a conta de anúncios a otimizar campanhas pelos eventos do site. Antes disso a mensuração era cega no domínio novo — o endpoint rejeitava os eventos com HTTP 400. Detalhes em `docs/META_TRACKING_2026-07-24.md`.
