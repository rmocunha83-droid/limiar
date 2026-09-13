# Preparacao da release de ordem das leituras

- Base: main 6a441a1 (1.22 / 203).
- Cache: migracao do snapshot existente, mantendo versiculos e homilias. Reflexoes conjuntas remotas antigas com mais de um trecho sao ocultadas e regeneradas sobre os mesmos trechos. Historico, favoritos e preferencias nao sao apagados.
- Contagem do cache e prewarm: usa o numero de trechos realmente elegiveis, nao apenas a profundidade configurada.
- Backend: filtros antes da preservacao de ordem; sessao incompleta recusada antes do provedor. Contratos legados preservados.
- iOS: rejeita ordem divergente, protege travessia ativa e impede prewarm tardio de substituir sessao salva.
- Dashboard: sufixo BLIVRE oculto apenas na apresentacao; fonte, catalogo, identidade e narracao preservados.

## Validacao e publicacao

- Backend consolidado: 53 testes passaram localmente.
- Testes iOS completos: pendentes; nao considerar compilacao como execucao dos testes.
- App Store Connect verificado: 1.22 (203), Pronto para distribuicao, liberacao em etapas no dia 3. Nao alterada.
- Antes de distribuir: concluir testes iOS, conferir proxima numeracao no Xcode Cloud, publicar backend compativel e gerar binario somente pelo Xcode Cloud.
- Nao houve envio para revisao nesta preparacao.
