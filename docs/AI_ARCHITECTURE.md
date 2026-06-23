# Arquitetura de IA do Limiar

## Fluxo

1. O app iOS monta uma leitura local imediatamente usando os geradores locais.
2. Para usuários no teste gratuito ativo ou com assinatura ativa, o app chama o backend:
   - `POST /api/spiritual-reading`
   - `POST /api/reflection`
3. O backend chama a OpenAI API usando `OPENAI_API_KEY` em variável de ambiente.
4. O backend exige JSON estruturado e valida o resultado.
5. O app valida novamente o JSON recebido.
6. Se qualquer etapa falhar, o app mantém a reflexão local sem mostrar erro técnico ao usuário.

Usuários sem teste ativo e sem assinatura ativa não devem acionar chamadas remotas de IA.

## Modelo Comercial

- Modelo padrão: `gpt-4.1-mini`.
- O modelo só deve ser alterado via `OPENAI_MODEL` no Vercel.
- A leitura principal usa 4 textos espirituais/religiosos e uma reflexão final.
- Usuários em teste gratuito ativo e assinantes podem usar até 6 gerações remotas por dia.
- A partir do limite diário, o app usa leitura local até o dia seguinte.
- O app evita gerar nova leitura remota quando o usuário apenas sai e volta para a mesma tela.
- O backend aplica rate limit por janela e limite diário por instalação/IP para reduzir chamadas duplicadas e proteger custo.
- O GPT é usado apenas para conteúdo textual. A narração usa voz nativa do iOS no aparelho.

## Segurança

- A chave da OpenAI nunca fica no app iOS.
- O app não envia seleção de APPs bloqueados, email, localização, contatos ou identificadores pessoais.
- O backend recebe apenas tradição, preferências espirituais, profundidade, trechos e histórico recente resumido.
- As chamadas para OpenAI usam `store: false`.

## Variáveis no Vercel

- `OPENAI_API_KEY`: chave da OpenAI usada somente no backend.
- `OPENAI_MODEL`: modelo leve configurável. Padrão: `gpt-4.1-mini`.
- `OPENAI_TIMEOUT_MS`: timeout do backend. Padrão: `12000`.
- `LIMIAR_AI_DAILY_GENERATION_LIMIT`: limite diário por endpoint/instalação. Padrão: `6`.
- `LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS`: limite por janela. Padrão: `24`.
- `LIMIAR_AI_RATE_LIMIT_WINDOW_MS`: janela do limite. Padrão: `900000`.

## Fallback

Os geradores abaixo continuam como plano B:

- `LocalSpiritualReadingGenerator`
- `LocalLightweightReflectionGenerator`

Eles são usados quando o backend falha, quando não há internet, quando a OpenAI retorna erro ou quando o JSON é inválido.
O fallback não é a experiência principal para usuários pagantes ou em teste gratuito; ele existe para manter o app fluido.

## Narração

A leitura em voz alta é feita localmente com `AVSpeechSynthesizer` e `AVSpeechUtterance`.
O app não usa OpenAI TTS, não gera áudio remoto e não consome tokens para voz.
Quando disponível, a voz preferida é `pt-BR`; se ela não existir no aparelho, o app usa outra voz em português ou a voz padrão do sistema.

## Testes

```bash
npm run test:ai-backend
```

Esse teste valida o contrato JSON do backend. Para QA no app, testar:

- geração remota com `OPENAI_API_KEY` configurada;
- limite diário na 7ª tentativa;
- fallback sem internet;
- backend retornando erro;
- JSON inválido;
- profundidades curta, média e grande;
- retorno ao app depois de bloqueio;
- repetição reduzida com histórico recente.
