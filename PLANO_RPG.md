# Plano do Modo RPG

Pedido do usuário (15/11): um modo opcional, escolhido no começo do jogo junto da dificuldade, em que a experiência dá níveis, e cada nível dá 1 ponto para distribuir entre atributos que deixam o personagem mais forte. Na tela aparece o nível ("Nv 5"); com pontos para distribuir, "Nv 5+1". **Velocidade fica de fora** (decisão do usuário: mexer na velocidade quebra golpes, combos e colisões).

Faça as tarefas da seção 4 **na ordem, uma por vez**. Marque `[x]` e anote os números medidos na própria tarefa. Leia antes o `ARQUITETURA.md` (threads, janela, armadilhas) e a N21 do `PLANO_DESEMPENHO.md` (menu Gráfico: é a mesma técnica de tela por cima, detecção por RAM e roteiro de teste).

---

## 1. Regras de ouro

1. **Com o modo desligado, o jogo não muda nada.**
   - Nenhuma escrita na RAM do jogo e nenhum desvio de comportamento.
   - As funções substituídas (`runtime.replaceFunction`) chamam a original sem tocar em nada quando o RPG está desligado.
   - Prova: R3/R4/R4b do `PLANO_DESEMPENHO.md` iguais e o roteiro de gameplay da tarefa R11 com a mesma vida perdida.
2. **Não mexer nos arquivos do jogo** (WAD, ELF, memory card). Tudo fica no runtime: `game_overrides_mksm.cpp` e a janela (`ps2_runtime.cpp`).
3. **Os dados do RPG não vão para o save do jogo.** Ficam num arquivo próprio ao lado do `mksm.ini` (ver R10), e o save continua igual ao original: abre num jogo sem o modo e num PS2.
4. **Sem velocidade:** nada que altere tempo de animação, movimento, hitbox ou quadros de golpe.
5. **Números ajustáveis num lugar só** (tabela no código, ou chaves `RPG_*` no `mksm.ini`), para o balanceamento da R12 não exigir recompilar.
6. Regras gerais do projeto: as do `CLAUDE.md` (commits só do usuário, sem dados do jogo no git, `PS2Recomp/` só por `scripts/atualizar_patches.sh`, diagnósticos temporários saem antes do commit).

## 2. O que já sabemos (15/11)

| O quê | Onde / como |
|---|---|
| O jogo já tem experiência | HUD mostra "EXP"; o mapa do Start mostra "Experience" e "Moves" (no original, a experiência libera golpes) |
| Comandos internos ligados a XP e dano | strings no ELF: `addexperience`, `spawnexperience`, `applydamage`, `bodydamage`, `pickupdoubledamage` (o jogo já multiplica dano com o item "dano dobrado") |
| Estrutura do jogador | `0x33C0` bytes por jogador; campos não mapeados (MODDING.md §5) |
| Estado da tela | `0x4F4B68` = 1 em gameplay e cutscene; `0x6BEE2C` = 1 na pausa do Select; `0x4C49E8` = 1 em menu dentro do jogo (N21) |
| Técnica para achar campos | cópias da RAM em momentos marcados e comparação (como na N21: `MENUDUMP` temporário + roteiro `MKSM_AUTO_HOLD`/`MKSM_AUTO_SELECT_AT`) |
| Tela por cima e controle bloqueado | menu Gráfico (`updateGfxMenu`/`drawGfxMenu`, `g_gfxBlockInput`, `MKSM_GFX_SCRIPT` para testar sem controle) |
| Trocar uma função do jogo | `runtime.replaceFunction(endereço, função)` em `game_overrides_mksm.cpp` (ex.: `skipIntro` chama a original no meio) |

## 3. Como o modo funciona (desenho)

- **Ativação:** na tela de escolha de dificuldade, uma dica "R3: Modo RPG" por cima. R3 alterna desligado/ligado (com controle bloqueado durante a escolha, como no Gráfico). A escolha vale para o jogo começado ali e fica gravada com os dados do RPG daquele save (R10). Num save sem RPG, o modo fica desligado.
- **Nível:** sai da experiência total que o próprio jogo acumula (não inventamos outra fonte). Curva calibrada na R6 com o XP medido por luta, por exemplo nível n exige `RPG_XP_BASE · n^1,5` de XP total.
- **Pontos:** 1 por nível ganho, distribuídos no menu "Atributos" (por cima, aberto na pausa com R3 quando o RPG está ligado; a pausa passa a oferecer "Gráfico" e "Atributos"). Pontos gastos não voltam (sem "resetar" na primeira versão).
- **Atributos** (valores iniciais para ajustar na R12):

  | Atributo | Efeito por ponto | Teto sugerido |
  |---|---|---|
  | Força | +5% de dano causado | +100% (20 pontos) |
  | Defesa | −3% de dano recebido | −60% (20 pontos) |
  | Vida | +5% de vida máxima | +100% (20 pontos) |

- **Indicador na tela:** "Nv 5", ou "Nv 5+1" com pontos livres, desenhado pela janela num canto da imagem do jogo, sem cobrir o HUD. Aparece na gameplay e na pausa, só com o RPG ligado. Respeita o 16:9 (posição relativa à imagem, não à janela).
- **Dois jogadores:** a primeira versão cobre o jogador 1; o jogador 2 entra na R13.

## 4. Tarefas (faça na ordem)

### R1 Achar a tela de dificuldade
- **Faça:** roteiro até a tela de dificuldade (Single Player → personagem → dificuldade), cópias da RAM antes, durante e depois dela, comparação como na N21. Anote também onde fica a dificuldade escolhida.
- **Verifique:** o endereço muda só nessa tela, em três rodadas, e não muda no resto do menu inicial nem na gameplay.
- **Pronto quando:** endereço e valores anotados aqui, com o roteiro usado.

### R2 Mapear o jogador 1 (XP, vida atual, vida máxima)
- **Faça:** cópias da RAM na gameplay antes e depois de ganhar experiência (derrotar um inimigo), de apanhar e de recuperar vida. Ache o ponteiro para a estrutura do jogador (`0x33C0` bytes) e os deslocamentos de XP total, vida atual e vida máxima. Confirme se a vida máxima vem dessa estrutura ou de uma tabela por personagem.
- **Verifique:** um log temporário (sai antes do commit) mostra os três valores mudando coerentes com a tela (HUD "EXP", barra de vida) em três rodadas, com Liu Kang e com Kung Lao.
- **Pronto quando:** ponteiro e deslocamentos anotados aqui e no `MODDING.md` §5.

### R3 Achar onde o dano é aplicado
- **Faça:**
  - Procure no ELF a tabela de comandos do script: a string `applydamage` costuma estar ao lado do endereço da função que trata o comando. Ache essa função e a que ela chama para descontar a vida.
  - Se não houver tabela, ache quem escreve o deslocamento de vida da R2 no código gerado.
  - Descubra quem é o atacante e quem é o alvo nos argumentos (registradores `a0`–`a3`).
- **Verifique:** com uma chave de teste (`RPG_TESTE_DANO=2`, temporária), um wrapper via `replaceFunction` dobra o dano quando o atacante é o jogador 1. Num roteiro de golpes fixo, a vida tirada do inimigo dobra; sem a chave, fica igual à de antes.
- **Pronto quando:** função, argumentos e o teste do dobro anotados aqui.

### R4 Conferir o multiplicador do "dano dobrado"
- **Faça:** ache o campo que o `pickupdoubledamage` liga. Se for um multiplicador no jogador, ele pode servir para a Força sem interceptar função nenhuma.
- **Pronto quando:** decidido e anotado o caminho da Força: multiplicador do jogo ou wrapper da R3.

### R5 Vida máxima
- **Faça:** com o RPG ligado, aplique +% na vida máxima ao começar a fase e ao subir de nível, sem passar do valor que a barra de vida aguenta desenhar. Confira como o jogo recupera vida (itens, troca de sala) e se ele reescreve a vida máxima.
- **Verifique:** barra de vida desenha certo; a recuperação respeita a nova vida máxima; com o RPG desligado, o valor é o original.
- **Pronto quando:** medido e anotado aqui (vida máxima por ponto, onde é aplicada).

### R6 Nível e pontos a partir do XP
- **Faça:**
  - Meça quanto XP o jogo dá por inimigo e por sala, a partir do campo da R2, nas primeiras salas do Goro's Lair.
  - Escolha a curva (`RPG_XP_BASE` e o expoente) para cerca de 1 nível por sala no começo, ficando mais espaçado depois.
  - Calcule nível = maior n com XP total ≥ limite(n), e pontos livres = nível − pontos gastos.
- **Verifique:** teste por asserção da curva (nível 0 com XP 0, nível sobe exatamente no limite, nunca desce).
- **Pronto quando:** curva e medidas anotadas aqui.

### R7 Indicador "Nv 5" / "Nv 5+1"
- **Faça:** desenhe na janela (raylib, como a dica do Gráfico), canto superior esquerdo da imagem do jogo, abaixo do HUD, tamanho proporcional à altura da imagem. Aparece só com o RPG ligado, na gameplay e na pausa (`0x4F4B68`, `0x6BEE2C`), fora de filmes e menus.
- **Verifique:** capturas em 4:3 e 16:9 na gameplay e na pausa, sem cobrir a barra de vida nem o "EXP". Com o RPG desligado, nada aparece.
- **Pronto quando:** capturas conferidas (anote os nomes).

### R8 Menu "Atributos"
- **Faça:**
  - Na pausa, com o RPG ligado, R3 abre uma escolha "Gráfico / Atributos".
  - Atributos mostra nível, pontos livres e Força/Defesa/Vida com o valor atual e o efeito: esquerda/direita escolhe, X gasta 1 ponto, O fecha.
  - O controle fica bloqueado para o jogo enquanto o menu está aberto (`g_gfxBlockInput`).
  - Teste sem controle: estender o `MKSM_GFX_SCRIPT` ou criar um `MKSM_RPG_SCRIPT`.
- **Verifique:** roteiro que gasta pontos; efeito aplicado na hora (R3 a R5); "+1" do indicador some quando os pontos acabam.
- **Pronto quando:** roteiro e capturas anotados.

### R9 Ativação na tela de dificuldade
- **Faça:** com o endereço da R1, mostre "R3: Modo RPG (desligado)" por cima da tela de dificuldade; R3 alterna. Ao confirmar a dificuldade, o estado vai para o save novo (R10).
- **Verifique:** começar um jogo com e sem o modo; o indicador da R7 só aparece no primeiro.
- **Pronto quando:** os dois caminhos testados por roteiro.

### R10 Guardar os dados do RPG por save
- **Faça:**
  - Ache como saber qual save está carregado. O memory card passa pelo runtime (`[MC]` no log): use o diretório e o arquivo que o jogo abre ao carregar e ao salvar.
  - Grave `rpg_<save>.ini` (ligado, pontos gastos por atributo) ao lado do `mksm.ini`, no mesmo momento em que o jogo salva. O XP e o nível não precisam ser gravados, porque saem do XP do próprio save.
  - Save sem arquivo de RPG = modo desligado.
- **Verifique:** salvar, sair, carregar: nível, pontos e atributos voltam iguais. Um save com RPG aberto com o modo de outro jogo continua funcionando no jogo normal.
- **Pronto quando:** testado com dois saves (um com e um sem RPG).

### R11 Provar que os modos normais não mudaram
- **Faça:** com o RPG desligado:
  - testes `ps2x_tests`, R4 e R4b do `PLANO_DESEMPENHO.md`;
  - o roteiro de gameplay do `gp.sh` com a vida do jogador e do inimigo registrada a cada golpe, antes e depois do modo existir (mesma sequência e valores).

  Com o RPG ligado: o mesmo roteiro com Força/Defesa em 0, 5 e 10 pontos, medindo o dano causado e recebido.
- **Pronto quando:** tudo igual com o modo desligado, e os efeitos com ele ligado batendo com a tabela da seção 3 (±1 de arredondamento).

### R12 Balanceamento (com o usuário)
- **Faça:** o usuário joga as primeiras salas no modo RPG e diz se ficou fácil ou difícil demais. Ajuste por ponto, tetos e curva pelas chaves `RPG_*`. Se o jogador ficar forte demais, considere fortalecer os inimigos junto com o nível.
- **Pronto quando:** o usuário aprovar.

### R13 Segundo jogador (cooperativo)
- **Faça:** repita R2, R5 e R7 para o jogador 2 (estrutura seguinte, `+0x33C0`?). Cada um com nível, pontos e indicador próprios; o menu Atributos pergunta qual jogador.
- **Pronto quando:** testado com dois controles.

## 5. Perguntas para o usuário (juntar aqui, não parar)

- Curva de nível: 1 nível por sala no começo está bom, ou prefere mais rápido ou mais lento?
- Os números da tabela (+5% de dano, −3% de dano recebido, +5% de vida por ponto) estão bons para começar?
- O modo vale por save (escolhido ao começar o jogo) ou como opção geral que vale em qualquer save?
- Quer um jeito de redistribuir os pontos (por exemplo, no começo de cada fase)?
