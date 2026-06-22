# Plano de teste em aparelho real

Este checklist deve ser executado depois que o Limiar estiver instalado em um iPhone físico com assinatura válida da Apple Developer.

## Onboarding

- Conferir se a tela inicial abre com a imagem, fonte, cores e botão corretos.
- Verificar se o botão `Continuar` não fica cortado em telas pequenas.
- Avançar por todas as etapas do onboarding.
- Confirmar que todos os textos estão com acentuação correta em português.
- Selecionar tradições religiosas, incluindo católica, evangélica, judaica e espírita.
- Configurar preferências bíblicas, temas favoritos e profundidade da explicação.

## Bloqueio de APPs

- Abrir a seleção nativa de APPs.
- Escolher APPs para bloquear.
- Salvar a seleção.
- Conferir se a tela usa o texto `Escolha quais APPs você quer bloquear`.
- Ativar o bloqueio.
- Tentar abrir um APP bloqueado.
- Confirmar que o escudo do iOS aparece com a mensagem correta do Limiar.

## Leitura e liberação

- Abrir o Limiar a partir do fluxo de bloqueio.
- Confirmar que aparece um trecho religioso adequado ao perfil configurado.
- Verificar se trechos muito curtos são combinados em uma leitura maior.
- Finalizar a leitura.
- Conferir se o APP bloqueado fica liberado pelo tempo configurado.
- Confirmar que, depois desse tempo, uma nova leitura é exigida.

## Rotação de trechos

- Manter o Limiar aberto em segundo plano.
- Abrir novamente um APP bloqueado.
- Voltar para o Limiar.
- Confirmar que um novo trecho aparece, evitando que o texto anterior fique preso.
- Repetir o fluxo algumas vezes para verificar que a rotação continua funcionando.

## Reflexão com IA

- Gerar reflexão curta.
- Gerar reflexão média.
- Gerar reflexão profunda.
- Confirmar que a resposta contém resumo, significado espiritual, aplicação prática, conclusão e pergunta de meditação.
- Verificar se o texto não inventa conteúdo bíblico.
- Reabrir o mesmo trecho com o mesmo perfil e profundidade.
- Confirmar que o cache local reutiliza a reflexão sem nova chamada de IA.

## Favoritos e histórico

- Marcar um trecho como favorito.
- Remover um trecho dos favoritos.
- Abrir a tela de favoritos.
- Conferir se o trecho salvo aparece corretamente.
- Abrir o histórico.
- Confirmar que as leituras concluídas aparecem com referência, data e duração.

## Narração

- Tocar para ouvir o trecho.
- Confirmar que a voz masculina do iOS é usada quando disponível.
- Pausar ou interromper a narração.
- Sair da tela durante a narração e confirmar que o áudio não fica preso indevidamente.

## Configurações

- Alterar duração de liberação.
- Confirmar o texto `Defina o tempo de liberação do app após a leitura religiosa`.
- Verificar o subtítulo explicando que, depois desse tempo, será necessária uma nova leitura.
- Ajustar APPs bloqueados.
- Confirmar o texto `Ajustar APPs bloqueados`.
- Alterar tradição, temas e profundidade.
- Confirmar que as próximas leituras respeitam as novas preferências.

## Regressão visual

- Testar em modo claro e escuro do sistema.
- Testar com fonte do iOS aumentada.
- Testar em iPhone pequeno e iPhone grande.
- Verificar se não há botões cortados, textos sobrepostos ou elementos fora da tela.

## Critério de aprovação

O app só deve ser considerado pronto para publicação quando todos os fluxos acima passarem em aparelho real. Qualquer falha encontrada deve ser corrigida e testada novamente antes de seguir para App Store.
