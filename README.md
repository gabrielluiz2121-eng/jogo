# Jogo – Protótipo 1 (protótipo cinza)

Primeiro protótipo do jogo das ilhas flutuantes. Ainda **sem arte**: tudo é feito de
cubos, cilindros e esferas. O objetivo é só um: **descobrir se o ciclo principal é divertido**.

> colher flor mágica → secar no varal → vender o chá ao barco mercador →
> encomendar materiais → construir uma ponte para a próxima ilha

## Como abrir e jogar

1. Baixe o **Godot 4** (versão 4.3 ou mais nova, a versão normal, não a ".NET"):
   <https://godotengine.org/download>. Não precisa instalar, é só descompactar e abrir.
2. Baixe este repositório (botão verde **Code → Download ZIP** no GitHub) e descompacte.
3. Abra o Godot. Na tela de projetos, clique em **Importar** e escolha o arquivo
   `project.godot` desta pasta.
4. Com o projeto aberto, aperte **F5** (ou o botão ▶ no canto superior direito) para jogar.

Na primeira vez o Godot leva alguns segundos “importando” o projeto. É normal.

## Controles

| Tecla | Ação |
|---|---|
| W A S D (ou setas) | Andar |
| Shift | Correr |
| Espaço | Pular |
| Mouse | Girar a câmera |
| Roda do mouse | Aproximar/afastar a câmera |
| E | Interagir (colher, usar o varal, negociar, construir) |
| T (segurar) | Acelerar o tempo, para ver o dia virar noite |
| Esc | Soltar o mouse / fechar a loja (clique na tela para prender de novo) |

## O que tem neste protótipo

- **Ilha principal** com dois níveis de altura (um morro com rampa), trilha de terra,
  árvores e flores mágicas rosas. Se cair da beirada, você volta para o último chão firme.
- **Personagem** camponês (corpo azul, chapéu de palha, mochila) com câmera em terceira pessoa.
- **Mochila**: carrega até 12 flores, mais chá, moedas, tábuas e cordas (canto superior esquerdo).
- **Varal de secagem**: pendure flores; cada uma vira um pacote de chá em 5 segundos.
- **Barco mercador** (junco voador com uma criatura a bordo): chega no cais de tempos em
  tempos (o tempo aparece no canto superior direito). Ele compra seu chá e você encomenda
  tábuas e cordas, que **chegam na visita seguinte**.
- **Ponte de corda**: na beirada leste da ilha há uma obra marcada. Com 8 tábuas e 4 cordas,
  aperte E para construir e atravessar para a **segunda ilha**, que tem flores azuis.

As flores colhidas nascem de novo depois de 40 segundos.

## Visual de aquarela e nanquim

O jogo agora tenta se aproximar das artes conceituais:

- **Filtro de pintura** na tela inteira (`shaders/tela_aquarela.gdshader`): contorno de nanquim
  que treme e falha como pincel, tinta acumulada nas bordas das cores, textura de papel e
  um leve "sangramento" da aquarela.
- **Material de aquarela** nos objetos (`shaders/aquarela.gdshader`): cores chapadas em duas
  faixas de luz, sombras azuladas e manchas de pigmento. As rochas são deformadas para
  parecerem irregulares.
- **Céu pintado** (`shaders/ceu.gdshader`) com raios de sol, manchas de nuvem e estrelas.
- **Mar de nuvens** em várias camadas que andam com o vento (`shaders/nuvens.gdshader`),
  neblina densa lá embaixo e picos de pedra no horizonte.
- **Ciclo de dia e noite** (`scripts/ciclo.gd`): amanhecer dourado, dia, entardecer e noite
  azul com estrelas; lanternas e flores brilham mais à noite. Um dia dura 8 minutos.
- **Camponês 3D** feito no Meshy e animado no Mixamo (`personagem/`, `scripts/personagem.gd`):
  parado, andar, correr, pular e colher. Para voltar ao boneco simples, mude
  `USAR_MODELO_3D` para `false` em `scripts/jogador.gd`.
- Boneco simples antigo (formas) baseado na folha de conceito (`scripts/campones.gd`): chapéu cônico, túnica com lapela de linho, faixa, calça dobrada, sandálias e cesto de bambu com ferramentas e plantas. Tem animação de andar, correr, pular e colher.
- Pinheiros tortos com copas achatadas, raízes penduradas sob as ilhas e cachoeiras.

Para comparar com e sem o filtro, mude `ATIVO` para `false` em `scripts/estilo.gd`.

## Trocar ou adicionar animações do personagem

1. Baixe do Mixamo em **FBX, With Skin** (andar e correr com **In Place**).
2. Coloque em `personagem/fontes/` com os nomes `parado.fbx`, `andar.fbx`, `correr.fbx`,
   `pular.fbx` e `colher.fbx` (essa pasta não vai para o GitHub porque os arquivos são grandes).
3. No terminal, dentro da pasta do projeto, rode:
   `godot --headless --import` e depois `godot --headless -s res://ferramentas/importar_animacoes.gd`.
   Isso gera `personagem/animacoes.res`, que o jogo usa.

## Onde ajustar o ritmo

Os números que mudam o “sentir” do jogo estão no começo dos scripts:

- `scripts/jogo.gd`: preços e capacidade da mochila.
- `scripts/mercador.gd`: de quanto em quanto tempo o barco vem e quanto tempo fica.
- `scripts/secador.gd`: tempo para secar cada flor.
- `scripts/flor.gd`: tempo para a flor nascer de novo.
- `scripts/ponte.gd`: custo da ponte.
- `scripts/jogador.gd`: velocidade, pulo e sensibilidade do mouse.
- `scripts/ciclo.gd`: duração do dia, hora inicial e as cores de cada parte do dia.
- `scripts/estilo.gd`: liga/desliga o filtro e a cor do nanquim.

## Como o código está organizado

O mundo inteiro é montado por código em `scripts/main.gd` (posições das ilhas, rampa,
trilha, árvores, flores, cais e ponte). Isso deixa fácil mexer em números enquanto a
ideia ainda está mudando. Quando a arte chegar, cada peça vira uma cena própria no editor.

```
project.godot      configuração do projeto
main.tscn          cena principal (só chama scripts/main.gd)
scripts/
  jogo.gd          estado global: mochila, moedas, encomenda, controles
  main.gd          monta o mundo
  jogador.gd       movimento e câmera
  hud.gd           textos na tela e loja do mercador
  interagivel.gd   base de tudo que usa a tecla E
  flor.gd, secador.gd, mercador.gd, ponte.gd
  util.gd          ajudantes para criar formas
  ciclo.gd         dia e noite
  estilo.gd        liga o filtro de aquarela na câmera
shaders/           aquarela, filtro da tela, céu, nuvens e cachoeira
```

## Perguntas para testar

Enquanto joga, repare:

- Colher e secar é gostoso ou fica repetitivo rápido?
- Esperar o barco dá vontade de explorar ou dá tédio?
- Construir a ponte e atravessar dá aquela sensação de “conquista”?
- Quanto tempo levou da primeira flor até a segunda ilha?
