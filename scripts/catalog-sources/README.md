# Fonte da expansão do catálogo

- Obra: Bíblia Livre (BLIVRE), fevereiro de 2018, variante Nestle 1904 (n4).
- Autores: Diego Santos, Mario Sérgio e Marco Teles.
- Fonte primária: https://github.com/blivre/BibliaLivre/releases/tag/2018.2.0
- Arquivo original: https://github.com/blivre/BibliaLivre/releases/download/2018.2.0/bliv-n4_vpl.zip
- SHA-256: `676e8d1efea3f576f1ae716fc0b3b7b37085c3d59c5e72daaea409ae083968e5`.
- Licença declarada pela edição: Creative Commons Atribuição 3.0 Brasil,
  https://creativecommons.org/licenses/by/3.0/br/.
- Crédito da fonte: https://github.com/blivre/BibliaLivre/blob/master/README.md#como-dar-crédito-à-bíblia-livre.

Todas as novas citações com identificador `blivre-2018-` são dessa edição.
As entradas anteriores não recebem essa atribuição: sua fonte não foi
reconstruída nesta expansão. Cada nova entrada contém os créditos completos
no campo `source`, empacotado no JSON do aplicativo, e identifica BLIVRE na
referência visível. A fonte permite a sigla quando o espaço é limitado.

O texto é extraído de versículos existentes, sem geração por IA. São preservadas
as palavras da tradução, incluindo as originalmente entre colchetes. São removidos
apenas esses colchetes, os rótulos alfabéticos do Salmo 119 e o título
"Cântico dos degraus"; espaços de pontuação são normalizados. Os versículos
de cada intervalo são unidos por espaço. Essas transformações são declaradas
em `source.changes`. Títulos curtos e temas são metadados editoriais do Limiar.

`selection.tsv` contém a lista editorial de candidatos. O script reserva todo
capítulo que uma referência anterior cita sem versos e exclui interseções de
versículos na mesma tradição, inclusive com prefixos hebraicos e pontuação
diferente. Também exclui textos idênticos dentro da tradição. Esses controles
não certificam a exatidão editorial das 977 entradas legadas.

A primeira expansão escolhe 823 candidatos, balanceando tradições (450 entradas
por tradição), livros e temas. Primeiro assegura 180 entradas elegíveis nas
categorias padrão de cada tradição; depois reforça livros e temas menores.
Referências iguais em tradições diferentes são permitidas, pois o usuário
recebe apenas a tradição escolhida. Não significam 1.800 referências universais
distintas. O texto do Antigo Testamento usa a edição identificada acima,
sem acrescentar interpretação cristã ao perfil judaico.

## Reprodução offline

```sh
python3 scripts/expand_passages.py          # relatório, sem gravar
python3 scripts/expand_passages.py --write  # reconstroi apenas o lote com prefixo
python3 scripts/validate_passages.py        # inclui comparação com a fonte
python3 -m unittest discover -s scripts -p 'test_catalog_expansion.py'
```

O ZIP é material de desenvolvimento; não é recurso do target iOS. A rede não
participa da seleção ou da leitura local. Para um lote futuro, preserve também
os IDs e os textos deste lote: não altere a seleção já distribuída para trocar
entradas antigas por outras. O script é para reproduzir esta expansão, não um
atualizador remoto nem um substituto de revisão editorial.
