# Plano do Modo RPG

**Pedido do usuário:**
- **15/11:** um modo opcional em que a experiência dá níveis e cada nível dá pontos para deixar o personagem mais forte. Na tela aparece o nível ("Nv 5") e, com pontos livres, "Nv 5+1". **Velocidade fica de fora**: mexer nela quebra golpes, combos e colisões.
- **15/11, à noite:**
  - O nível sai do **XP ganho**, o mesmo XP que compra golpes, somado ao longo do jogo (comprar golpe não tira nível).
  - Curva por XP: do nível 1 para o 2 custa 300, depois 400, depois 550, e assim vai.
  - Subir de nível e distribuir pontos fica no R3, ao lado do menu Gráfico: subiu de nível, pausa, R3 e distribui. Redistribuir é livre.
  - **O modo só se escolhe ao começar um jogo do zero.** Um save normal nunca vira RPG no meio.
  - **A tela de load/save mostra quais saves são RPG** (uma tag em cima do save).
  - **Um save RPG fica RPG para sempre:** a pessoa não muda mais.
  - **Perto do nome do personagem, na tela de jogo:** o nível e quanto falta para o próximo, tipo "0/300" no começo, mudando com o tempo.
  - **O RPG é sempre no Hard** (sem Normal), e o começo deve ser **mais difícil que o Hard**, porque o jogador fica muito forte a longo prazo.
  - **Mais atributos:** só três parece pouco. Dos propostos, tirar o Crítico; manter o resto. 1 ponto por nível por enquanto.
  - **Nível máximo geral: 100.**
  - **Ativar na tela de dificuldade com L3, com o cursor no Hard,** e a marca "RPG" em cima do Hard: para ficar claro que o RPG é uma variante do Hard.

**Como usar este plano:**
- Faça as tarefas da seção 7 **na ordem, uma por vez**, no formato de cada uma (Faça / Verifique / Pronto quando).
- Ao terminar uma tarefa, marque `[x]` e anote nela os endereços e números medidos.
- Leia antes o `ARQUITETURA.md` (threads, janela, armadilhas) e a N21 do `PLANO_DESEMPENHO.md` (menu Gráfico: tela por cima, detecção do estado do jogo pela RAM, roteiro de teste).

---

## 1. Regras de ouro

1. **Modo desligado = jogo original, bit a bit.**
   - Nenhuma escrita na RAM do jogo e nenhum desvio de comportamento.
   - As funções trocadas (`runtime.replaceFunction`) chamam a original e retornam sem tocar em nada.
   - Prova na tarefa D1.
2. **O modo é do save, escolhido uma vez:** só na tela de dificuldade de um jogo novo. Não liga nem desliga depois (3.6).
3. **Arquivos do jogo intactos:** nada muda no WAD, no ELF nem no memory card. Tudo fica no runtime.
4. **O save continua o original:** abre num jogo sem o modo e num PS2. Os dados do RPG ficam num arquivo próprio (3.7).
5. **Sem velocidade:** nada que altere animação, movimento, hitbox ou quadros de golpe. O modo mexe só em dano, vida (máxima e atual), XP para o nível e na tela por cima.
6. **A economia do jogo não muda:** o jogo dá o mesmo XP, os golpes custam o mesmo e o saldo de XP gasta igual. O RPG só lê o XP (a Sabedoria de 3.3 acelera só o nível, não o saldo).
7. **Números ajustáveis sem recompilar:** chaves `RPG_*` no `mksm.ini` (lista em 3.10), lidas no começo do jogo.
8. **Regras do projeto** (`CLAUDE.md`):
   - Commits só do usuário.
   - Nada do jogo no git.
   - `PS2Recomp/` só por `scripts/atualizar_patches.sh`; arquivo novo entra no `patches/arquivos.txt`.
   - Diagnósticos temporários saem antes do commit.
   - **Header novo não entra no `ps2_runtime.h`**, para não recompilar os 13 mil arquivos gerados.

## 2. Vocabulário

| Termo | O que é |
|---|---|
| **XP saldo** | O número que o jogo mostra no HUD ("EXP") e no mapa. Sobe ao matar inimigos, desce ao comprar golpes. |
| **XP ganho** | Tudo o que o personagem ganhou desde o começo do jogo RPG. Só sobe. **É dele que sai o nível.** |
| **Nível** | Começa em 1. Função do XP ganho (curva em 3.2). Nunca desce. |
| **Progresso do nível** | XP ganho desde o último nível / custo do degrau atual. Começa em "0/300" e zera a cada nível ("0/400" ao chegar no 2). |
| **Pontos** | `RPG_PONTOS_POR_NIVEL` (1) por nível acima do 1. Livres = (nível − 1) × pontos por nível − gastos. |
| **Desafio RPG** | O Hard com os inimigos mais fortes (3.11). É a dificuldade de todo jogo RPG. |
| **Perfil RPG** | O estado do modo num save: XP ganho (se o RPG precisar guardar; ver 3.1), pontos gastos em cada atributo e o nível (cópia, para a tag de 3.8). |
| **Foto do save** | O perfil RPG gravado no instante em que o jogo grava o save. É o que volta quando o save é carregado (3.7). |

## 3. Desenho

### 3.1 De onde vem o XP ganho

O usuário lembra que o jogo talvez já some isso em algum lugar. A tarefa A1 confirma, e o caminho escolhido vem do que ela achar, nesta ordem de preferência:

1. **Contador do próprio jogo:** um valor que sobe com o XP e não desce ao comprar golpe (estatística do save, conquistas, Konten).
   - O RPG lê esse valor; não precisa guardar XP.
   - Se o contador já não começa em 0 num jogo novo, o perfil guarda o valor do começo e o XP ganho é a diferença.
2. **Somar na entrada:** trocar a função que credita XP (a que trata `addexperience`/coleta do orbe; A2) por uma que chama a original e, num save RPG, soma a quantia ao XP ganho.
   - O XP ganho vai para a foto do save.
3. **Somar pela diferença do saldo:** a cada quadro de gameplay, se o saldo subiu, somar a diferença.
   - Fica fora das trocas de save e de sala, que podem reescrever o saldo.
   - É o último recurso: frágil em carregamento.

Como todo save RPG começa do zero (3.6), o XP ganho começa em 0 e não há conta a fazer para saves antigos.

**XP por personagem:** se cada personagem (Liu Kang, Kung Lao…) tem saldo e golpes próprios (A1 confirma), o nível e os pontos também são por personagem.

### 3.2 Nível e curva

Nível por XP, como o usuário pediu: subir do nível k para o k+1 custa

`custo(k) = RPG_XP_PRIMEIRO + RPG_XP_AUMENTO × (k−1) + RPG_XP_ACELERA × (k−1)(k−2)/2`

Com 300, 100 e 50, os custos são 300, 400, 550, 750, 1000…: cada degrau aumenta 50 a mais que o anterior.

| Nível | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 12 | 15 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Custo do degrau | 300 | 400 | 550 | 750 | 1.000 | 1.300 | 1.650 | 2.050 | 2.500 | 3.550 | 5.500 |
| XP ganho total | 300 | 700 | 1.250 | 2.000 | 3.000 | 4.300 | 5.950 | 8.000 | 10.500 | 17.050 | 31.500 |

- **Nível** = maior n com XP ganho ≥ soma dos custos até n, até o **nível máximo 100** (`RPG_NIVEL_MAX`, pedido do usuário). No 100, o indicador mostra "Nv 100 · MÁX".
- **Quanto custa chegar lá com 300/100/50:** nível 20 = 71.250 de XP ganho; 30 = 232.000; 50 = 1.053.500; 100 = 8.357.250.
- A A1 mede quanto XP o jogo inteiro dá. Se ficar longe dessas contas, o usuário decide entre deixar o 100 como meta quase inalcançável ou achatar a curva (`RPG_XP_ACELERA` menor). Mudar a curva é só mexer nas três chaves.

### 3.3 Pontos e atributos

Seis atributos, todos sem mexer em velocidade, aprovados pelo usuário em 15/11 (o Crítico, proposto junto, saiu).

| Atributo | Efeito por ponto | Teto (por enquanto) | Como entra no jogo |
|---|---|---|---|
| **Força** | +5% de dano causado | 20 pontos (+100%) | Multiplica o dano em que o atacante é o jogador (A4) |
| **Defesa** | −3% de dano recebido | 20 pontos (−60%) | Multiplica o dano em que o alvo é o jogador, com mínimo de 1 (A4) |
| **Vida** | +5% de vida máxima | 20 pontos (+100%) | Vida máxima do jogador ao começar a sala, ao subir de nível e ao gastar ponto (A3) |
| **Roubo de vida** *(novo)* | Cura 1% do dano causado | 20 pontos (20%) | Gancho de dano: soma à vida atual do jogador, sem passar da máxima (A3, A4) |
| **Regeneração** *(novo)* | Recupera 0,1% da vida máxima por segundo | 20 pontos (2%/s) | A cada quadro de gameplay, fora de pausa, menu e cutscene (A3, A7) |
| **Sabedoria** *(novo)* | +3% de XP para o nível | 20 pontos (+60%) | Só no XP ganho do RPG; o saldo de XP do jogo não muda (regra 6) |

- **Talvez um oitavo, Fúria:** o medidor especial/de fatality enche +5% mais rápido por ponto. Só entra se a A8 achar o medidor e ele puder ser acelerado sem mexer em velocidade.
- **Ordem do cálculo do dano causado:** base × (1 + Força) ÷ (1 + vida extra dos inimigos, 3.11). O Roubo de vida cura sobre o resultado.
- **Tetos:** o usuário vai tirar os tetos depois. `RPG_TETO_ATRIBUTO=0` desliga o teto. Mesmo sem teto, a Defesa para em −90% (o dano nunca some) e a Regeneração em 10%/s.
- **Pontos por nível:** 1 (usuário, 15/11; `RPG_PONTOS_POR_NIVEL`). No nível 100 são 99 pontos.
- **Arredondamento:** dano e vida arredondados para o inteiro mais próximo; o dano nunca vai a 0.
- **Exceções:** morte instantânea do jogo (abismo, fatality) não passa pelos multiplicadores.
- **Redistribuir:** livre, a qualquer momento em que a aba RPG abre. "Redistribuir pontos" devolve todos os pontos gastos (confirmação com X duas vezes).

### 3.4 Onde se joga: janela "Opções", abas Gráfico e RPG

O menu Gráfico vira uma janela com **duas abas lado a lado**. O uso pedido: subiu de nível, pausa (Select), R3, distribui.

```
  Gráfico   [ RPG ]                              L1/R1: trocar aba
  ─────────────────────────────────────────────────────────────
  Liu Kang · Nível 7 · 2 pontos livres
  Próximo nível     600 / 1.650   ▕██████░░░░░░░░░░░░░▏   XP ganho 4.900
  Força          3   +15% de dano causado            X: +1 ponto
  Defesa         2   −6% de dano recebido
  Vida           0   +0% de vida máxima
  Roubo de vida  0   cura 0% do dano causado
  Regeneração    0   0,0% da vida por segundo
  Sabedoria      0   +0% de XP para o nível
  Redistribuir pontos
  Fechar
  ─────────────────────────────────────────────────────────────
  Cima/Baixo: escolher   X: gastar/mudar   O ou R3: fechar
```

- **Abrir:** como hoje (R3 fora da gameplay: menu inicial, pausa do Select, mapa; F1 a qualquer hora). Abre na aba RPG quando há pontos livres; senão, na última usada.
- **Trocar aba:** L1/R1 no controle, Q/E no teclado (já são L1/R1 no teclado).
- **Aba Gráfico:** igual à de hoje, com "Restaurar recomendado" (feito em 15/11).
- **Aba RPG fora de um save RPG:** a linha "Este save não é do modo RPG. Para jogar nele, comece um jogo novo e ligue o modo na tela de dificuldade." Sem nada para mudar.
- **Gastar ponto:** X na linha do atributo; com zero pontos livres ou atributo no teto, a linha fica cinza. O efeito vale na hora.
- **Controle:** enquanto a janela está aberta, o jogo não recebe nada (`g_gfxBlockInput`, como hoje).
- **Dica:**
  - Num save normal, continua "R3: Gráfico".
  - Num save RPG, "R3: Gráfico · RPG".
  - Com pontos livres, "R3: RPG +2" na pausa.

### 3.5 Indicador e aviso de nível

- **Indicador, ao lado do nome do personagem no HUD** (pedido do usuário): nível e progresso, em dourado.
  - No começo: **"Nv 1 · 0/300"**. Depois, por exemplo, "Nv 7 · 600/1.650"; com pontos livres, "Nv 7+2 · 600/1.650".
  - O progresso é o do nível atual (2): o XP desde o último nível sobre o custo do degrau. Ao subir, zera ("Nv 2 · 0/400").
  - Atualiza na hora em que o XP entra.
  - Posição exata na C3, por capturas: na mesma linha do nome, sem cobrir o nome, a barra de vida nem o "EXP".
  - O tamanho acompanha a altura da imagem, e a posição é relativa à imagem do jogo (certo em 4:3 e 16:9).
  - Aparece na gameplay e na pausa, só num save RPG.
  - Some em filmes, cutscenes (se a A7 achar como distingui-las) e menus.
- **Aviso de nível:** ao subir, "NÍVEL 8! +1 ponto · Select e R3 para distribuir" no alto da imagem por 3 s, sem cobrir o HUD. Vários níveis de uma vez viram um aviso só ("NÍVEL 10! +3 pontos").

### 3.6 Escolher o modo (só num jogo novo)

O RPG é uma **variante do Hard**, escolhida em cima dele (pedido do usuário):

- **Onde:** na tela de escolha de dificuldade de um jogo novo.
- **Como:**
  - Com o cursor no **Hard**, aparece ao lado a dica "L3: Modo RPG".
  - **L3** liga e desliga (no teclado, F2; o teclado não tem L3). Ligado, aparece a marca dourada **"RPG"** em cima da palavra Hard.
  - O L3 não vai para o jogo nessa hora.
- **Só no Hard:**
  - Com o cursor no Normal, nem a dica nem o L3 existem.
  - Levar o cursor do Hard para o Normal desliga o RPG, e a marca some.
  - O jogo não é forçado em nada: a pessoa escolhe o Hard como sempre.
- **Por que L3 e não R3:** nos menus, o R3 abre a janela de opções (Gráfico/RPG).
- **Quando vale:** confirmar o Hard com a marca "RPG" cria um jogo RPG (no Hard, com o Desafio RPG de 3.11); sem a marca, um jogo normal.
  - Num jogo RPG, o perfil nasce na memória (nível 1, XP ganho 0) e vai para o arquivo no primeiro save do jogo (3.7).
  - Num jogo normal, nenhum perfil.
- **Depois disso é fixo:**
  - Carregar um save normal nunca liga o modo, e a aba RPG não oferece ligar (3.4).
  - Um save RPG não desliga: sempre que é carregado, o modo vem ligado.
- **Só aparece onde faz sentido:** se a tela de dificuldade também aparece fora de jogo novo (A7), a dica fica só no caminho de jogo novo.

### 3.7 Dados por save (a foto do save)

- **Arquivo:** `rpg_<cartão>[_<slot>].ini` ao lado do `mksm.ini` (ex.: `rpg_mc0.ini`), em texto `CHAVE=valor`:
  - `NIVEL` (cópia para a tag de 3.8);
  - por personagem: `FORCA`, `DEFESA`, `VIDA` e, nos caminhos 2 e 3 de 3.1, `XP_GANHO` (no caminho 1, `XP_INICIO` se o contador não começa em 0).
  - O `_<slot>` só existe se a A5 mostrar mais de um save por cartão.
  - Existir o arquivo = aquele save é RPG.
- **Quando grava:** no instante em que o jogo grava o save, inclusive no autosave (o memory card passa pelo runtime, `Kernel/Stubs/MemoryCard.cpp`).
  - Jogo RPG gravando: escreve o perfil.
  - **Jogo normal gravando por cima de um save RPG:** apaga o `rpg_*.ini` daquele save, que deixou de ser RPG.
- **Quando lê:** quando o jogo carrega o save. Entre um e outro, o perfil vive na memória.
- **Por quê:** se o jogador morre e recarrega sem salvar, o XP ganho e os pontos voltam junto com o save, como no próprio jogo.
- **Arquivo inválido ou editado à mão** (fronteira de confiança): valores fora da faixa são limitados, linhas ilegíveis ignoradas, e soma de pontos maior que o permitido pelo nível zera os gastos. Nunca trava o jogo.
- **Pastas portáteis:** o arquivo fica na raiz, ao lado do `mksm.ini`. Quem copia o save para outra pasta copia o `rpg_*.ini` junto (dito no LEIA-ME).

### 3.8 Tag na tela de load/save

- **Na tela de carregar e na de salvar** do jogo (`Load Menu`/`Save Menu`), cada save que tem `rpg_*.ini` ganha uma tag dourada **"RPG · Nv 7"** logo acima da sua linha/caixa, desenhada pela janela por cima da imagem do jogo.
- **Posições:** a A6 acha como saber que a tela está aberta, quais saves ela lista e onde cada um aparece na imagem (posição fixa por linha ou lida da RAM, se a lista rola).
- **Se o jogo mostra só o cartão** (um save por cartão): a tag fica sobre o cartão.
- **Cobertura:** a tag nunca cobre o texto do save. Posição relativa à imagem do jogo (certa em 4:3 e 16:9).

### 3.9 Dois jogadores

- A primeira versão cobre o jogador 1.
- O jogador 2 (cooperativo) entra na D4, com nível, pontos e indicador próprios, e a aba RPG perguntando de qual jogador.

### 3.10 Chaves `RPG_*` (no `mksm.ini`, todas opcionais)

| Chave | Padrão | O quê |
|---|---|---|
| `RPG_XP_PRIMEIRO` | 300 | Custo do nível 1 → 2 |
| `RPG_XP_AUMENTO` | 100 | Quanto o 2º degrau custa a mais que o 1º |
| `RPG_XP_ACELERA` | 50 | Quanto cada aumento cresce em relação ao anterior |
| `RPG_NIVEL_MAX` | 100 | Nível máximo (usuário, 15/11) |
| `RPG_FORCA_POR_PONTO` | 5 | % de dano causado por ponto |
| `RPG_DEFESA_POR_PONTO` | 3 | % de dano recebido a menos por ponto |
| `RPG_VIDA_POR_PONTO` | 5 | % de vida máxima por ponto |
| `RPG_ROUBO_POR_PONTO` | 1 | % do dano causado que vira vida |
| `RPG_REGEN_POR_PONTO` | 0,1 | % da vida máxima por segundo |
| `RPG_SABEDORIA_POR_PONTO` | 3 | % de XP a mais para o nível |
| `RPG_TETO_ATRIBUTO` | 20 | Pontos por atributo; 0 = sem teto |
| `RPG_PONTOS_POR_NIVEL` | 1 | Pontos ganhos a cada nível (usuário, 15/11) |
| `RPG_INIMIGO_DANO` | 30 | % de dano a mais que os inimigos causam (3.11) |
| `RPG_INIMIGO_VIDA` | 30 | % de vida a mais dos inimigos (3.11) |
| `RPG_INIMIGO_POR_NIVEL` | 0 | % a mais nos dois, por nível do jogador (3.11) |

### 3.11 Dificuldade: sempre Hard, e mais duro que o Hard no começo

O jogador do RPG cresce sem parar (pontos, golpes comprados). Por isso o jogo começa **mais difícil que o Hard** e vai ficando mais fácil conforme ele evolui.

- **Base:** sempre Hard (o RPG só existe em cima dele; 3.6).
- **Desafio RPG, por cima do Hard:**
  - os inimigos causam +30% de dano (`RPG_INIMIGO_DANO`);
  - aguentam +30% de dano (`RPG_INIMIGO_VIDA`).
  - Os dois valem para todos os inimigos e chefes, desde o nível 1.
- **Como entra no jogo, sem mexer em nenhum inimigo:**
  - O dano que o jogador recebe é multiplicado por 1,3, junto com a Defesa.
  - O dano que ele causa é dividido por 1,3, junto com a Força. Para a luta, "inimigo com 30% a mais de vida" é a mesma coisa que "levar 30% menos dano", e assim não é preciso achar a vida de cada inimigo.
  - A barra de vida dos inimigos desenha igual; ela só desce mais devagar.
- **Como fica a curva de dificuldade** (exemplo; números reais na D3):

  | Momento | Dano que o jogador causa | Dano que recebe | Comparado ao Hard |
  |---|---|---|---|
  | Nível 1, sem pontos | 77% | 130% | Bem mais difícil |
  | Nível ~15 (5 Força, 4 Defesa, 3 Vida, 2 Roubo de vida) | ~96% | ~114%, com +15% de vida e curando 2% do que bate | Mais ou menos o Hard |
  | Nível 25 em diante | acima de 100% | abaixo de 100% | Mais fácil que o Hard: o jogador ficou forte |

- **Escala por nível (desligada, `RPG_INIMIGO_POR_NIVEL=0`):** inimigos ficando mais fortes a cada nível do jogador anulariam a evolução. Com +1% por nível nos dois valores, um jogador no nível 15 que espalhou os pontos ficaria mais fraco, em relação aos inimigos, do que no nível 1. Fica disponível para a D3, se o usuário achar o fim fácil demais.
- **Escala por área (ideia para depois):** inimigos mais fortes nas áreas finais, independente do nível. Precisa do endereço da área atual; só entra se o usuário pedir na D3.

## 4. O que já sabemos (15/11)

| O quê | Onde / como |
|---|---|
| O jogo tem experiência e loja de golpes | HUD "EXP"; mapa do Start com "Experience" e "Moves" |
| Comandos de script ligados a XP e dano | Strings no ELF: `addexperience` (`0x575DA0`), `spawnexperience` (`0x578818`), `applydamage` (`0x586570`), `bodydamage` (`0x58F308`), `pickupdoubledamage` (`0x578C10`). Não há tabela com ponteiros para essas strings: cada comando é registrado por código |
| Registro do `addexperience` | Em `0x1671B0` (`sub_001671B0`): `func_362CE0(registro, "addexperience", descritor em 0x5CCDB0)`. O descritor fica na BSS e é preenchido em tempo de execução. A função que trata o comando é alcançada a partir dele: ponto de partida da A2 |
| Estrutura do jogador | `0x33C0` bytes por jogador; campos não mapeados (`MODDING.md` §5) |
| Estado da tela | `0x4F4B68` = 1 em gameplay e cutscene; `0x6BEE2C` = 1 na pausa do Select; `0x4C49E8` = 1 em menu dentro do jogo (N21). Carregamento também dá `0x4F4B68` = 0 (ARQUITETURA, menu Gráfico) |
| Telas com nome no ELF | `Load Menu`, `Save Menu`, `FE Menu`, `Pause` (`MODDING.md`) |
| Saves | Memory card em `jogo/mc0/BASLUS-21087/` (um arquivo `BASLUS-21087`, 198.876 bytes). O log `[MC]` mostra cada GetDir/abertura |
| Save do usuário mais adiante no jogo | `portatil/backup_save_mc0_15nov/` (cópia de 15/11). Para testar áreas depois do Goro's Lair, copie para uma pasta de teste; nunca grave por cima do original |
| Tela por cima e controle bloqueado | Menu Gráfico (`updateGfxMenu`/`drawGfxMenu`, `g_gfxBlockInput`, `MKSM_GFX_SCRIPT`) em `ps2_runtime.cpp` |
| Trocar uma função do jogo | `runtime.replaceFunction(endereço, função)` em `game_overrides_mksm.cpp` (ex.: `skipIntro`) |

## 5. Mapa do código

| Peça | Onde |
|---|---|
| Estado, curva, chaves `RPG_*`, perfil, arquivo `rpg_*.ini` | Novo `ps2xRuntime/src/lib/mksm_rpg.cpp` + `mksm_rpg.h`, este incluído só pelos `.cpp` que usam (nunca pelo `ps2_runtime.h`). Entram no `patches/arquivos.txt` e no `target_sources` do `ps2EntryRunner` (como `game_overrides_mksm.cpp`) |
| Trocas de função (crédito de XP, dano, vida máxima) | `game_overrides_mksm.cpp`, chamando o `mksm_rpg` |
| Gravar/carregar/apagar o perfil junto com o save | Gancho no `Kernel/Stubs/MemoryCard.cpp` (escrita e leitura do arquivo do save) avisando o `mksm_rpg` |
| Janela Opções (abas), aba RPG, indicador, aviso, dicas, tag de load/save | `ps2_runtime.cpp`, ao lado do menu Gráfico |
| Testes | Asserções no `mksm_rpg.cpp` (curva, validação do arquivo) e um teste em `ps2xTest` se a curva for exposta |

## 6. Ferramentas

- **Cópias da RAM:** `PS2X_DUMP_RAM_AT="70,74,78"` grava `ram_<s>.bin` (32 MB) nesses segundos.
  - Compare dois estados com um script Python na pasta de rascunho.
  - Para valores que só sobem ou só descem, use três ou mais cópias e filtre pela tendência.
- **Roteiro de botões:** `MKSM_AUTO_PAD`, `MKSM_AUTO_HOLD` e `MKSM_PAD_CLOCK=reads` (determinístico); formatos em `ps2_pad.cpp`. R5 do `PLANO_DESEMPENHO.md` leva à gameplay.
- **Menus sem controle:** `MKSM_GFX_SCRIPT` (o abrir, u d l r cima/baixo/esq/dir, x aceitar, c fechar). Na C1 ganha `q`/`e` para trocar de aba.
- **Capturas:** `PS2X_SCREENSHOT_DIR`, `PS2X_SCREENSHOT_EVERY`/`FROM`/`UNTIL`.
- **Log temporário:** `std::fprintf(stderr, ...)` com prefixo `[rpg]`, que sai antes do commit.
- **Código gerado:** `PS2Recomp/ps2xRuntime/src/runner/sub_<ENDEREÇO>_*.cpp`, com o assembly de cada instrução em comentário (`// 0x1671f8: ... addiu $a1, $a1, 0x5DA0`). Dá para procurar quem usa uma constante ou um deslocamento com `grep`.
- **Testes com save:** sempre numa cópia da pasta `mc0` (pasta de teste com links para os arquivos do jogo e o `mc0` copiado). Nunca no save do usuário.

## 7. Tarefas (faça na ordem)

### Fase A: investigação (só leitura; nada muda no jogo)

- [ ] **A1 XP: saldo, acumulado e por personagem**
  - **Faça:**
    - Na gameplay (R5), cópias da RAM antes e depois de matar inimigos (o saldo sobe), e antes e depois de comprar um golpe no mapa (o saldo desce).
    - Ache o **saldo** (bate com o HUD) e procure um **acumulado**: um valor que subiu com as mortes na mesma quantia e **não** desceu na compra. Olhe também perto do saldo, na estrutura do jogador e na área do save (o save carregado fica na RAM). Veja se o acumulado começa em 0 num jogo novo.
    - Troque de personagem (Kung Lao) e veja se o saldo é por personagem.
    - Meça o XP por inimigo e por sala nas primeiras salas do Goro's Lair e, no save do usuário, o saldo (e o acumulado, se houver) no ponto em que ele está. Estime quanto XP o jogo inteiro dá.
  - **Verifique:** três rodadas com os mesmos valores; o saldo bate com o HUD em todas as cópias.
  - **Pronto quando:** anotados aqui e no `MODDING.md` §5:
    - endereço ou ponteiro do saldo;
    - se existe acumulado (endereço, valor num jogo novo) ou não;
    - se é por personagem;
    - XP por inimigo, por sala e estimado no jogo inteiro (com o nível a que a curva de 3.2 chega);
    - escolha do caminho de 3.1.

- [ ] **A2 Quem credita o XP** (pule se a A1 achou o acumulado do jogo)
  - **Faça:**
    - A partir do registro em `0x1671B0` (descritor `0x5CCDB0`), ache a função que trata o comando `addexperience`.
    - Em paralelo, procure no código gerado quem grava no endereço/deslocamento do saldo da A1 (`grep` pelo deslocamento nos `sub_*.cpp`).
    - Confirme com um `replaceFunction` temporário que loga a quantia a cada chamada.
  - **Verifique:** a soma das quantias logadas = a subida do saldo, numa sala inteira; nenhuma chamada na compra de golpe.
  - **Pronto quando:** função, argumento da quantia e de quem recebe anotados aqui.

- [ ] **A3 Vida do jogador 1**
  - **Faça:**
    - Cópias antes e depois de apanhar e de recuperar vida (item), e ao trocar de sala.
    - Ache vida atual e vida máxima e de onde a máxima vem: campo do jogador, tabela por personagem, ou dificuldade.
    - Veja se o jogo reescreve a máxima ao trocar de sala ou carregar.
    - Veja como a barra de vida é desenhada: proporção atual/máxima (aguenta máxima maior) ou largura fixa por ponto de vida (aí a Vida precisa de outro caminho).
    - Para a Regeneração e o Roubo de vida: com uma chave temporária, some 10 à vida atual e veja se o jogo aceita (a barra sobe e não volta no quadro seguinte) ou se a reescreve de uma cópia.
  - **Verifique:** log temporário mostrando os valores coerentes com a barra em três rodadas, com Liu Kang e Kung Lao; a escrita de teste fica.
  - **Pronto quando:** endereços, origem da máxima e comportamento da barra anotados aqui e no `MODDING.md`.

- [ ] **A4 Dano**
  - **Faça:**
    - Ache a função que desconta a vida: quem grava a vida atual da A3 no código gerado, e o tratador do comando `applydamage` (registrado como o `addexperience`).
    - Descubra nos argumentos (`a0`–`a3`) quem ataca, quem recebe e a quantia. O RPG precisa separar os quatro casos: jogador → inimigo (Força, Roubo, vida extra dos inimigos), inimigo → jogador (Defesa, dano extra dos inimigos), e o resto (armadilha → jogador conta como inimigo; inimigo → inimigo fica igual).
    - Veja o que o `pickupdoubledamage` liga: se for um multiplicador no jogador, anote; pode servir de referência para a Força.
    - Liste as fontes de dano que passam por ali: golpes, armas, projéteis, armadilhas, quedas.
  - **Verifique:** com uma chave temporária `RPG_TESTE_DANO=2`, um wrapper dobra o dano quando o atacante é o jogador 1. Num roteiro de golpes fixo, a vida tirada do inimigo dobra; sem a chave, fica igual.
  - **Pronto quando:** função, argumentos e a lista de fontes anotados aqui.

- [ ] **A5 Como o jogo identifica cada save**
  - **Faça:**
    - Com o log `[MC]`, comece um jogo novo, salve, carregue, e salve em outro save (se o jogo deixar), vendo arquivos, deslocamentos e tamanhos de cada leitura/gravação.
    - Anote em que momento um jogo novo grava o primeiro save (autosave logo no começo ou só depois).
  - **Verifique:** dá para dizer, só pelo que passa no `MemoryCard.cpp`, qual save foi carregado e qual foi gravado (autosave incluído).
  - **Pronto quando:** regra do nome do `rpg_*.ini` (por cartão ou por cartão e slot) e o momento do primeiro save anotados aqui.

- [ ] **A6 Telas de load e de save**
  - **Faça:**
    - Cópias da RAM com a tela de carregar aberta, com a de salvar aberta, e fora delas.
    - Ache um valor que diga "tela de load/save aberta" e, se houver, qual save está selecionado e o primeiro da lista visível (se ela rola).
    - Capturas da tela com um, dois e (se der) mais saves para medir onde cada linha/caixa aparece na imagem.
  - **Verifique:** em três rodadas, o valor liga só nessas telas, e as posições batem com as capturas.
  - **Pronto quando:** endereços e posições (em fração da imagem) anotados aqui e no `MODDING.md`.

- [ ] **A7 Telas: dificuldade (jogo novo) e cutscene**
  - **Faça:**
    - Cópias da RAM antes, durante e depois da tela de dificuldade num jogo novo (Single Player → personagem → dificuldade). Anote:
      - o cursor da tela (Normal/Hard), o valor da dificuldade escolhida e o do Hard;
      - onde a palavra "Hard" aparece na imagem (para a marca "RPG" em cima dela);
      - se o jogo usa L3 nessa tela;
      - se essa tela aparece em outros caminhos (Konten, carregar).
    - Cópias numa cutscene e na gameplay logo depois (Goro's Lair), procurando um valor que separe as duas (HUD visível).
  - **Verifique:** o valor da tela de dificuldade muda só nela, em três rodadas, e dá para saber que é jogo novo; o de cutscene separa as duas em três rodadas.
  - **Pronto quando:** os endereços anotados aqui (o de cutscene pode não existir; então o indicador fica também nas cutscenes).

- [ ] **A8 Medidor especial (para a Fúria; opcional)**
  - **Faça:** ache o medidor que enche para a fatality/golpe especial (se o jogo tiver um no HUD), quem o enche e com quanto por golpe.
  - **Verifique:** o valor acompanha o medidor na tela em três rodadas.
  - **Pronto quando:** endereço e quem enche anotados aqui, ou anotado que não há medidor (aí a Fúria não entra).

### Fase B: núcleo (sem tela)

- [ ] **B1 Módulo `mksm_rpg`**
  - **Faça:** arquivo novo com:
    - as chaves `RPG_*` (3.10) e o perfil (por personagem: XP ganho se preciso, pontos gastos);
    - `custo(k)`, `nivel(xpGanho)`, `pontosLivres()` e os multiplicadores, com os tetos de 3.3.
    - Nada ligado ao jogo ainda.
  - **Verifique:** asserção que roda uma vez:
    - nível 1 com XP 0, 2 com 300, 3 com 700, 4 com 1.250, 5 com 2.000 (tabela de 3.2);
    - o nível sobe exatamente no limite e nunca desce;
    - nível 100 com 8.357.250 de XP ganho e nunca 101;
    - multiplicadores dos seis atributos com 0, 1 e 20 pontos batem com a tabela de 3.3, e sem teto a Defesa para em −90% e a Regeneração em 10%/s;
    - a ordem do dano causado (3.3) com o Desafio RPG (3.11): 100 de base, 4 de Força → 100 × 1,2 ÷ 1,3 = 92.
    - Testes `ps2x_tests` iguais.
  - **Pronto quando:** módulo compilando no Linux e no Windows (`scripts/build_windows.sh`), com as asserções passando.

- [ ] **B2 XP ganho ao vivo**
  - **Faça:** o caminho escolhido na A1:
    - caminho 1: ler o acumulado;
    - caminho 2: wrapper da A2 somando a quantia num save RPG;
    - caminho 3: diferença do saldo.
    - Num save normal, o wrapper só chama a original.
  - **Verifique:** log temporário numa sala inteira (o XP ganho acompanha o saldo e não desce na compra de golpe); save normal com a mesma sequência de saldo de antes.
  - **Pronto quando:** medido e anotado aqui.

- [ ] **B3 Foto do save**
  - **Faça:** gravar, ler e apagar o `rpg_*.ini` como em 3.7 (regra da A5), com a validação.
  - **Verifique:**
    - jogo RPG: salvar, sair e carregar, perfil igual;
    - ganhar XP e gastar ponto, morrer e recarregar sem salvar: volta ao gravado;
    - jogo normal salvo por cima de um save RPG: o arquivo some e o save carrega normal;
    - arquivo corrompido à mão: o jogo abre, com os valores limitados;
    - save normal carregado: modo desligado.
  - **Pronto quando:** os cinco casos testados (roteiro ou usuário) e anotados aqui.

- [ ] **B4 Efeitos: Força, Defesa e Vida**
  - **Faça:**
    - Força e Defesa no wrapper da A4, com as exceções de 3.3.
    - Vida na máxima da A3, reaplicada onde o jogo a reescreve; ao ganhar Vida, a vida atual sobe na mesma quantia.
  - **Verifique:** roteiro de golpes fixo com 0, 5 e 10 pontos em cada atributo; dano causado, dano recebido e vida máxima batem com a tabela (±1 de arredondamento); barra de vida desenhada certo.
  - **Pronto quando:** a tabela medida anotada aqui.

- [ ] **B5 Efeitos: Roubo de vida, Regeneração e Sabedoria (e Fúria, se a A8 achou)**
  - **Faça:**
    - Roubo de vida no gancho de dano.
    - Regeneração por quadro de gameplay (A7 para pausa e cutscene).
    - Sabedoria sobre o XP que entra no XP ganho (B2).
    - Fúria no que enche o medidor (A8).
  - **Verifique:**
    - roteiro fixo com 10 pontos em cada um;
    - Roubo: vida sobe 10% do dano causado;
    - Regeneração: 1% da máxima por segundo parado;
    - Sabedoria: XP ganho = 130% do saldo ganho.
  - **Pronto quando:** medido e anotado aqui.

- [ ] **B6 Desafio RPG e Hard**
  - **Faça:** os multiplicadores de 3.11 no gancho de dano (dano recebido × 1,3; dano causado ÷ 1,3), só num save RPG.
  - **Verifique:** o mesmo roteiro de golpes no Hard normal e num jogo RPG sem pontos: o inimigo leva ~77% do dano e o jogador ~130% (±1).
  - **Pronto quando:** medido e anotado aqui.

### Fase C: tela

- [ ] **C1 Janela Opções com abas**
  - **Faça:**
    - O menu Gráfico vira a aba Gráfico de uma janela com abas (3.4), sem mudar nada dentro dela.
    - L1/R1 e Q/E trocam de aba; o `MKSM_GFX_SCRIPT` ganha `q`/`e`.
    - A aba RPG pode estar vazia nesta tarefa.
  - **Verifique:** capturas da aba Gráfico iguais às de antes (fora o título das abas); roteiro troca de aba e volta.
  - **Pronto quando:** capturas anotadas.

- [ ] **C2 Aba RPG**
  - **Faça:** o conteúdo de 3.4:
    - nível, barra de XP, pontos livres, os seis atributos com efeito (sete com a Fúria);
    - X gasta, linha cinza sem pontos ou no teto;
    - "Redistribuir pontos" com confirmação;
    - abrir na aba RPG quando há pontos livres;
    - a mensagem de "este save não é RPG" num save normal.
  - **Verifique:** roteiro que, num save RPG, gasta pontos, redistribui e fecha; efeito na hora (B4); `rpg_*.ini` atualizado no próximo save. Num save normal, só a mensagem.
  - **Pronto quando:** roteiro e capturas anotados.

- [ ] **C3 Indicador, aviso de nível e dicas**
  - **Faça:** "Nv 1 · 0/300" ao lado do nome do personagem (3.5), o aviso de 3.5 e as dicas de 3.4; esconder em filmes, menus e cutscenes (A7). Se o nome do personagem muda de lugar ou de tamanho (troca de personagem, 2 jogadores), a posição vem da A3/A7 ou de uma tabela por personagem.
  - **Verifique:**
    - capturas em 4:3 e 16:9, gameplay e pausa, com Liu Kang e Kung Lao: o texto na linha do nome, sem cobrir nome, barra de vida nem "EXP";
    - no roteiro, o progresso sobe a cada inimigo, chega a 300/300, vira "Nv 2 · 0/400" e mostra o aviso uma vez;
    - save normal sem nada do RPG na tela.
  - **Pronto quando:** capturas anotadas.

- [ ] **C4 Escolha na tela de dificuldade**
  - **Faça:** com os endereços da A7, o que está em 3.6:
    - dica "L3: Modo RPG" ao lado do Hard só com o cursor nele;
    - L3 (F2 no teclado) liga e desliga, sem chegar ao jogo;
    - marca "RPG" em cima do Hard;
    - cursor no Normal desliga;
    - confirmar o Hard com a marca cria o perfil.
    - O roteiro de teste ganha um passo para L3.
  - **Verifique:**
    - começar um jogo com e sem o modo por roteiro; o indicador só aparece no primeiro, e a dificuldade do jogo RPG é Hard (valor da A7);
    - no Normal, L3 não faz nada; ligar no Hard e descer para o Normal tira a marca;
    - capturas da marca em 4:3 e 16:9, sem cobrir o texto do jogo;
    - o primeiro save do jogo RPG cria o `rpg_*.ini`;
    - num save normal carregado, não há como ligar.
  - **Pronto quando:** os três casos testados.

- [ ] **C5 Tag "RPG · Nv N" na tela de load/save**
  - **Faça:** com a A6, desenhar a tag de 3.8 sobre cada save que tem `rpg_*.ini`, na tela de carregar e na de salvar.
  - **Verifique:** capturas com um save RPG e um normal: a tag só sobre o RPG, com o nível certo, sem cobrir o texto, em 4:3 e 16:9; depois de gravar um jogo normal por cima, a tag some.
  - **Pronto quando:** capturas anotadas.

### Fase D: prova, ajuste e acabamento

- [ ] **D1 Modo desligado igual ao original**
  - **Faça:** num jogo normal (e sem `rpg_*.ini`):
    - `ps2x_tests`;
    - R4/R4b do `PLANO_DESEMPENHO.md` (hashes das cenas);
    - o roteiro de golpes da B4, registrando a vida do jogador e do inimigo a cada golpe, contra a mesma gravação feita antes da Fase B (no Normal e no Hard: o Desafio RPG não pode vazar para um jogo normal no Hard).
  - **Pronto quando:** tudo igual, número por número.

- [ ] **D2 Pasta portátil e Windows**
  - **Faça:**
    - `scripts/empacotar_linux.sh` e `scripts/build_windows.sh`;
    - LEIA-ME das duas pastas com o modo RPG (escolher no jogo novo, distribuir com Select e R3, a tag nos saves, copiar o `rpg_*.ini` junto com o save);
    - `mksm.ini` com as chaves `RPG_*` comentadas.
  - **Verifique:** o modo funciona nas duas pastas (Windows: pelo menos no Wine, e o usuário confirma no Windows).
  - **Pronto quando:** as duas pastas geradas e testadas.

- [ ] **D3 Balanceamento (com o usuário)**
  - **Faça:** o usuário joga um jogo RPG do começo e diz se os níveis vêm no ritmo certo e se ficou fácil ou difícil. Ajustar pelas chaves `RPG_*`:
    - curva, efeitos e tetos (ele já disse que vai tirar os tetos depois);
    - o Desafio RPG (`RPG_INIMIGO_DANO`/`VIDA`): o começo tem que ser mais duro que o Hard;
    - pontos por nível (1 por enquanto);
    - se o nível 100 está ao alcance com o XP do jogo (A1), ou se a curva achata;
    - se o fim ficar fácil demais: `RPG_INIMIGO_POR_NIVEL` ou a escala por área (3.11).
    - Se o jogador ficar forte demais no fim, considerar inimigos mais fortes por nível (nova tarefa; não entra sem pedido).
  - **Pronto quando:** o usuário aprovar.

- [ ] **D4 Segundo jogador**
  - **Faça:** A3, B4 e C3 para o jogador 2 (estrutura seguinte, `+0x33C0`?), cada um com perfil, pontos e indicador próprios; a aba RPG escolhe o jogador.
  - **Pronto quando:** testado com dois controles.

- [ ] **D5 Documentação**
  - **Faça:**
    - `ARQUITETURA.md`: janela com abas, ganchos do RPG, foto do save, tag de load/save, armadilhas achadas.
    - `MODDING.md`: endereços das tarefas A.
    - Este plano com tudo marcado.
  - **Pronto quando:** commit com tudo atualizado.

## 8. Decisões

| Decisão | Escolha | Origem |
|---|---|---|
| Nível sai de | XP ganho (só sobe) | Usuário, 15/11 |
| Curva | 300, 400, 550, 750… (3.2) | Usuário, 15/11 |
| Efeitos por ponto | Força +5%, Defesa −3%, Vida +5% | Usuário aprovou, 15/11 |
| Tetos | 20 por atributo por enquanto; `RPG_TETO_ATRIBUTO=0` tira | Usuário, 15/11 ("depois vou tirar os limites") |
| Onde distribuir | Aba RPG ao lado da aba Gráfico; pausa (Select) e R3 | Usuário, 15/11 |
| Redistribuir | Livre, a qualquer momento | Usuário, 15/11 |
| Escolher o modo | Só na tela de dificuldade de um jogo novo; fixo depois | Usuário, 15/11 |
| Saves RPG visíveis | Tag "RPG · Nv N" nas telas de load e save | Usuário, 15/11 |
| Morrer e recarregar | O perfil volta à foto do save | Igual ao que o jogo faz com o XP e os golpes |
| Desligar num save RPG | Não dá; o save é RPG para sempre | Usuário confirmou, 15/11 |
| Dificuldade | Sempre Hard: o RPG se liga com L3 em cima do Hard, com a marca "RPG" | Usuário, 15/11 |
| Nível máximo | 100 | Usuário, 15/11 |
| Pontos por nível | 1 | Usuário, 15/11 ("por enquanto") |
| Começo mais duro que o Hard | Desafio RPG: inimigos +30% de dano e +30% de vida, desde o nível 1, sem crescer com o nível | Usuário pediu ("mais difícil que o Hard no começo"); valores e forma são proposta |
| Atributos | Força, Defesa, Vida, Roubo de vida, Regeneração, Sabedoria (Fúria se houver medidor) | Usuário, 15/11 (Crítico tirado) |
| Na tela de jogo | "Nv 7 · 600/1.650" ao lado do nome do personagem; progresso do nível atual, zera a cada nível | Usuário, 15/11 ("0/300 no começo e vai mudando") |
| Inimigos mais fortes | Não | Fora do pedido; ver D3 |

## 9. Perguntas para o usuário (juntar aqui; não parar por elas)

- Nenhuma em aberto.
- (Se o usuário preferir o XP total no indicador, "4.900/5.950" em vez do progresso do nível, é só trocar o texto na C3.)

## 10. Riscos conhecidos

- **O acumulado pode não existir:** os caminhos 2 e 3 de 3.1 cobrem; como todo save RPG começa do zero, não há perda.
- **A barra de vida pode não aceitar uma máxima maior:** a A3 mede. Se não aceitar, a Vida vira "regenerar vida" ou "dano recebido" e o usuário decide.
- **Chefes com fases por porcentagem de vida:** mais dano pode pular falas ou fases; a B4 inclui um chefe no teste quando houver save perto de um.
- **Identificação do save:** se o jogo usar um arquivo só, com slots dentro, o nome do `rpg_*.ini` depende do deslocamento (A5).
- **Tela de load/save:** se a lista rola e a posição de cada save não aparece na RAM, a tag fica só sobre o save selecionado (A6 decide).
- **Cutscene × gameplay:** sem um valor que separe as duas (A7), o indicador aparece também nas cutscenes, e a Regeneração continua nelas.
- **Escrever na vida atual:** se o jogo reescreve a vida de uma cópia a cada quadro (A3), Regeneração e Roubo de vida precisam escrever na cópia ou passar pelo gancho de dano com valor negativo.
- **Cursor da tela de dificuldade:** se não for um valor simples na RAM (A7), a marca "RPG" passa a depender da posição do destaque na imagem; e se o jogo usar L3 nessa tela, o atalho vira outro botão livre.
