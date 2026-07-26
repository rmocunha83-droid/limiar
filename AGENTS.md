# Limiar — contexto para agentes de código

Leia este arquivo antes de mexer no projeto. Ele existe para evitar mudanças que quebram a proposta do produto.

## O que é o Limiar

App iOS de fé publicado na App Store brasileira. Ele **bloqueia os apps que a pessoa escolheu** em um horário definido por ela (o "turno") e só os libera depois que ela completa a **travessia**: ler de 1 a 3 trechos bíblicos com explicações geradas por IA.

O público é adulto, brasileiro, religioso, e busca disciplina de atenção. A proposta é criar uma pausa espiritual antes do impulso de abrir o celular — não é um app de bloqueio genérico nem um devocional comum.

Quatro tradições atendidas: **católica, evangélica, judaica e cristã ampla**. A tradição escolhida determina o cânone, o vocabulário e o tom das explicações.

## Arquitetura

- **App iOS** em `Limiar/` — SwiftUI, FamilyControls/DeviceActivity/ManagedSettings para o bloqueio, app group `group.com.romeucunha.Limiar`
- **Backend serverless** em `api/` — Vercel, região `gru1`
- **Site institucional** na raiz (`index.html`, `privacy.html`, `terms.html`, `support.html`) — domínio `https://applimiar.com.br` (o antigo `limiar-five.vercel.app` continua respondendo)
- **Push em `main` = deploy automático do Vercel + build automática no Xcode Cloud**

### Não invente o que não existe

O Limiar **não tem contas de usuário, login, banco de dados nem sincronização entre aparelhos**. Tudo é local ao dispositivo. Se uma tarefa parecer exigir "o usuário logado" ou "buscar do banco", a premissa está errada — pergunte antes de construir.

## Guarda-rails

1. **A IA explica, nunca escolhe.** A seleção dos trechos é determinística, feita a partir do catálogo local. O modelo só recebe o trecho já escolhido e escreve a explicação. Não mova a escolha para o modelo.
2. **O bloqueio é sagrado.** Qualquer mudança em shield, DeviceActivity ou ManagedSettings precisa ser testada em aparelho real. Um bug aí deixa a pessoa presa fora dos próprios apps.
3. **Nunca compilar localmente para a App Store.** Use a compilação que o Xcode Cloud gera a cada push. Ver `docs/META_TRACKING_2026-07-24.md`, seção 6.
4. **Texto de narração é contrato.** O formato `"{referência}.\n{texto}"` precisa ser idêntico entre app, backend e pré-aquecimento, senão o cache de áudio quebra.
5. **Modo Essencial não chama o backend.** Ele mostra trechos e explicações do catálogo local e exibe anúncios do AdMob. Não introduza chamadas de rede nesse caminho.
6. **Privacidade é posicionamento.** Conteúdo espiritual, tradição, temas e a seleção de apps bloqueados **nunca** vão para publicidade ou medição. Ao mexer em rastreamento, atualize `privacy.html` e a ficha da App Store Connect junto.
7. **pt-BR em tudo que o usuário lê.** Inclusive nas mensagens de permissão do sistema.
8. **Sempre há caminho de saída.** Falha de rede, de IA ou de assinatura precisa degradar para a sessão local, nunca travar a travessia.

## Documentos de referência

Leia conforme a tarefa:

| Documento | Quando ler |
|---|---|
| `docs/AI_ARCHITECTURE.md` | Mexer em seleção de trechos, geração de explicações, narração ou cache |
| `docs/META_TRACKING_2026-07-24.md` | **Mexer em rastreamento, SDK da Meta, ATT, SKAdNetwork, `api/meta-capi.js` ou política de privacidade** |
| `docs/handoff-mudancas.md` | Panorama histórico das entregas |
| `docs/QA_CHECKLIST.md` | Antes de publicar |
| `docs/APP_STORE_CONNECT_CHECKLIST.md` | Submissão à loja |

## Monetização

Acesso inicial completo por tempo limitado → depois **Modo Essencial** (funcional, com anúncios) ou **Premium** (mensal/anual, via StoreKit). O Essencial não é uma versão quebrada: ele entrega a travessia inteira, só sem as explicações personalizadas e a narração.

## Estado atual (24/07/2026)

- Versão na loja: **1.10**; **1.11 (build 157)** aguardando revisão, com o rastreamento da Meta em modo completo
- Domínio `applimiar.com.br` no ar, verificado no Meta Business Manager
- E-mail de contato oficial: `contato@applimiar.com.br`
