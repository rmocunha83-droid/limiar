# QA — viewability dos anúncios do Modo Essencial

## Blocos criados no AdMob

- `Limiar — Banner ancorado (Essencial)` — `ca-app-pub-7717198050770102/7996436288`
- `Limiar — Retângulo final (Essencial)` — `ca-app-pub-7717198050770102/2565100496`

O bloco anterior `ca-app-pub-7717198050770102/8580637095` não foi alterado nem
excluído. Ele pode ser arquivado no painel somente depois da validação em produção.

## Evidências visuais

As capturas usam os anúncios oficiais de teste do Google e o argumento DEBUG
`-LimiarForceEssential`.

| Dispositivo | Topo | Meio | Final |
| --- | --- | --- | --- |
| iPhone SE | [topo](iphone-se-top.png) | [meio](iphone-se-middle.png) | [final](iphone-se-end.png) |
| iPhone Pro Max | [topo](iphone-pro-max-top.png) | [meio](iphone-pro-max-middle.png) | [final](iphone-pro-max-end.png) |

No final do conteúdo, a ordem validada é: cards de leitura, MREC, “Editar apps da
pausa”, explicação de conclusão e botão “Despausar apps, continuar”. O banner
ancorado permanece fixo fora da rolagem, sem cobrir elementos interativos.

## Cenários verificados

- Modo Essencial: banner ancorado visível durante a rolagem e MREC único no final.
- Premium/trial: os placements não entram na árvore porque `model.showsAds` é falso.
- Falha forçada (`-LimiarAdMobForceFailure`): slots e rótulos ficam colapsados; os
  dois placements registram `admob_banner_failed` com posição, código e motivo.
- Retry: uma única recarga suave por ciclo de vida de cada placement, sem loop.
