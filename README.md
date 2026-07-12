# Jogo da Vida em Linguagem Funcional

## Introdução
Este relatório documenta o desenvolvimento e a implementação do Jogo da Vida de Conway através de uma Interface de Utilizador de Terminal (TUI - Terminal User Interface). O projeto foi construído utilizando a linguagem Haskell e o framework declarativo Brick. O objetivo principal deste trabalho é demonstrar a viabilidade prática do paradigma funcional na engenharia de sistemas interativos e demonstrar possíveis vantagens de Haskell em relação a linguagens imperativas convencionais.


## Guia de Execução e Uso

### Pré-Requisitos
Como pré-requisito é necessário instalar:

- [haskell](https://www.haskell.org/downloads/)
- [stack](https://docs.haskellstack.org/en/stable/)

### Instalação
1. Clone o repositório
```bash
git clone https://github.com/theoluiging/functional-game-of-life.
```

2. No diretório do repositório, compile o projeto
```bash
stack build
```

3. Execute o projeto
```bash
stack run
```

### Controles

A tabela abaixo detalha o mapeamento dos inputs capturados pelo jogo:

| Tecla | Ação |
| :--- | :--- |
| Setas ou WASD | Mover o cursor |
| ESPAÇO | Inverter estado da célula (viva/morta) |
| ENTER | Pausar / Retomar a simulação |
| T | Avançar uma geração manualmente |
| R | Recomeçar (limpar tabuleiro) |
| Q ou ESC | Sair do jogo |

## O Jogo da Vida de Conway
Criado pelo matemático John Horton Conway em 1970, o Jogo da Vida é o exemplo mais bem conhecido de um autómato celular. Classificado como um "jogo sem jogador", o que quer dizer que sua evolução é determinada pelo seu estado inicial, não necessitando de nenhuma entrada de jogadores humanos.

O jogo da vida se passa em um arranjo bidimensional infinito de células que podem estar em um de dois estados, vivo ou morto. Cada célula interage com suas oito vizinhas, as células adjacentes horizontal, vertical e diagonalmente. O jogo evolui em unidades de tempo discretas chamadas de gerações. A cada nova geração, o estado do jogo é atualizado pela aplicação das seguintes regras:

1. Toda célula morta com exatamente três vizinhos vivos torna-se viva (nascimento).
2. Toda célula viva com menos de dois vizinhos vivos morre por isolamento.
3. Toda célula viva com mais de três vizinhos vivos morre por superpopulação.
4. Toda célula viva com dois ou três vizinhos vivos permanece viva (sobrevivência).

As regras são aplicadas simultaneamente em todas as células para chegar ao estado da próxima geração.

## Bibliotecas
No desenvolvimento do projeto, foram utilizadas três bibliotecas do ecossistema Haskell:

- **Vty:** Biblioteca para interação de baixo nível com o terminal. Utilizada para capturar as teclas do teclado.

- **Brick:** Framework declarativo para criação de interfaces de terminal.
Em vez de ditar manualmente ao computador como redesenhar ou limpar partes específicas da tela (abordagem imperativa), o programador apenas declara o que a tela deve conter com base no estado atual.  
Utilizada em conjunto com Vty para capturar inputs e renderizar a interface do usuário.  

- **Microlens:** Biblioteca para manipulação elegante de estado imutável. 
Devido à imutabilidade do Haskell, atualizar um campo profundamente aninhado exige a recriação manual de toda a estrutura envolvente. As Lenses permitem emular funcionalidades getters e setters de linguagens imperativas, utilizada para alterar campos do estado do jogo com maior facilidade

## Arquitetura do Sistema
Para fins de organização, a arquitetura do sistema foi dividida em módulos de responsabilidades isoladas. Os módulos e suas responsabilidades são:

### Mechanics.hs
Este módulo define o núcleo estrutural do jogo, contendo os tipos de dados fundamentais e as regras que regem o sistema de coordenadas e a manipulação do estado de jogo.

#### Sistema de Coordenadas
A base do sistema de coordenadas se dá pela definição do tipo `type Coord = (Int, Int)`, por ela é possível representar a posição da mira e de cada célula viva do tabuleiro.

Foram definidos também valores para as dimensões do tabuleiro (`width:: Int` e `height:: Int`) e a função `limitCoord` (definida abaixo) para limitar uma coordenada dentro dos confins do tabuleiro com efeito *wrap-around*.

```Haskell
limitCoord:: Coord -> Coord
limitCoord (x,y) = (newX, newY)
    where
        newX = x `mod` width
        newY = y `mod` height
```

#### GameState
O estado global do jogo é centralizado no tipo `GameState`, cujos campos incluem a posição da mira (`_cursorPos:: Coord`), o estado de pausa (`_gamePaused:: Bool`) e o vetor de células vivas (`_liveCells:: [Coord]`). O uso da macro `makeLenses ''GameState` gera automaticamente as lentes necessárias.

O estado inicial foi definido como `initialState :: GameState`, ele é inicializado com o vetor de células vazio e com `_gamePaused=True`.

#### Movimentação do Cursor e Ativação de Células
A movimentação do cursor implementa a função `moveCursor`, mapeada através de uma estrutura de dados customizada para as direções `data Direction = U | D | L | R`. Para mitigar o desaparecimento do cursor, foi desenvolvida a função pura `limitCursor:: GameState -> GameState`, que aplica a função `limitCoord`, fazendo com que o cursor reapareça no extremo oposto do tabuleiro ao cruzar as bordas da tela.

Para permitir que o usuário possa selecionar quais células deseja manter vivas ou mortas antes da simulação, foi criada a função `toggleCell:: Coord -> [Coord] -> [Coord]`, que recebe a coordenada atual do cursor e a lista de células vivas. Se a coordenada atual da mira já existir na lista de células vivas, o elemento é removido através de uma aplicação de `filter (/= c)`; caso contrário, a coordenada é anexada à cabeça da lista através do construtor de listas (`:`).

### Logic.hs
Neste módulo reside a lógica matemática que governa as regras do jogo de Conway. A decisão de design mais crítica do projeto foi a rejeição de um modelo tradicional de Matriz Densa em favor de um modelo de Matriz Esparsa. Em vez de alocar uma matriz fixa e iterar sobre milhares de células mortas e redundantes a cada iteração ($O(W \times H)$), o estado armazena apenas uma lista simples contendo as coordenadas das células que estão efetivamente vivas: `[Coord]`. 

O mais interessante desta abordagem é que ela permite, com modificações mínimas, uma simulação em tabuleiro infinito do Jogo da Vida. Se aproveitando da avaliação preguiçosa de listas infinitas, natural da linguagem Haskell.

#### Cálculo dos Vizinhos
A função `neighbors:: Coord -> [Coord]` recebe uma coordenada, e por meio de *list comprehension* retorna a lista das posições de seus vizinhos, limitada ao tabuleiro. Ela é definida como:
```Haskell
neighbors (x,y) = [limitCoord (x + dx, y + dy) |
 dx <- [-1, 0, 1],
 dy <- [-1, 0, 1], 
 (dx, dy) /= (0, 0)]
```
Por essa definição fica claro como a aplicação do termo `limitCoord` resulta na limitação de todo tabuleiro aos confins delimitados em `Mechanics.hs`. A remoção desse único termo da expressão resulta em uma simulação infinita do Jogo da Vida, onde as listas podem crescer indefinidamente.

#### Algoritmo de Gerações
Para calcular o próximo passo do algoritmo, foi criada a função `nextStep :: [Coord] -> [Coord]`, que recebe a lista de células vivas de `GameState`, aplica o algoritmo e retorna a lista de células vivas da próxima iteração.

A otimização de matriz esparça mencionada anteriormente se dá pela sequência:
```Haskell
allNeighbors = concatMap neighbors liveCells
candidates = nub (liveCells ++ allNeighbors)
```
Essa sequência encontra a lista com todos os vizinhos de todas as células vivas e soma com a lista de todas as células vivas. E então a função nub remove os itens repetidos desta soma.

Desta forma podemos aplicar as regras do Jogo diretamente na lista dos candidatos a serem transformados, e dela podemos usar a função `filter` para extrair uma nova lista de `liveCells`.

### UI.hs
O módulo de visualização é puramente declarativo. Ele aceita o `GameState` imutável e renderiza a representação visual da interface através da construção de estruturas combinatórias de `Widgets`, declaradas na biblioteca Brick.

A função `drawUI` coordena a montagem visual da aplicação empilhando elementos verticalmente através dos combinadores `vBox`. O tabuleiro é encapsulado pela função `borderWithLabel` da biblioteca Brick, adicionando molduras definidas automaticamente.

```Haskell
borderedGrid = borderWithLabel (str "Conway's Game of Life") . drawGrid
```

A montagem dos elementos internos do tabuleiro é feita por uma combinação de linhas empilhadas verticalmente com `vBox`, por sua vez cada linha é composta por uma combinação de células sequenciadas horizontalmente com `hBox`. Abaixo do tabuleiro de simulação, um painel horizontal construído com `hBox` renderiza de forma estática o menu de controles e comandos da aplicação.

### Main.hs
O ponto de entrada da aplicação (`main :: IO ()`) gerencia os efeitos colaterais e é responsável pela thread secundária necessária para o avanço automático das gerações da simulação.

A função `handleEvent` intercepta os inputs através de pattern matching estruturado na mônada de estado do Brick (`EventM`). O uso combinado das lentes e de *do notation* permitiu a escrita de ações sequenciais limpas e intuitivas. Ela também é responsável por capturar os eventos de `Tick` necessários para a passagem de tempo.

O terminal por padrão bloqueia a execução à espera de ações do usuário. Para permitir o avanço do tempo de forma assíncrona, o projeto utiliza da concorrência nativa do Haskell. Foi criada uma thread secundária através da função `forkIO` atuando como um metrônomo. Esta thread roda em plano de fundo de forma perpétua, aguarda um intervalo de tempo determinado via `threadDelay 500000` (0.5 segundos) e envia um evento customizado do tipo `Tick` num canal de comunicação assíncrono (`BChan` da biblioteca Brick).

O loop principal intercepta as mensagens do canal através do construtor de eventos `AppEvent Tick`. Caso o estado `_gamePaused` seja `False`, a função `handleEvent` executa automaticamente a transição para a próxima geração invocando a função `nextStep`, completando o ciclo interativo do programa.

## Conclusão
A implementação do Jogo da Vida de Conway através de uma interface de terminal em Haskell provou ser um excelente exercício prático de engenharia de software funcional. A transição da mentalidade imperativa (focada em loops indexados e mutação direta de matrizes na memória) para a mentalidade funcional (focada em transformações de coleções de dados, imutabilidade e mapeamentos declarativos) resultou num sistema consideravelmente mais limpo e conciso.

A arquitetura esparsa adotada no módulo lógico demonstra o poder das funções de alta ordem (`filter`, `concatMap`) em simplificar otimizações que seriam verbosas e propensas a erros de indexação em linguagens tradicionais. Adicionalmente, a utilização de *list comprehension* para a geração de vizinhos no algoritmo demonstra a vantagem única da linguagem, ao ser possível fazer uso de listas infinitas com o intuito de gerar uma simulação em plano ilimitado sem muita dificuldade.

Por fim, as abstrações fornecidas pelas bibliotecas Brick e Lenses provaram que é possível mitigar a rigidez sintática associada à imutabilidade do Haskell, produzindo um código limpo, de leitura fluida e modular.

## Referências

1. [ Writing a Solitaire TUI with Lenses and Brick. JBuckland Blog](https://jbuckland.com/blog/game-solitaire/)
2. [Jogo da vida. Wikipedia](https://pt.wikipedia.org/wiki/Jogo_da_vida)
3. [FP BLOCK. Building Terminal User Interfaces with Haskell](https://www.youtube.com/watch?v=qbDQdXfcaO8)
4. [BRICK: A declarative terminal user interface library](https://hackage.haskell.org/package/brick)
5. [MICROLENS: A tiny lens library with no dependencies](https://hackage.haskell.org/package/microlens)
