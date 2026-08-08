# Plano de teste em aparelho real

Este checklist deve ser executado depois que o Limiar estiver instalado em um iPhone físico com assinatura válida da Apple Developer.

## Onboarding

- Conferir se a tela inicial abre com a imagem, fonte, cores e botão corretos.
- Verificar se o botão `Continuar` não fica cortado em telas pequenas.
- Avançar por todas as etapas do onboarding.
- Confirmar que todos os textos estão com acentuação correta em português.
- Selecionar tradições religiosas, incluindo católica, evangélica, judaica e espírita.
- Configurar preferências bíblicas, temas favoritos e profundidade da explicação.

## Assinatura e coortes

- Em instalação limpa, concluir o onboarding e confirmar que o portão não pode ser fechado ou contornado.
- Confirmar preços localizados reais nos planos mensal e anual.
- Em conta elegível, confirmar “7 dias grátis” nos dois planos; em conta não elegível, confirmar que a promessa não aparece.
- Comprar no sandbox e confirmar acesso imediato ao dashboard, inclusive durante o teste.
- Cancelar durante o teste e confirmar acesso até a expiração; depois, retorno ao portão sem anúncios e sem Modo Essencial.
- Restaurar uma assinatura ativa e confirmar entrada no dashboard.
- Simular coorte legada com `TrialStartStore` preenchido e confirmar trial local, funil D6/D7/D8 e Modo Essencial sem qualquer portão novo.
- Validar os eventos Meta de início do teste e ativação paga no Gerenciador de Eventos, sem duplicatas.

## Apps que ativam o Limiar

- Abrir a seleção nativa de apps.
- Escolher apps ou categorias que ativam o Limiar.
- Salvar a seleção.
- Conferir se a tela usa a linguagem `apps que ativam o Limiar`.
- Ativar as pausas.
- Tentar abrir um app selecionado.
- Confirmar que o escudo do iOS aparece com a mensagem correta do Limiar.

## Leitura e continuidade

- Abrir o Limiar a partir do fluxo de pausa.
- Confirmar que aparecem 1, 2 ou 3 leituras adequadas ao perfil, conforme a profundidade Curta, Média ou Mais profunda.
- Verificar se trechos muito curtos são combinados em uma leitura maior.
- Finalizar a leitura.
- Conferir se os apps selecionados ficam disponíveis depois da leitura.
- Confirmar que a pausa diária volta a ser aplicada no ciclo seguinte, às 5h da manhã.

## Contingência sem conexão

- Ativar o modo avião antes de abrir a travessia e confirmar que 1, 2 ou 3 leituras locais aparecem com o aviso discreto, sem explicações vazias visíveis.
- Concluir a leitura local e confirmar histórico, recentes e liberação dos apps selecionados.
- Repetir sem concluir, restabelecer a conexão e tocar em `Tentar novamente`; confirmar que uma resposta remota válida substitui a sessão uma única vez.
- Repetir concluindo antes da reconexão; confirmar que o conteúdo concluído não é substituído.
- Repetir na coorte legada em Modo Essencial e confirmar anúncios, bloqueios Premium e conclusão normal.

## Rotação de trechos

- Manter o Limiar aberto em segundo plano.
- Abrir novamente um app selecionado.
- Voltar para o Limiar.
- Confirmar que um novo trecho aparece, evitando que o texto anterior fique preso.
- Repetir o fluxo algumas vezes para verificar que a rotação continua funcionando.

## Reflexões personalizadas

- Gerar reflexão curta.
- Gerar reflexão média.
- Gerar reflexão profunda.
- Confirmar que a resposta contém resumo, significado espiritual, aplicação prática, conclusão e pergunta de meditação.
- Verificar se o texto não inventa conteúdo bíblico.
- Reabrir o mesmo trecho com o mesmo perfil e profundidade.
- Confirmar que usuários novos com entitlement ativo, inclusive no teste, e assinantes legados recebem a experiência completa com IA.
- Confirmar que o Modo Essencial aparece somente para legados e mostra os trechos principais com explicações essenciais, anúncios e sem narração.

## Favoritos e histórico

- Marcar um trecho como favorito.
- Remover um trecho dos favoritos.
- Abrir a tela de favoritos.
- Conferir se o trecho salvo aparece corretamente.
- Abrir o histórico.
- Confirmar que as leituras concluídas aparecem com referência, data e duração.

## Narração

- Tocar para ouvir o trecho.
- Confirmar que a narração usa voz local do iOS em português do Brasil quando disponível.
- Pausar ou interromper a narração.
- Sair da tela durante a narração e confirmar que o áudio não fica preso indevidamente.
- Confirmar que tocar em “Ouvir este trecho” no Modo Essencial legado abre o paywall e não chama a narração.

## Configurações

- Ajustar apps que ativam o Limiar.
- Confirmar o texto `Ajustar Apps que ativam o Limiar`.
- Verificar o subtítulo `Defina quais apps vão acionar essa pausa`.
- Alterar tradição, temas e profundidade.
- Confirmar que as próximas leituras respeitam as novas preferências.

## Regressão visual

- Testar em modo claro e escuro do sistema.
- Testar com fonte do iOS aumentada.
- Testar em iPhone pequeno e iPhone grande.
- Verificar se não há botões cortados, textos sobrepostos ou elementos fora da tela.

## Portão de assinatura (1.13)

- Abrir o app novo em modo avião ao fim do onboarding: o portão deve mostrar "Tentar novamente" (nunca botão morto); religar a rede e confirmar que os planos carregam pelo botão ou ao voltar ao app.
- Reinstalar com assinatura ativa e sem rede: banner "Verificando sua assinatura" com Restaurar em destaque; com rede, acesso liberado sem passar pela venda.
- Usuário pré-1.13 com onboarding completo que nunca iniciou o trial: após atualizar, deve cair na tela antiga "Começar minha travessia" (coorte legado), não no portão.
- Selecionar plano Mensal enquanto os preços carregam: a seleção não pode voltar sozinha para o Anual.

## Narração (estabilidade)

- Receber ligação durante a narração: pausa; tocar "Continuar narração" com a ligação ativa mantém a pausa (não apaga a fila); ao desligar, retomar do mesmo ponto.
- Desconectar o fone durante a narração: pausa recuperável.
- Modo avião no meio da narração: botão muda para "Não foi possível continuar — tentar de novo"; religar e tocar retoma do segmento falho.
- Tela bloqueada por 2+ minutos numa narração longa: controles de play/pause aparecem na tela bloqueada e a narração segue entre os parágrafos.
- Tocar narração no dashboard e em um trecho salvo em sequência: nunca dois áudios ao mesmo tempo.

## Onboarding (temas por tradição)

- Escolher tradição Espírita no passo 1: o passo de temas deve abrir com 8 temas pré-selecionados do conjunto espírita.
- Desmarcar todos os temas: "Continuar" não avança e mostra a mensagem de mínimo.

## Critério de aprovação

O app só deve ser considerado pronto para publicação quando todos os fluxos acima passarem em aparelho real. Qualquer falha encontrada deve ser corrigida e testada novamente antes de seguir para App Store.
