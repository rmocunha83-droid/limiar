# Arquitetura de IA do Limiar

## Fluxo

1. O app iOS monta uma leitura local imediatamente usando os geradores locais.
2. Em paralelo, o app chama o backend:
   - `POST /api/spiritual-reading`
   - `POST /api/reflection`
3. O backend chama a OpenAI API usando `OPENAI_API_KEY` em variável de ambiente.
4. O backend exige JSON estruturado e valida o resultado.
5. O app valida novamente o JSON recebido.
6. Se qualquer etapa falhar, o app mantém a reflexão local.

## Segurança

- A chave da OpenAI nunca fica no app iOS.
- O app não envia seleção de APPs bloqueados, email, localização, contatos ou identificadores pessoais.
- O backend recebe apenas tradição, preferências espirituais, profundidade, trechos e histórico recente resumido.
- As chamadas para OpenAI usam `store: false`.

## Variáveis no Vercel

- `OPENAI_API_KEY`: chave da OpenAI usada somente no backend.
- `OPENAI_MODEL`: modelo leve configurável. Padrão: `gpt-4.1-mini`.
- `OPENAI_TIMEOUT_MS`: timeout do backend. Padrão: `12000`.

## Fallback

Os geradores abaixo continuam como plano B:

- `LocalSpiritualReadingGenerator`
- `LocalLightweightReflectionGenerator`

Eles são usados quando o backend falha, quando não há internet, quando a OpenAI retorna erro ou quando o JSON é inválido.

## Testes

```bash
npm run test:ai-backend
```

Esse teste valida o contrato JSON do backend. Para QA no app, testar:

- geração remota com `OPENAI_API_KEY` configurada;
- fallback sem internet;
- backend retornando erro;
- JSON inválido;
- profundidades curta, média e grande;
- retorno ao app depois de bloqueio;
- repetição reduzida com histórico recente.
