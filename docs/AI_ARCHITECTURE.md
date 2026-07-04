# Arquitetura de geração do Limiar

## Fluxo

1. O app iOS prepara candidatos de leitura conforme as preferências do usuário.
2. Para usuários no teste gratuito ativo ou com assinatura ativa, o app chama o backend:
   - `POST /api/spiritual-reading`
   - `POST /api/reflection`
   - `POST /api/speech`, somente quando a pessoa toca para ouvir um trecho específico.
3. O app envia uma lista maior de candidatos para o backend, e o modelo remoto escolhe 3 trechos para a jornada atual. Isso evita repetir sempre os primeiros trechos locais.
4. O backend gera texto com GPT-5.4 mini usando `OPENAI_API_KEY` em variável de ambiente.
5. O backend exige JSON estruturado e valida o resultado.
6. O app valida novamente o JSON recebido.
7. Se qualquer etapa falhar, o app mostra uma mensagem simples de indisponibilidade sem expor erro técnico.

Usuários com teste expirado e sem assinatura ativa entram no Modo Essencial: continuam vendo 3 trechos religiosos e usando o fluxo de pausa, mas não acionam chamadas remotas de reflexão nem narração. Anúncios não fazem parte da versão atual; a integração com Google AdMob deve entrar apenas em uma versão futura, depois da conta e dos IDs de anúncio estarem prontos.

## Modelo Comercial

- Modelo textual padrão: `gpt-5.4-mini`.
- O modelo textual só deve ser alterado via `OPENAI_MODEL` no Vercel.
- Modelo de voz padrão: `eleven_flash_v2_5`, opção econômica da ElevenLabs.
- O modelo de voz só deve ser alterado via `ELEVENLABS_TTS_MODEL` no Vercel.
- Voz masculina do app: `TxGEqnHWrfWFTfGW9XjX`, com velocidade inicial `0.92` para uma narração mais calma.
- A leitura principal usa 3 textos espirituais/religiosos.
- Usuários em teste gratuito ativo e assinantes geram conteúdo remoto sempre que o app entra em primeiro plano.
- Não há limite diário de geração remota no produto.
- O backend mantém apenas rate limit por janela para proteção básica contra abuso ou loops.
- A narração usa áudio gerado no backend por ElevenLabs, sem expor a chave no app iOS.
- A narração nunca é pré-gerada: `/api/speech` só deve ser chamado quando a pessoa toca no botão de ouvir de um trecho específico.
- No Modo Essencial, a interface oculta áudio e reflexões personalizadas para evitar custo remoto.
- No Modo Essencial, o app mantém a experiência reduzida sem narração e sem reflexões personalizadas. Anúncios ficam fora da versão atual.

## Segurança

- Chaves de provedores nunca ficam no app iOS.
- O app não envia seleção dos apps que ativam o Limiar, email, localização, contatos ou identificadores pessoais.
- O backend recebe apenas tradição, preferências espirituais, profundidade, trechos e histórico recente resumido.
- O app iOS não deve conter `OPENAI_API_KEY` ou `ELEVENLABS_API_KEY`.

## Variáveis no Vercel

- `OPENAI_API_KEY`: chave usada somente no backend.
- `OPENAI_MODEL`: modelo textual configurável. Padrão: `gpt-5.4-mini`.
- `OPENAI_BASE_URL`: base URL da API. Padrão: `https://api.openai.com/v1`.
- `OPENAI_TIMEOUT_MS`: timeout do backend. Padrão: `25000`. O app exibe os trechos assim que a primeira resposta remota chega, sem esperar chamadas complementares.
- `ELEVENLABS_API_KEY`: chave da ElevenLabs usada somente no backend.
- `ELEVENLABS_TTS_MODEL`: modelo econômico de voz. Padrão: `eleven_flash_v2_5`.
- `ELEVENLABS_VOICE_ID`: voz padrão do backend caso o cliente não envie uma voz. O app iOS envia explicitamente a voz masculina `TxGEqnHWrfWFTfGW9XjX`.
- `ELEVENLABS_TTS_SPEED`: velocidade da narração. Padrão: `0.92`.
- `ELEVENLABS_TTS_TIMEOUT_MS`: timeout da narração. Padrão: `12000`.
- `LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS`: limite por janela. Padrão: `24`.
- `LIMIAR_AI_RATE_LIMIT_WINDOW_MS`: janela do limite. Padrão: `900000`.

## Narração

A leitura em voz alta é feita com áudio remoto gerado por `POST /api/speech`.
O app iOS envia apenas o texto limpo do trecho escolhido, a voz masculina escolhida e a velocidade para o backend, e recebe MP3.
A chave da ElevenLabs fica somente no Vercel.

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
- retorno ao app depois da pausa;
- repetição reduzida com histórico recente;
- voz remota por `/api/speech` somente após toque no botão de ouvir de um trecho específico;
- Modo Essencial sem chamadas para `/api/spiritual-reading`, `/api/reflection` ou `/api/speech`.
- Modo Essencial sem chamadas remotas de reflexão, sem narração e sem anúncios nesta versão.
