# Limiar

Limiar é um app iOS em SwiftUI para criar uma pausa espiritual antes de voltar a apps de distração. A pessoa escolhe quais apps vão ativar o Limiar, lê uma jornada religiosa e, depois de concluir com calma, retoma o uso com mais presença.

## Funcionalidades

- Onboarding com estética visual do Limiar e preferências espirituais.
- Tradições: católica, evangélica, judaica e espírita.
- Seleção de apps que ativam o Limiar usando recursos nativos do iOS.
- Exibição dos apps selecionados apenas por ícones originais, sem nome, horário ou descrição.
- Tela inicial com jornada de leitura e três trechos religiosos por sessão.
- Rotação local de trechos para evitar que o mesmo texto fique preso quando o app permanece aberto.
- Reflexões personalizadas via backend próprio, com GPT-5.4 mini no servidor, histórico antirrepetição e fallback local.
- Explicação espiritual por trecho, com resumo, aplicação prática e pergunta de meditação.
- Histórico local de leituras e opção individual de salvar cada trecho.
- Narração premium via Azure Cognitive Services Speech no backend seguro, acionada apenas quando a pessoa toca em ouvir; ElevenLabs permanece disponível como alternativa por configuração.
- Botão “Li com calma, continuar” com ícone positivo e retorno temporário aos apps selecionados.
- Modo Essencial após o teste gratuito: mantém os 3 trechos principais, explicações essenciais e o fluxo de pausa, com anúncios e sem narração.
- Preview web e materiais de marketing/App Store.

## Requisitos

- Xcode 26.5 ou superior.
- iOS 17 ou superior.
- Conta Apple Developer adicionada no Xcode.
- Perfis de desenvolvimento para o app e extensões:
  - `com.romeucunha.Limiar`
  - `com.romeucunha.Limiar.DeviceActivityMonitorExtension`
  - `com.romeucunha.Limiar.ShieldActionExtension`
  - `com.romeucunha.Limiar.ShieldConfigurationExtension`

## Observação de linguagem

Todos os textos visíveis e textos gerados para o usuário devem usar português brasileiro com acentuação correta.

## Reflexões personalizadas

O app iOS chama os endpoints em `api/` e nunca carrega chaves de provedores no cliente. Configure `OPENAI_API_KEY` no Vercel para geração textual. Para narração, o padrão é Azure Speech: `AZURE_SPEECH_KEY`, `AZURE_SPEECH_REGION=brazilsouth`, `AZURE_SPEECH_VOICE=pt-BR-AntonioNeural` e `TTS_PROVIDER=azure`. O app publicado ainda pode enviar um ID de voz do ElevenLabs, mas ele é ignorado quando Azure está ativo. Para reverter sem alterar o app, defina `TTS_PROVIDER=elevenlabs` e mantenha `ELEVENLABS_API_KEY` (mais `ELEVENLABS_VOICE_ID`, `ELEVENLABS_TTS_MODEL` e `ELEVENLABS_TTS_SPEED`, se desejado). Usuários em teste gratuito ativo e assinantes usam a experiência completa; usuários no Modo Essencial não geram chamadas remotas de reflexão nem narração e veem anúncios do AdMob. A arquitetura está detalhada em `docs/AI_ARCHITECTURE.md`.

### Pré-aquecimento da narração

Os trechos fixos usam o formato canônico `"{reference}.\n{text}"`, usado de modo idêntico pelo app e pelo cache Vercel Blob. Para preencher o catálogo, execute `npm run prewarm:narration` com `AZURE_SPEECH_KEY`, `AZURE_SPEECH_REGION` e `BLOB_READ_WRITE_TOKEN`. O script é idempotente, processa de 3 a 5 itens em paralelo e só sintetiza itens ausentes.
