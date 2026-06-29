# Arquitetura de IA do Limiar

## Fluxo

1. O app iOS prepara candidatos de leitura conforme as preferências do usuário.
2. Para usuários no teste gratuito ativo ou com assinatura ativa, o app chama o backend:
   - `POST /api/spiritual-reading`
   - `POST /api/reflection`
   - `POST /api/speech`, somente quando a pessoa toca para ouvir a leitura.
3. O backend gera texto com GLM-4.5-Air usando `GLM_API_KEY` ou `ZAI_API_KEY` em variável de ambiente.
4. O backend exige JSON estruturado e valida o resultado.
5. O app valida novamente o JSON recebido.
6. Se qualquer etapa falhar, o app mostra uma mensagem simples de indisponibilidade sem expor erro técnico.

Usuários com teste expirado e sem assinatura ativa entram no Modo Essencial: continuam vendo 3 trechos religiosos e usando o fluxo de pausa, mas não acionam chamadas remotas de IA nem narração.

## Modelo Comercial

- Modelo textual padrão: `glm-4.5-air`.
- O modelo textual só deve ser alterado via `GLM_MODEL` ou `ZAI_MODEL` no Vercel.
- Modelo de voz padrão: `eleven_flash_v2_5`, opção econômica da ElevenLabs.
- O modelo de voz só deve ser alterado via `ELEVENLABS_TTS_MODEL` no Vercel.
- Voz padrão: `21m00Tcm4TlvDq8ikWAM`, com velocidade inicial `0.92` para uma narração mais calma.
- A leitura principal usa 3 textos espirituais/religiosos.
- Usuários em teste gratuito ativo e assinantes geram conteúdo remoto sempre que o app entra em primeiro plano.
- Não há limite diário de geração remota no produto.
- O backend mantém apenas rate limit por janela para proteção básica contra abuso ou loops.
- A narração usa áudio gerado no backend por ElevenLabs, sem expor a chave no app iOS.
- A narração nunca é pré-gerada: `/api/speech` só deve ser chamado quando a pessoa toca no botão de ouvir.
- No Modo Essencial, a interface oculta áudio e reflexões por IA para evitar custo remoto.

## Segurança

- Chaves de IA nunca ficam no app iOS.
- O app não envia seleção dos apps que ativam o Limiar, email, localização, contatos ou identificadores pessoais.
- O backend recebe apenas tradição, preferências espirituais, profundidade, trechos e histórico recente resumido.
- O app iOS não deve conter `GLM_API_KEY`, `ZAI_API_KEY` ou `ELEVENLABS_API_KEY`.

## Variáveis no Vercel

- `GLM_API_KEY`: chave do provedor GLM/Z.ai usada somente no backend.
- `ZAI_API_KEY`: alternativa para a mesma chave, caso prefira nomear pelo provedor.
- `GLM_MODEL` ou `ZAI_MODEL`: modelo textual configurável. Padrão: `glm-4.5-air`.
- `GLM_BASE_URL` ou `ZAI_BASE_URL`: base URL da API. Padrão: `https://api.z.ai/api/paas/v4`.
- `GLM_TIMEOUT_MS` ou `ZAI_TIMEOUT_MS`: timeout do backend. Padrão: `12000`.
- `ELEVENLABS_API_KEY`: chave da ElevenLabs usada somente no backend.
- `ELEVENLABS_TTS_MODEL`: modelo econômico de voz. Padrão: `eleven_flash_v2_5`.
- `ELEVENLABS_VOICE_ID`: voz da narração. Padrão: `21m00Tcm4TlvDq8ikWAM`.
- `ELEVENLABS_TTS_SPEED`: velocidade da narração. Padrão: `0.92`.
- `ELEVENLABS_TTS_TIMEOUT_MS`: timeout da narração. Padrão: `12000`.
- `LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS`: limite por janela. Padrão: `24`.
- `LIMIAR_AI_RATE_LIMIT_WINDOW_MS`: janela do limite. Padrão: `900000`.

## Narração

A leitura em voz alta é feita com áudio remoto gerado por `POST /api/speech`.
O app iOS envia apenas o texto limpo e a velocidade para o backend, e recebe MP3.
A chave da ElevenLabs fica somente no Vercel.

## Testes

```bash
npm run test:ai-backend
```

Esse teste valida o contrato JSON do backend. Para QA no app, testar:

- geração remota com `GLM_API_KEY` ou `ZAI_API_KEY` configurada;
- ausência de limite diário na 7ª tentativa;
- mensagem simples sem internet;
- backend retornando erro;
- JSON inválido;
- profundidades curta, média e grande;
- retorno ao app depois da pausa;
- repetição reduzida com histórico recente;
- voz remota por `/api/speech` somente após toque no botão de ouvir;
- Modo Essencial sem chamadas para `/api/spiritual-reading`, `/api/reflection` ou `/api/speech`.
