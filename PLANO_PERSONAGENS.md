# Plano: lutadores do Versus jogáveis na história

**Pedido do usuário (16/11):**
- Investigar tudo do modo Versus.
- Ver se dá para pôr todos os lutadores do Versus como jogáveis, e fazer o plano completo.
- No Versus, os lutadores liberam com o tempo de jogo: o usuário pediu para deixar **todos liberados** no repositório.

**Como usar este plano:** mesmo formato do `PLANO_RPG.md` e do `PLANO_DESEMPENHO.md`. Faça as tarefas da seção 5 na ordem, uma por vez (Faça / Verifique / Pronto quando). Ao terminar uma tarefa, marque `[x]` e anote os endereços e números medidos. Antes, leia o `ARQUITETURA.md` e o `MODDING.md` §5.

## 1. Regras

1. **Arquivos do jogo intactos:** nada muda no WAD, no ELF nem no memory card por fora. Tudo fica no runtime (trocas de função, escritas na RAM).
2. **Sem a opção ligada, o jogo é o original:** a escolha de um lutador do Versus na história é opcional. A liberação do Versus fica ligada por padrão, porque o usuário pediu; `MKSM_VERSUS_TODOS=0` desliga.
3. **Regras do projeto** (`CLAUDE.md`):
   - `PS2Recomp/` só por `scripts/atualizar_patches.sh`.
   - Nenhum header novo no `ps2_runtime.h`.
   - Diagnósticos temporários saem antes do commit.

## 2. O que já sabemos (investigação de 16/11)

| O quê | Onde / como |
|---|---|
| Lutadores do Versus | 9 na seleção. Visto liberado: Baraka, Kitana (ou Mileena), Sub-Zero, Kung Lao, Liu Kang, Scorpion, Johnny Cage e Reptile, mais um lugar a conferir. Num jogo novo, só Liu Kang e Kung Lao vêm liberados |
| Liberação | Lista de bits do Konten em `0x5D8280` (o save a guarda). `CharLocked(n)`, a consulta do menu (tratador em `0x1C1FE8`), testa o bit `n`. `unlockchar(n)` (`func_1C1A20`) liga o bit `n`. Outras categorias usam bases de bit: 92, 101, 166, 343 e 360 |
| Bits dos lutadores | Bits 80–87 (palavra `0x5D8288`, máscara `0x00FF0000`): Baraka, Scorpion e Reptile. Bits 88–91 (máscara `0x0F000000`): Kitana/Mileena, Sub-Zero e Johnny Cage |
| **Feito: todos liberados** | `ps2_runtime.cpp` liga `0x0FFF0000` em `0x5D8288` sempre que falta algum bit (`MKSM_VERSUS_TODOS=0` desliga). Testado: seleção com todos coloridos e luta Johnny Cage × Kung Lao jogável. Captura em `capturas/versus_todos.png` |
| Número do personagem | Halfword em `estrutura do jogador + 0x1E0E`. Jogador 1 em `0x5E6B40`, jogador 2 em `0x5E9F00` (`0x5E3780 + 0x33C0 × n`; `func_283B50(0x67C590, n)` devolve o ponteiro). Liu Kang = 0, Kung Lao = 1, Johnny Cage = 90: **o número é o mesmo bit que libera o lutador** |
| Seleção da história | 4 lugares: Liu Kang, Kung Lao, Sub-Zero e Scorpion. Os dois últimos não abrem com bit nenhum do Konten (testado com os bits 0–127): a história usa outra marca para eles |
| **Teste-chave:** Johnny Cage forçado na história | Escrevendo 90 em `0x5E6B40+0x1E0E` antes do Goro's Lair carregar, o HUD mostra "JOHNNY CAGE", mas o corpo é o do Liu Kang, que faz poses estranhas. Conclusão: o nome e parte do comportamento seguem o número, mas o **modelo e os dados do personagem são escolhidos antes e em outro lugar**. Captura em `capturas/personagem_jc_na_historia.png` |
| Outros fios | `unlockendofgame` (`func_1C21B8`) lê o personagem do jogador e liga o bit 82 (Liu) ou 88 (Kung Lao): o fim de jogo de cada monge libera um lutador. `unlockmk2` grava `[0x5D82B0] = 1`. Strings: `CHARACTER_MEMORY`, `CUSTOM_CHARACTER_MEMORY`, `Setup_MainCharacter`, `Process_Character_Data`, `New_Process_Character` |

## 2b. Avanço de 16/11, à noite (prova feita)

- **O personagem da fase vem do save:** `save+0xCC` (jogador 1) e `save+0xD0` (jogador 2), lidos por `func_1CEE00` ao montar a sala, que chama `func_2F6BA0(número, jogador)`. Esta grava `+0x1E0E` e `+0x2AAC` da estrutura do jogador e as listas `0x6F5D98`/`0x6F5DD0`. Trocar só o `+0x1E0E` muda o nome no HUD, mas não o corpo.
- **Prova:** com `save+0xCC = 90`, o Johnny Cage entra no Goro's Lair com o próprio modelo, anda e tem o nome no HUD.
- **Números (cada um carregado no Goro's Lair):**

| Número | Personagem | Número | Personagem |
|---|---|---|---|
| 0 | Liu Kang | 85 | Ermac (não está no Versus) |
| 1 | Kung Lao | 88 | Sub-Zero |
| 82 | Scorpion | 89 | Kitana |
| 83 | Baraka | 90 | Johnny Cage |
| 84 | Reptile | 81 | gigante de quatro braços (Goro/Kintaro) |
| 2, 3, 80, 86, 87 | inimigos genéricos ou sem nome claro | 91 | trava no carregamento |

- **Varredura de 16/11 (números 0–30 e 80–110 carregados no Goro's Lair, apertando quadrado, triângulo, bola e X):**
  - **Respondem com os próprios golpes:** Sub-Zero (88), Scorpion (82), Johnny Cage (90), Reptile (84), Baraka (83) e Kitana (89); também o gigante de quatro braços (81), o encapuzado Shang Tsung (27, magias rosa e verde) e o demônio de lava (30, fogo e explosão).
  - **Carregam, mas ficam parados de braços abertos (sem golpes de jogador):** Ermac (85), um Liu Kang alternativo (5), um homem de terno (6) e uma mulher de roupa rosa (23).
  - **Inimigos genéricos (7–22, 24–26, 28, 29):** monges, ninjas, esqueletos, demônios vermelhos, macaco branco. Não testados no controle.
  - **4:** tela preta. **91 e 92–110:** travam no carregamento.
  - **Especiais (L1 + botão)** não testados: o roteiro não aperta L1.
  - **Personagem secreto do Versus:** andando o cursor pela seleção, só aparecem os 8 conhecidos.
- **Feito: escolha só no jogo novo** (o usuário pediu, para não bagunçar golpes comprados e fatalities; a aba do meio do jogo saiu). Na tela de dificuldade de um jogo novo, L1/R1 no controle de cada jogador (Q/E no teclado) trocam o lutador: Liu Kang, Kung Lao, Sub-Zero, Scorpion, Baraka, Reptile, Kitana, Johnny Cage, e Goro, Shang Tsung e o demônio de lava (experimentais; Ermac saiu: não obedece ao controle). "O da seleção" é o original. A troca de `func_1CEE00` grava `save+0xCC`/`0xD0` quando a primeira sala é montada (antes disso o jogo ainda reescreve). Depois, o lutador fica no save do jogo. Testado: Ko-op novo com Sub-Zero e Baraka no Goro's Lair. Roteiro de teste: `MKSM_TEST_LUTADOR=88,83`.
- **A seleção da história continua com 4 lugares**, e Sub-Zero e Scorpion seguem bloqueados nela: não abrem com nenhum bit do Konten (bits 0–511 testados). A aba Personagens resolve sem isso.
- **Falta (Fase C):** jogar cada lutador numa fase inteira (golpes, armas, loja de golpes, chefe, cutscenes). Só o andar e o modelo foram vistos.

## 3. Como seria (o desenho)

O usuário escolhe, para a história (Single Player ou Ko-op), um dos lutadores do Versus. O jogo carrega o modelo, os golpes e os sons dele, e ele joga o Goro's Lair e o resto como se fosse um dos monges.

- **Onde escolher:** na própria seleção da história, com os lutadores do Versus a mais. Se a lista do jogo não aceitar mais lugares, uma linha nova na janela de opções (R3/F1), "Personagem da história", que vale no próximo jogo novo ou carregado.
- **O que precisa casar:**
  1. **Carga do personagem:** o caminho que a seleção usa para escolher modelo, texturas, golpes e banco de som. É ele que precisa receber o lutador do Versus, e não só o número em `+0x1E0E` (teste-chave).
  2. **Memória:** a área `CHARACTER_MEMORY` tem tamanho fixo. Um lutador do Versus pode ser maior que um monge.
  3. **Golpes:** os do Versus são feitos para luta 1 × 1; a história tem vários inimigos, pegar armas, quebrar objetos, brutalidades e fatalities por fase. O que faltar no lutador pode travar ou deixar um botão sem efeito.
  4. **Loja de golpes e XP:** a loja do mapa lista golpes do personagem. Para um lutador do Versus pode vir vazia ou errada.
  5. **Roteiro das fases:** cutscenes e eventos que conferem se o jogador é o personagem 0 ou 1 (como o `unlockendofgame`). Com outro número, podem não disparar ou mostrar o monge.
  6. **HUD e retrato:** o nome já segue o número (visto). Falta o retrato no círculo do HUD.
  7. **Ko-op:** dois lutadores do Versus ao mesmo tempo, ou um monge e um lutador.
- **Modo RPG:** funciona igual, porque o RPG lê XP, dano e vida, não o personagem.

## 4. Riscos

- **O lutador do Versus pode não ter tudo que a história usa** (item 3). Pior caso: só dá para jogar até certo ponto, ou só nas arenas. Mitigação: começar só pela troca de modelo e golpes e testar fase por fase.
- **Memória:** se o lutador não couber, ele fica de fora, ou é preciso achar como o Versus aumenta a área.
- **Cutscenes com o monge:** aceitável (o usuário decide); o personagem jogável volta depois da cena.
- **Saves:** o personagem escolhido precisa ir junto com o save, como o RPG (`*_slot<n>.ini`), sem mudar o arquivo do cartão.

## 5. Tarefas

### Fase A: investigação

- [x] **A0 Versus com todos liberados** (feito 16/11; ver a seção 2).
- [x] **A1 Número de cada lutador** (16/11: tabela na seção 2b)
  - **Faça:** no Versus, escolha cada lutador e leia `0x5E6B40+0x1E0E` (cópia da RAM na luta). Confira o nono lugar.
  - **Pronto quando:** tabela nome → número → bit anotada aqui e no `MODDING.md`.
- [x] **A2 O que a seleção grava** (16/11: `save+0xCC`/`0xD0`, `func_1CEE00` → `func_2F6BA0`)
  - **Faça:**
    - Compare a RAM logo depois de aceitar Liu Kang e logo depois de aceitar Kung Lao na história, e o mesmo no Versus com um lutador. Procure, além de `+0x1E0E`, o valor que o carregamento lê (global, save ou outra estrutura).
    - Ache quem chama `Setup_MainCharacter`/`New_Process_Character` e com que argumento.
  - **Verifique:** trocar esse valor antes do Goro's Lair carregar faz o modelo do Kung Lao aparecer numa história iniciada com o Liu Kang.
  - **Pronto quando:** endereço e função anotados.
- [x] **A3 Lutador do Versus na história (prova)** (16/11: Johnny Cage no Goro's Lair; golpes e luta ainda sem teste)
  - **Faça:** com o caminho da A2, carregue o Johnny Cage no Goro's Lair.
  - **Verifique:** modelo, golpes básicos (soco, chute, pulo, agarrão), dano nos inimigos, morte e volta.
  - **Pronto quando:** capturas e a lista do que funciona e do que não funciona anotadas.
- [ ] **A4 Memória e dados por lutador:** tamanho dos dados de cada lutador contra a área `CHARACTER_MEMORY` (onde fica, quanto cabe, como o Versus faz). **Pronto quando:** tabela de quem cabe.
- [ ] **A5 Seleção da história:** como ela monta os 4 lugares (onde fica a lista, o que trava Sub-Zero e Scorpion) e se aceita mais. **Pronto quando:** decidido entre a lista do jogo e a linha na janela de opções (3.).

### Fase B: escolha e carga

- [x] **B1 Escolher o lutador** (16/11: L1/R1 na tela de dificuldade do jogo novo, gravando no save do jogo): na seleção da história (A5) ou na janela de opções, com o número salvo por slot (`personagem_mc0_slot<n>.ini` ou dentro do perfil do RPG).
- [x] **B2 Carregar o lutador** (o próprio jogo carrega pelo save): troca de função no caminho da A2, só quando a opção está ligada. Sem ela, o jogo é o original (regra 2).
- [x] **B3 Ko-op** (jogador 2 na mesma aba): o jogador 2 também escolhe.

### Fase C: compatibilidade, fase por fase

- [ ] **C1 Goro's Lair inteiro com cada lutador:** golpes, armas, objetos, chefe, cutscenes, loja de golpes. Anote por lutador o que falha.
- [ ] **C2 Correções:** para cada falha da C1, a correção no runtime ou um aviso ("este lutador não tem X"). Golpe faltando pode usar um do monge.
- [ ] **C3 Demais fases:** depende de saves do usuário mais adiante (`portatil/backup_save_mc0_15nov` e o atual).

### Fase D: acabamento

- [ ] **D1 Sem a opção = original:** testes e replays (R3/R4 do `PLANO_DESEMPENHO.md`) iguais.
- [ ] **D2 Documentação e pastas portáteis:** README (os dois), LEIA-ME, `MODDING.md`, `ARQUITETURA.md`.

## 6. Decisões

| Decisão | Escolha | Origem |
|---|---|---|
| Lutadores do Versus | Todos liberados, ligados por padrão (`MKSM_VERSUS_TODOS=0` desliga) | Usuário, 16/11 |
| Lutadores na história | A investigar (Fase A); opcional | Usuário pediu o plano, 16/11 |
| 4 jogadores | Fora por enquanto (exige mudar a lógica do jogo para mais de dois jogadores) | Usuário, 16/11 ("esquece isso por enquanto") |
