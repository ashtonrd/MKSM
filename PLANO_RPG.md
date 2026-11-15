# Plano do Modo RPG

**Pedido do usuário:**
- **15/11:** um modo opcional em que a experiência dá níveis e cada nível dá pontos para deixar o personagem mais forte. Na tela aparece o nível ("Nv 5") e, com pontos livres, "Nv 5+1". **Velocidade fica de fora**: mexer nela quebra golpes, combos e colisões.
- **15/11, à noite:** o nível sai do **XP ganho**, o mesmo XP que compra golpes, somado ao longo do jogo (comprar golpe não tira nível). Subir de nível e distribuir pontos fica "no próprio R3, do lado" do menu Gráfico.

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
2. **Arquivos do jogo intactos:** nada muda no WAD, no ELF nem no memory card. Tudo fica no runtime.
3. **O save continua o original:** abre num jogo sem o modo e num PS2. Os dados do RPG ficam num arquivo próprio (3.7).
4. **Sem velocidade:** nada que altere animação, movimento, hitbox ou quadros de golpe. O modo mexe só em dano, vida máxima e na tela por cima.
5. **A economia do jogo não muda:** o jogo dá o mesmo XP, os golpes custam o mesmo e o saldo de XP gasta igual. O RPG só lê o XP.
6. **Números ajustáveis sem recompilar:** chaves `RPG_*` no `mksm.ini` (lista em 3.9), lidas no começo do jogo.
7. **Regras do projeto** (`CLAUDE.md`):
   - Commits só do usuário.
   - Nada do jogo no git.
   - `PS2Recomp/` só por `scripts/atualizar_patches.sh`; arquivo novo entra no `patches/arquivos.txt`.
   - Diagnósticos temporários saem antes do commit.
   - **Header novo não entra no `ps2_runtime.h`**, para não recompilar os 13 mil arquivos gerados.

## 2. Vocabulário

| Termo | O que é |
|---|---|
| **XP saldo** | O número que o jogo mostra no HUD ("EXP") e no mapa. Sobe ao matar inimigos, desce ao comprar golpes. |
| **XP ganho** | Tudo o que o personagem já ganhou desde o começo do save. Só sobe. **É dele que sai o nível.** |
| **Nível** | Função do XP ganho (curva em 3.2). Nunca desce. |
| **Pontos** | 1 por nível. Livres = nível − gastos. |
| **Perfil RPG** | O estado do modo num save: ligado, XP ganho (se o RPG precisar guardar; ver 3.1) e pontos gastos em cada atributo. |
| **Foto do save** | O perfil RPG gravado no instante em que o jogo grava o save. É o que volta quando o save é carregado (3.7). |

## 3. Desenho

### 3.1 De onde vem o XP ganho

O usuário lembra que o jogo talvez já some isso em algum lugar. A tarefa A1 confirma, e o caminho escolhido vem do que ela achar, nesta ordem de preferência:

1. **Contador do próprio jogo:** um valor que sobe com o XP e não desce ao comprar golpe (estatística do save, conquistas, Konten).
   - O RPG só lê esse valor; não precisa guardar XP.
   - É o caminho mais simples e o mais fiel.
2. **Somar na entrada:** trocar a função que credita XP (a que trata `addexperience`/coleta do orbe; A2) por uma que chama a original e soma a quantia ao XP ganho do perfil.
   - O XP ganho vai para a foto do save.
3. **Somar pela diferença do saldo:** a cada quadro de gameplay, se o saldo subiu, somar a diferença.
   - Fica fora das trocas de save e de sala, que podem reescrever o saldo.
   - É o último recurso: frágil em carregamento.

**Save que já existia antes do modo:** no caminho 1, nada a fazer. Nos caminhos 2 e 3, o XP ganho inicial é o saldo atual mais o custo dos golpes já comprados (A3). Se o custo não puder ser lido, vale o saldo atual, e o LEIA-ME avisa que o nível desse save começa mais baixo.

**XP por personagem:** se cada personagem (Liu Kang, Kung Lao…) tem saldo e golpes próprios (A1 confirma), o nível e os pontos também são por personagem.

### 3.2 Nível e curva

- **Limite do nível n:** `limite(n) = RPG_XP_BASE × n^RPG_XP_EXPOENTE` de XP ganho.
- **Nível** = maior n com XP ganho ≥ limite(n), até `RPG_NIVEL_MAX`.
- **Ponto de partida** (calibrado na A1 com o XP medido; reavaliado na D3):
  - ~5 níveis até o fim do Goro's Lair;
  - ~1 nível por área depois;
  - perto do teto no fim do jogo.
- **Teto:** nível 50. Com teto de 20 pontos por atributo (3.3), dá para maximizar dois atributos e meio, não os três: as escolhas pesam.

| Valores de partida | `RPG_XP_BASE` | `RPG_XP_EXPOENTE` | `RPG_NIVEL_MAX` |
|---|---|---|---|
| Até a A1 medir | 100 | 1,5 | 50 |

### 3.3 Pontos e atributos

| Atributo | Efeito por ponto | Teto | Como entra no jogo |
|---|---|---|---|
| **Força** | +5% de dano causado | 20 pontos (+100%) | Multiplica o dano em que o atacante é o jogador (A5) |
| **Defesa** | −3% de dano recebido | 20 pontos (−60%) | Multiplica o dano em que o alvo é o jogador, com mínimo de 1 (A5) |
| **Vida** | +5% de vida máxima | 20 pontos (+100%) | Vida máxima do jogador ao começar a sala, ao subir de nível e ao gastar ponto (A4) |

- **Arredondamento:** dano e vida arredondados para o inteiro mais próximo; o dano nunca vai a 0.
- **Exceções:** morte instantânea do jogo (abismo, fatality) não passa pelos multiplicadores.
- **Redistribuir:** "Redistribuir pontos" na aba RPG devolve todos os pontos gastos (confirmação com X duas vezes). É um jogo para um jogador; travar a escolha só frustraria.

### 3.4 Onde se joga: janela "Opções", abas Gráfico e RPG

O menu Gráfico vira uma janela com **duas abas lado a lado**:

```
  Gráfico   [ RPG ]                              L1/R1: trocar aba
  ─────────────────────────────────────────────────────────────
  Modo RPG neste save                                 < Ligado >
  Liu Kang · Nível 7 · 2 pontos livres
  XP ganho        4.180 / 5.100   ▕██████████████░░░░░▏
  Força       3   +15% de dano causado               X: +1 ponto
  Defesa      2   −6% de dano recebido
  Vida        0   +0% de vida máxima
  Redistribuir pontos
  Fechar
  ─────────────────────────────────────────────────────────────
  Cima/Baixo: escolher   X: gastar/mudar   O ou R3: fechar
```

- **Abrir:** como hoje (R3 fora da gameplay: menu inicial, pausa do Select, mapa; F1 a qualquer hora). Abre na última aba usada.
- **Trocar aba:** L1/R1 no controle, Q/E no teclado (já são L1/R1 no teclado).
- **Aba Gráfico:** igual à de hoje, com "Restaurar recomendado" (feito em 15/11).
- **Aba RPG com o modo desligado** neste save: só a linha "Modo RPG neste save < Desligado >" e uma explicação de uma linha.
- **Gastar ponto:** X na linha do atributo; com zero pontos livres, a linha fica cinza. O efeito vale na hora.
- **Controle:** enquanto a janela está aberta, o jogo não recebe nada (`g_gfxBlockInput`, como hoje).
- **Dica:**
  - Com o modo desligado, continua "R3: Gráfico".
  - Com ele ligado, "R3: Gráfico · RPG".
  - Com pontos livres, "R3: RPG +2" na pausa.

### 3.5 Indicador e aviso de nível

- **Indicador:** "Nv 7" ou, com pontos livres, "Nv 7+2", em dourado, junto ao HUD do jogador 1 (posição exata na C3, por capturas). O tamanho acompanha a altura da imagem, e a posição é relativa à imagem do jogo (certo em 4:3 e 16:9).
  - Aparece na gameplay e na pausa, só com o modo ligado.
  - Some em filmes, cutscenes (se a A7 achar como distingui-las) e menus.
- **Aviso de nível:** ao subir, "NÍVEL 8! +1 ponto · R3 na pausa" no alto da imagem por 3 s, sem cobrir o HUD. Vários níveis de uma vez viram um aviso só ("NÍVEL 10! +3 pontos").

### 3.6 Ligar e desligar o modo

- **Começo de jogo:** na tela de escolha de dificuldade, a dica "R3: Modo RPG (desligado)" por cima. R3 alterna, como pedido em 15/11. Confirmada a dificuldade, o perfil nasce com o modo como estava.
- **Save já começado:** a linha "Modo RPG neste save" na aba RPG liga o modo. O nível sai do XP ganho (3.1), então ligar no meio do jogo dá o nível certo.
- **Desligar:** pela mesma linha. Os pontos ficam guardados e os efeitos param; religar devolve tudo.

### 3.7 Dados por save (a foto do save)

- **Arquivo:** `rpg_<cartão>[_<slot>].ini` ao lado do `mksm.ini` (ex.: `rpg_mc0.ini`), em texto `CHAVE=valor`:
  - `LIGADO`;
  - por personagem: `FORCA`, `DEFESA`, `VIDA` e, nos caminhos 2 e 3 de 3.1, `XP_GANHO`.
  - O `_<slot>` só existe se a A6 mostrar mais de um save por cartão.
- **Quando grava:** no instante em que o jogo grava o save, inclusive no autosave (o memory card passa pelo runtime, `Kernel/Stubs/MemoryCard.cpp`).
- **Quando lê:** quando o jogo carrega o save. Entre um e outro, o perfil vive na memória.
- **Por quê:** se o jogador morre e recarrega sem salvar, o XP ganho e os pontos voltam junto com o save, como no próprio jogo.
- **Arquivo inválido ou editado à mão** (fronteira de confiança): valores fora da faixa são limitados, linhas ilegíveis ignoradas, e soma de pontos maior que o nível zera os gastos. Nunca trava o jogo.
- **Save sem arquivo de RPG** = modo desligado.
- **Pastas portáteis:** o arquivo fica na raiz, ao lado do `mksm.ini`. Quem copia o save para outra pasta copia o `rpg_*.ini` junto (dito no LEIA-ME).

### 3.8 Dois jogadores

- A primeira versão cobre o jogador 1.
- O jogador 2 (cooperativo) entra na D4, com nível, pontos e indicador próprios, e a aba RPG perguntando de qual jogador.

### 3.9 Chaves `RPG_*` (no `mksm.ini`, todas opcionais)

| Chave | Padrão |
|---|---|
| `RPG_XP_BASE` | 100 |
| `RPG_XP_EXPOENTE` | 1,5 |
| `RPG_NIVEL_MAX` | 50 |
| `RPG_FORCA_POR_PONTO` | 5 (%) |
| `RPG_DEFESA_POR_PONTO` | 3 (%) |
| `RPG_VIDA_POR_PONTO` | 5 (%) |
| `RPG_TETO_ATRIBUTO` | 20 |

## 4. O que já sabemos (15/11)

| O quê | Onde / como |
|---|---|
| O jogo tem experiência e loja de golpes | HUD "EXP"; mapa do Start com "Experience" e "Moves" |
| Comandos de script ligados a XP e dano | Strings no ELF: `addexperience` (`0x575DA0`), `spawnexperience` (`0x578818`), `applydamage` (`0x586570`), `bodydamage` (`0x58F308`), `pickupdoubledamage` (`0x578C10`). Não há tabela com ponteiros para essas strings: cada comando é registrado por código |
| Registro do `addexperience` | Em `0x1671B0` (`sub_001671B0`): `func_362CE0(registro, "addexperience", descritor em 0x5CCDB0)`. O descritor fica na BSS e é preenchido em tempo de execução. A função que trata o comando é alcançada a partir dele: ponto de partida da A2 |
| Estrutura do jogador | `0x33C0` bytes por jogador; campos não mapeados (`MODDING.md` §5) |
| Estado da tela | `0x4F4B68` = 1 em gameplay e cutscene; `0x6BEE2C` = 1 na pausa do Select; `0x4C49E8` = 1 em menu dentro do jogo (N21). Carregamento também dá `0x4F4B68` = 0 (ARQUITETURA, menu Gráfico) |
| Saves | Memory card em `jogo/mc0/BASLUS-21087/` (um arquivo `BASLUS-21087`, 198.876 bytes). O log `[MC]` mostra cada GetDir/abertura |
| Save do usuário mais adiante no jogo | `portatil/backup_save_mc0_15nov/` (cópia de 15/11). Para testar áreas depois do Goro's Lair, copie para uma pasta de teste; nunca grave por cima do original |
| Tela por cima e controle bloqueado | Menu Gráfico (`updateGfxMenu`/`drawGfxMenu`, `g_gfxBlockInput`, `MKSM_GFX_SCRIPT`) em `ps2_runtime.cpp` |
| Trocar uma função do jogo | `runtime.replaceFunction(endereço, função)` em `game_overrides_mksm.cpp` (ex.: `skipIntro`) |

## 5. Mapa do código

| Peça | Onde |
|---|---|
| Estado, curva, chaves `RPG_*`, perfil, arquivo `rpg_*.ini` | Novo `ps2xRuntime/src/lib/mksm_rpg.cpp` + `mksm_rpg.h`, este incluído só pelos `.cpp` que usam (nunca pelo `ps2_runtime.h`). Entram no `patches/arquivos.txt` e no `target_sources` do `ps2EntryRunner` (como `game_overrides_mksm.cpp`) |
| Trocas de função (crédito de XP, dano, vida máxima) | `game_overrides_mksm.cpp`, chamando o `mksm_rpg` |
| Gravar/carregar o perfil junto com o save | Gancho no `Kernel/Stubs/MemoryCard.cpp` (escrita e leitura do arquivo do save) avisando o `mksm_rpg` |
| Janela Opções (abas), aba RPG, indicador, aviso, dica | `ps2_runtime.cpp`, ao lado do menu Gráfico |
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

## 7. Tarefas (faça na ordem)

### Fase A: investigação (só leitura; nada muda no jogo)

- [ ] **A1 XP: saldo, acumulado e por personagem**
  - **Faça:**
    - Na gameplay (R5), cópias da RAM antes e depois de matar inimigos (o saldo sobe), e antes e depois de comprar um golpe no mapa (o saldo desce).
    - Ache o **saldo** (bate com o HUD) e procure um **acumulado**: um valor que subiu com as mortes na mesma quantia e **não** desceu na compra. Olhe também perto do saldo, na estrutura do jogador e na área do save (o save carregado fica na RAM).
    - Troque de personagem (Kung Lao) e veja se o saldo é por personagem.
    - Meça o XP por inimigo e por sala nas primeiras salas do Goro's Lair e, no save do usuário, o saldo e o acumulado (se houver) no ponto em que ele está.
  - **Verifique:** três rodadas com os mesmos valores; o saldo bate com o HUD em todas as cópias.
  - **Pronto quando:** anotados aqui e no `MODDING.md` §5:
    - endereço ou ponteiro do saldo;
    - se existe acumulado (endereço) ou não;
    - se é por personagem;
    - XP por inimigo e por sala;
    - escolha do caminho de 3.1 e números da curva de 3.2.

- [ ] **A2 Quem credita o XP** (pule se a A1 achou o acumulado do jogo)
  - **Faça:**
    - A partir do registro em `0x1671B0` (descritor `0x5CCDB0`), ache a função que trata o comando `addexperience`.
    - Em paralelo, procure no código gerado quem grava no endereço/deslocamento do saldo da A1 (`grep` pelo deslocamento nos `sub_*.cpp`).
    - Confirme com um `replaceFunction` temporário que loga a quantia a cada chamada.
  - **Verifique:** a soma das quantias logadas = a subida do saldo, numa sala inteira; nenhuma chamada na compra de golpe.
  - **Pronto quando:** função, argumento da quantia e de quem recebe anotados aqui.

- [ ] **A3 Loja de golpes** (pule se a A1 achou o acumulado do jogo)
  - **Faça:** ache onde ficam os golpes comprados (bits ou contador por personagem) e o custo de cada um (tabela na RAM ou nos dados).
  - **Verifique:** saldo + custo dos golpes comprados ≥ saldo atual, e coerente com o XP medido na A1 para o ponto do save do usuário.
  - **Pronto quando:** como calcular o XP ganho inicial de um save antigo, anotado aqui.

- [ ] **A4 Vida do jogador 1**
  - **Faça:**
    - Cópias antes e depois de apanhar e de recuperar vida (item), e ao trocar de sala.
    - Ache vida atual e vida máxima e de onde a máxima vem: campo do jogador, tabela por personagem, ou dificuldade.
    - Veja se o jogo reescreve a máxima ao trocar de sala ou carregar.
    - Veja como a barra de vida é desenhada: proporção atual/máxima (aguenta máxima maior) ou largura fixa por ponto de vida (aí a Vida precisa de outro caminho).
  - **Verifique:** log temporário mostrando os valores coerentes com a barra em três rodadas, com Liu Kang e Kung Lao.
  - **Pronto quando:** endereços, origem da máxima e comportamento da barra anotados aqui e no `MODDING.md`.

- [ ] **A5 Dano**
  - **Faça:**
    - Ache a função que desconta a vida: quem grava a vida atual da A4 no código gerado, e o tratador do comando `applydamage` (registrado como o `addexperience`).
    - Descubra nos argumentos (`a0`–`a3`) quem ataca, quem recebe e a quantia.
    - Veja o que o `pickupdoubledamage` liga: se for um multiplicador no jogador, anote; pode servir de referência para a Força.
    - Liste as fontes de dano que passam por ali: golpes, armas, projéteis, armadilhas, quedas.
  - **Verifique:** com uma chave temporária `RPG_TESTE_DANO=2`, um wrapper dobra o dano quando o atacante é o jogador 1. Num roteiro de golpes fixo, a vida tirada do inimigo dobra; sem a chave, fica igual.
  - **Pronto quando:** função, argumentos e a lista de fontes anotados aqui.

- [ ] **A6 Como o jogo identifica o save**
  - **Faça:** com o log `[MC]`, salve e carregue em dois saves diferentes (se o jogo deixar), e veja arquivos, deslocamentos e tamanhos de cada leitura/gravação.
  - **Verifique:** dá para dizer, só pelo que passa no `MemoryCard.cpp`, qual save foi carregado e qual foi gravado (autosave incluído).
  - **Pronto quando:** regra do nome do `rpg_*.ini` decidida (por cartão ou por cartão e slot) e anotada aqui.

- [ ] **A7 Telas: dificuldade e cutscene**
  - **Faça:**
    - Cópias da RAM antes, durante e depois da tela de dificuldade (Single Player → personagem → dificuldade); anote também onde fica a dificuldade escolhida.
    - Cópias numa cutscene e na gameplay logo depois (Goro's Lair), procurando um valor que separe as duas (HUD visível).
  - **Verifique:** o valor da dificuldade muda só nessa tela, em três rodadas; o de cutscene separa as duas em três rodadas.
  - **Pronto quando:** os dois endereços anotados aqui (o de cutscene pode não existir; então o indicador fica também nas cutscenes).

### Fase B: núcleo (sem tela)

- [ ] **B1 Módulo `mksm_rpg`**
  - **Faça:** arquivo novo com:
    - as chaves `RPG_*` (3.9) e o perfil (ligado, por personagem: XP ganho se preciso, pontos gastos);
    - `nivel(xpGanho)`, `limite(n)`, `pontosLivres()` e os multiplicadores.
    - Nada ligado ao jogo ainda.
  - **Verifique:** asserção que roda uma vez:
    - nível 0 com XP 0;
    - o nível sobe exatamente no limite e nunca desce;
    - o teto é respeitado;
    - multiplicadores com 0, 1 e 20 pontos batem com a tabela de 3.3.
    - Testes `ps2x_tests` iguais.
  - **Pronto quando:** módulo compilando no Linux e no Windows (`scripts/build_windows.sh`), com as asserções passando.

- [ ] **B2 XP ganho ao vivo**
  - **Faça:** o caminho escolhido na A1:
    - caminho 1: ler o acumulado;
    - caminho 2: wrapper da A2 somando a quantia;
    - caminho 3: diferença do saldo.
    - XP ganho inicial de saves antigos pela A3.
    - Com o modo desligado, o wrapper só chama a original.
  - **Verifique:** log temporário numa sala inteira (o XP ganho acompanha o saldo e não desce na compra de golpe); modo desligado com a mesma sequência de saldo de antes.
  - **Pronto quando:** medido e anotado aqui.

- [ ] **B3 Foto do save**
  - **Faça:** gravar o perfil no `rpg_*.ini` quando o jogo grava o save, e ler quando carrega (regra da A6); validação de 3.7.
  - **Verifique:**
    - salvar, sair e carregar: perfil igual;
    - ganhar XP e gastar ponto, morrer e recarregar sem salvar: volta ao gravado;
    - arquivo corrompido à mão: jogo abre, valores limitados;
    - save sem arquivo: modo desligado.
  - **Pronto quando:** os quatro casos testados (roteiro ou usuário) e anotados aqui.

- [ ] **B4 Efeitos: Força, Defesa e Vida**
  - **Faça:**
    - Força e Defesa no wrapper da A5, com as exceções de 3.3.
    - Vida na máxima da A4, reaplicada onde o jogo a reescreve; ao ganhar Vida, a vida atual sobe na mesma quantia.
  - **Verifique:** roteiro de golpes fixo com 0, 5 e 10 pontos em cada atributo; dano causado, dano recebido e vida máxima batem com a tabela (±1 de arredondamento); barra de vida desenhada certo.
  - **Pronto quando:** a tabela medida anotada aqui.

### Fase C: tela

- [ ] **C1 Janela Opções com abas**
  - **Faça:**
    - O menu Gráfico vira a aba Gráfico de uma janela com abas (3.4), sem mudar nada dentro dela.
    - L1/R1 e Q/E trocam de aba; o `MKSM_GFX_SCRIPT` ganha `q`/`e`.
    - A aba RPG pode estar vazia nesta tarefa.
  - **Verifique:** capturas da aba Gráfico iguais às de antes (fora o título das abas); roteiro troca de aba e volta.
  - **Pronto quando:** capturas anotadas.

- [ ] **C2 Aba RPG**
  - **Faça:** o conteúdo de 3.4: ligar/desligar, nível, barra de XP, pontos livres, atributos com efeito, X gasta, "Redistribuir pontos" com confirmação, linha cinza sem pontos.
  - **Verifique:** roteiro que liga o modo, gasta pontos, redistribui e fecha; efeito na hora (B4); `rpg_*.ini` atualizado no próximo save.
  - **Pronto quando:** roteiro e capturas anotados.

- [ ] **C3 Indicador e aviso de nível**
  - **Faça:** "Nv 7" / "Nv 7+2" junto ao HUD e o aviso de 3.5; esconder em filmes, menus e cutscenes (A7).
  - **Verifique:** capturas em 4:3 e 16:9, gameplay e pausa, sem cobrir a barra de vida nem o "EXP"; um nível ganho no roteiro mostra o aviso uma vez; modo desligado sem nada na tela.
  - **Pronto quando:** capturas anotadas.

- [ ] **C4 Ligar na tela de dificuldade**
  - **Faça:** com o endereço da A7, a dica "R3: Modo RPG (desligado/ligado)" por cima da tela de dificuldade. R3 alterna, com o controle bloqueado só durante a troca; confirmar a dificuldade cria o perfil.
  - **Verifique:** começar um jogo com e sem o modo por roteiro; o indicador só aparece no primeiro.
  - **Pronto quando:** os dois caminhos testados.

### Fase D: prova, ajuste e acabamento

- [ ] **D1 Modo desligado igual ao original**
  - **Faça:** com o modo desligado (e sem `rpg_*.ini`):
    - `ps2x_tests`;
    - R4/R4b do `PLANO_DESEMPENHO.md` (hashes das cenas);
    - o roteiro de golpes da B4, registrando a vida do jogador e do inimigo a cada golpe, contra a mesma gravação feita antes da Fase B.
  - **Pronto quando:** tudo igual, número por número.

- [ ] **D2 Pasta portátil e Windows**
  - **Faça:**
    - `scripts/empacotar_linux.sh` e `scripts/build_windows.sh`;
    - LEIA-ME das duas pastas com o modo RPG (como ligar, onde fica o `rpg_*.ini`, copiar junto com o save);
    - `mksm.ini` com as chaves `RPG_*` comentadas.
  - **Verifique:** o modo funciona nas duas pastas (Windows: pelo menos no Wine, e o usuário confirma no Windows).
  - **Pronto quando:** as duas pastas geradas e testadas.

- [ ] **D3 Balanceamento (com o usuário)**
  - **Faça:** o usuário joga no modo RPG do começo e do ponto do save dele e diz se ficou fácil ou difícil. Ajustar curva, efeitos e tetos pelas chaves `RPG_*`.
    - Se o jogador ficar forte demais no fim, considerar inimigos mais fortes por nível (nova tarefa; não entra sem pedido).
  - **Pronto quando:** o usuário aprovar.

- [ ] **D4 Segundo jogador**
  - **Faça:** A4, B4 e C3 para o jogador 2 (estrutura seguinte, `+0x33C0`?), cada um com perfil, pontos e indicador próprios; a aba RPG escolhe o jogador.
  - **Pronto quando:** testado com dois controles.

- [ ] **D5 Documentação**
  - **Faça:**
    - `ARQUITETURA.md`: janela com abas, ganchos do RPG, foto do save, armadilhas achadas.
    - `MODDING.md`: endereços das tarefas A.
    - Este plano com tudo marcado.
  - **Pronto quando:** commit com tudo atualizado.

## 8. Decisões tomadas (o usuário pode mudar)

| Decisão | Escolha | Por quê |
|---|---|---|
| Nível sai de | XP ganho (só sobe) | Pedido de 15/11: comprar golpe não tira nível |
| Onde distribuir os pontos | Aba RPG ao lado da aba Gráfico, na mesma janela do R3 | Pedido de 15/11 ("no próprio R3, do lado") |
| Ligar o modo | Na tela de dificuldade, e também na aba RPG para saves já começados | Pedido original + não obrigar a recomeçar o jogo |
| Redistribuir | Livre, com confirmação | Jogo para um jogador; experimentar faz parte |
| Pontos por nível / teto de nível | 1 / 50 | Teto de 20 por atributo: dá para maximizar ~2,5 dos 3 |
| Morrer e recarregar | O perfil volta à foto do save | Igual ao que o jogo faz com o XP e os golpes |
| Inimigos mais fortes | Não | Fora do pedido; ver D3 |

## 9. Perguntas para o usuário (juntar aqui; não parar por elas)

- Ritmo da curva: ~5 níveis no Goro's Lair e ~1 por área depois está bom?
- Força +5%, Defesa −3% e Vida +5% por ponto, teto de 20 cada: bom para começar?
- Redistribuir livre ou só em algum momento (por exemplo, no começo de cada fase)?

## 10. Riscos conhecidos

- **O acumulado pode não existir:** os caminhos 2 e 3 cobrem, mas um save antigo pode começar com nível mais baixo se a loja de golpes não puder ser lida (A3).
- **A barra de vida pode não aceitar uma máxima maior:** a A4 mede. Se não aceitar, a Vida vira "regenerar vida" ou "dano recebido" e o usuário decide.
- **Chefes com fases por porcentagem de vida:** mais dano pode pular falas ou fases; a B4 inclui um chefe no teste quando houver save perto de um.
- **Identificação do save:** se o jogo usar um arquivo só, com slots dentro, o nome do `rpg_*.ini` depende do deslocamento (A6).
- **Cutscene × gameplay:** sem um valor que separe as duas (A7), o indicador aparece também nas cutscenes.
