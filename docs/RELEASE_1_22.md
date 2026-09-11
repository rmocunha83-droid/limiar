# Limiar 1.22

## Base e escopo

- Base de producao: `e987c20` (1.21, build 202).
- Versao preparada: 1.22, numero local 203; a numeracao distribuida sera confirmada no Xcode Cloud.
- Preservados site, onboarding, paywall, ofertas, StoreKit, selecao de vozes, tamanho do texto e narracao por paragrafos da versao publicada.
- Nenhuma alteracao em autorizacao, agendamento ou liberacao do Tempo de Uso.

## Alteracoes

- Selecao local: ineditos nos temas escolhidos, ineditos de outros temas, depois menos recentes. Historico persistente sem o antigo corte de 60 entradas; recuperacao do historico legado disponivel.
- Catalogo: 1.800 entradas, 450 por tradicao. As 977 existentes foram preservadas; 823 novas entradas verificadas contra a fonte BLIVRE fixada e creditada.
- Feedback local e reversivel, busca em favoritos, campos opcionais para migracao de favoritos e diversidade opt-in nas explicacoes.
- Diagnosticos operacionais sem trechos, preferencias ou identificadores pessoais.
- Narracao: credito BLIVRE preservado visualmente; fala da referencia corrigida com marcador de cache seletivo. Cache dos trechos anteriores preservado.
- Prewarm aceita Blob por OIDC ou token e distingue ausencia real de audio de falha de acesso.

## Validacoes antes do envio

- 79 testes iOS no simulador: passaram.
- 53 testes Node: passaram, incluindo contratos de clientes antigos e novos, vozes permitidas e autenticacao do cache.
- 7 testes de expansao Python: passaram; catalogo valido e novas entradas conferidas contra a fonte.
- Comparacao com o backend publicado: SSML e assinatura dos 977 trechos anteriores identicos nas tres vozes permitidas.
- Geracao e verificacao remota dos 454 audios unicos da expansao: em andamento no momento deste registro.
- Build distribuivel somente pelo Xcode Cloud; conclusao de build, processamento e revisao ainda precisam ser confirmados no App Store Connect.

## Limites

- Historico descartado por versoes antigas nao pode ser reconstruido alem dos registros ainda existentes.
- Preferencias muito estreitas continuam limitando o conjunto elegivel; somente temas se expandem.
- Reabertura da sessao diaria preserva o conteudo atual. A atualizacao nao substitui a leitura no meio da travessia.
- O prewarm cobre a voz padrao configurada; vozes alternativas mantem seu cache separado e geram faltantes sob demanda.
