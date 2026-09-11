# Expansão local do catálogo — setembro de 2026

| Tradição | Anterior | Adicionados | Total |
| --- | ---: | ---: | ---: |
| Católica | 314 | 136 | 450 |
| Evangélica | 314 | 136 | 450 |
| Judaica | 189 | 261 | 450 |
| Espírita | 160 | 290 | 450 |
| Total | 977 | 823 | 1.800 |

As 977 entradas anteriores permanecem idênticas, na mesma ordem, com seus IDs,
referências e textos preservados. A expansão é exclusivamente de conteúdo,
ferramentas de curadoria e testes. Não exige migração de preferências, histórico,
favoritos ou sessão diária. Não muda os serviços, onboarding, site ou layout.

Os novos textos vêm da Bíblia Livre 2018.2.0, com referência, fonte e atribuição
identificadas. O script confere cada versículo contra um arquivo de fonte com
checksum fixo. Livro e tradição são definidos explicitamente. As referências
novas não se sobrepõem aos intervalos legados reconhecidos, nem entre si dentro
da mesma tradição. Referências de capítulo inteiro bloqueiam novos recortes do
mesmo capítulo. A validação anterior não detectava algumas classificações
legadas inconsistentes; esta entrega não altera ou certifica essas entradas.

Há ao menos 180 entradas elegíveis nas categorias padrão de cada tradição,
verificadas pelo seletor Swift real. Isso dá capacidade teórica para 90 sessões
de dois trechos distintos por ID, partindo de histórico vazio. Não é uma promessa
de 90 dias para toda combinação de livros/temas, para pessoas com histórico já
consumido, nem de ausência de similaridade entre passagens bíblicas. Combinações
mais restritas continuam tendo menos conteúdo. A expansão de deuterocanônicos
fica para um lote com fonte própria; a edição BLIVRE utilizada não os contém.

Validação desta entrega:

- Sete testes offline: preservação integral do legado, reprodução do lote,
  atribuição, livro/tradição, sobreposição e rejeição de adulteração de texto ou
  referência.
- 23 testes iOS aprovados, incluindo decodificação do JSON empacotado, filtros
  reais de cada perfil padrão e seleção de conteúdo novo com histórico antigo.
- Validador do catálogo com checagem automática da expansão contra a fonte.
  Alguns recortes mantêm 71–100 palavras para preservar contexto; são avisos
  editoriais do validador, não erros de esquema.

Estado: implementado e testado localmente. Nenhuma publicação ou pré-geração de
áudio foi executada. O catálogo chegará aos usuários em uma próxima build iOS.
Os créditos e a reprodução estão em `scripts/catalog-sources/README.md`.
