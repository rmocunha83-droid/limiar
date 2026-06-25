# Arquitetura de IA do Limiar

## Fluxo

1. O app iOS prepara candidatos de leitura conforme as preferências do usuário.
2. Para usuários no teste gratuito ativo ou com assinatura ativa, o app chama o backend:
   - `POST /api/spiritual-reading`
   - `POST /api/reflection`
   - `POST /api/speech`, quando o usuário toca para ouvir a leitura.
3. O backend chama a OpenAI API usando `OPENAI_API_KEY` em variável de ambiente.
4. O backend exige JSON estruturado e valida o resultado.
5. O app valida novamente o JSON recebido.
6. Se qualquer etapa falhar, o app mostra uma mensagem simples de indisponibilidade sem expor erro técnico.

Usuários com teste expirado e sem assinatura ativa entram no Modo Essencial: continuam vendo 3 trechos religiosos e usando o fluxo de pausa, mas não acionam chamadas remotas de IA nem narração.

## Modelo Comercial

- Modelo padrão: `gpt-4.1-mini`.
- O modelo só deve ser alterado via `OPENAI_MODEL` no Vercel.
- Modelo de voz padrão: `gpt-4o-mini-tts`.
- O modelo de voz só deve ser alterado via `OPENAI_TTS_MODEL` no Vercel.
- Voz padrão: `coral`, com velocidade inicial `0.92` para uma narração mais calma.
- A leitura principal usa 3 textos espirituais/religiosos e uma reflexão final.
- Usuários em teste gratuito ativo e assinantes geram conteúdo remoto sempre que o app entra em primeiro plano.
- Não há limite diário de geração remota no produto.
- O backend mantém apenas rate limit por janela para proteção básica contra abuso ou loops.
- A narração usa áudio gerado no backend, sem expor a chave no app iOS.
- No Modo Essencial, a interface oculta áudio e reflexões por IA para evitar custo remoto.

## Segurança

- A chave da OpenAI nunca fica no app iOS.
- O app não envia seleção dos apps que ativam o Limiar, email, localização, contatos ou identificadores pessoais.
- O backend recebe apenas tradição, preferências espirituais, profundidade, trechos e histórico recente resumido.
- As chamadas para OpenAI usam `store: false`.

## Variáveis no Vercel

- `OPENAI_API_KEY`: chave da OpenAI usada somente no backend.
- `OPENAI_MODEL`: modelo leve configurável. Padrão: `gpt-4.1-mini`.
- `OPENAI_TTS_MODEL`: modelo econômico de voz. Padrão: `gpt-4o-mini-tts`.
- `OPENAI_TTS_VOICE`: voz da narração. Padrão: `coral`.
- `OPENAI_TTS_SPEED`: velocidade da narração. Padrão: `0.92`.
- `OPENAI_TIMEOUT_MS`: timeout do backend. Padrão: `12000`.
- `LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS`: limite por janela. Padrão: `24`.
- `LIMIAR_AI_RATE_LIMIT_WINDOW_MS`: janela do limite. Padrão: `900000`.

## Narração

A leitura em voz alta é feita com áudio remoto gerado por `POST /api/speech`.
O app iOS envia apenas o texto limpo, instruções de narração e velocidade para o backend, e recebe MP3.
A chave da OpenAI fica somente no Vercel.

## Testes

```bash
npm run test:ai-backend
```

Esse teste valida o contrato JSON do backend. Para QA no app, testar:

- geração remota com `OPENAI_API_KEY` configurada;
- ausência de limite diário na 7ª tentativa;
- mensagem simples sem internet;
- backend retornando erro;
- JSON inválido;
- profundidades curta, média e grande;
- retorno ao app depois de bloqueio;
- repetição reduzida com histórico recente;
- voz remota por `/api/speech`.
- Modo Essencial sem chamadas para `/api/spiritual-reading`, `/api/reflection` ou `/api/speech`.
