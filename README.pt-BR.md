# Mortal Kombat: Shaolin Monks — recompilação estática do PS2

[English](README.md) · **Português (Brasil)**

**Recompilação estática** do *Mortal Kombat: Shaolin Monks* de **PlayStation 2** (USA, `SLUS-210.87`) para código nativo de PC, feita com o [**PS2Recomp**](https://github.com/ran-j/PS2Recomp).

Isto **não é um emulador** e **não é um remaster**. O código MIPS do jogo (o ELF) é traduzido para C++ e compilado como programa nativo. O hardware que não é CPU (GS, VU, DMA, IOP, SPU2) continua emulado pelo runtime do PS2Recomp, com as nossas mudanças por cima.

> **Este repositório não contém dados do jogo.** Nenhum ISO, ELF, código gerado, gravação ou arquivo do jogo, e ele não ajuda a obtê-los. Você precisa da sua própria cópia.

## Estado

| Área | Estado |
|---|---|
| Recompilar o ELF (13.651 arquivos C++) e compilar o runtime | ✅ Feito |
| Boot, threads, leitura de disco (CRI ADXF / `GAMEDATA.WAD`) | ✅ Feito |
| Telas de save, menu principal, seleção de personagem | ✅ Feito |
| Primeira fase 3D (Goro's Lair) com HUD, pausa e mapa | ✅ Feito |
| Música e falas (ADX) | ✅ Funcionando |
| GS na GPU (Vulkan) | ✅ Renderizador novo por lotes em 2x por padrão (mipmap por pixel); o antigo, exato, fica em `PS2X_GS_HW=0` |
| VU1 numa thread própria, JIT x86-64 | ✅ Funcionando |
| Velocidade cheia (60 campos/s) | 🟡 Velocidade certa em tudo (sem câmera lenta); numa GTX 1050 a gameplay roda a ~55–60 quadros/s, e nas cenas pesadas o jogo pula quadros (`PLANO_DESEMPENHO.md`, N20) |
| Filmes CRI (FMV) | ✅ Abertura e os 8 filmes tocam; Start pula |
| Memory card (salvar e carregar) | ✅ Funcionando (arquivos em `extraido_full/mc0/`) |
| Som na gameplay | ✅ 48 kHz sem distorção; eco (reverb) do SPU2 aproximado (`PS2X_REVERB`) |
| Som dos filmes | ✅ Tocado direto dos arquivos `.SFD` (sem chiado) |
| Kung Lao como parceiro | ✅ Aparece (era invisível) |
| Resto das fases testadas do início ao fim | ❌ Falta |
| Build para Windows | 🟡 Compilado com MinGW-w64 a partir do Linux (`scripts/build_windows.sh`); roda no Wine (menus, Versus, RPG), ainda não testado num Windows de verdade |
| Chão, paredes e raios de luz no Goro's Lair | ✅ Como no original (o VIF agora anda na frente da VU1: o jogo manda as cores de cada lote logo depois de começá-lo) |
| Liu Kang girando parado (uma instrução MMI do R5900 lia o registrador errado) | ✅ Corrigido |
| Momentos pesados da cutscene (chegada do Raiden) | 🟡 Caem para ~35 quadros/s por alguns segundos, nos dois renderizadores (limite do EE/VU1, N20) |
| Lutadores | ✅ Os 8 liberados no Versus, e Sub-Zero e Scorpion na seleção da história (`MKSM_VERSUS_TODOS=0` volta às liberações originais); qualquer um deles (mais Kintaro, Shadow Priest e Orochi, experimentais, e Ermac e três personagens cortados, que andam mas não têm golpes) pode ser escolhido para um jogo novo de história ou Ko-op com **L2/R2** na tela de dificuldade; a compatibilidade na história ainda está em teste ([`PLANO_PERSONAGENS.md`](PLANO_PERSONAGENS.md)) |
| Tela cheia | ✅ F11 |
| Resolução interna maior | ✅ Renderizador novo em 2x por padrão, tão rápido quanto o antigo; `PS2X_GS_HW=0` volta ao antigo, `PS2X_SCALE=1..4` escolhe a escala |
| Menu de gráfico para PC fraco | ✅ R3 nos menus/pausa (ou F1): resolução interna, 16:9, FXAA, filtro, mistura de campos, renderizador; grava no `mksm.ini` |
| Widescreen | ✅ 16:9 no menu Gráfico ou `PS2X_WIDESCREEN=1` (o 3D ganha campo nas laterais; o 2D/HUD estica, como no PCSX2; filmes ficam 4:3) |
| Modo RPG (níveis e pontos de atributo) | 🟡 Implementado, Single Player e Ko-op (ver [Modo RPG](#modo-rpg-opcional)); equilíbrio ainda em teste |

Estado detalhado: [`ESTADO.md`](ESTADO.md). Plano de desempenho com medições: [`PLANO_DESEMPENHO.md`](PLANO_DESEMPENHO.md).

## O que você precisa

- Sua própria cópia do jogo (PS2, USA, `SLUS-210.87`).
- Linux (testado no Arch/CachyOS com GCC). O build para Windows é feito a partir do Linux com MinGW-w64 (`scripts/build_windows.sh`); compilar direto no Windows ainda não foi testado.
- `git`, `cmake`, `ninja`, `7z`, `g++`, `glslc` (Vulkan SDK / shaderc), `libvulkan`.
- GPU com Vulkan. Opcional, mas bem mais rápido: `VK_EXT_fragment_shader_interlock` (NVIDIA desde a Maxwell, AMD/Intel recentes). Sem Vulkan, o renderizador da CPU é usado.
- ~5 GB de RAM por job de compilação e algumas horas na primeira compilação (o código gerado é enorme).

> **Não há executável pronto para baixar, e não vai haver.** O executável contém o código do jogo traduzido, então distribuí-lo seria distribuir o jogo. Cada pessoa compila a partir da própria cópia com o script abaixo.

## Compilar e rodar

Um comando extrai a ISO, baixa o PS2Recomp no commit fixado, aplica os nossos patches, recompila o ELF e compila tudo:

```bash
scripts/instalar.sh "caminho/da/sua.iso"
```

Use `JOBS=1` se faltar memória. Se parar no meio, rode de novo: as etapas prontas são puladas.

Para jogar:

```bash
scripts/jogar.sh
```

Ele lê configurações opcionais do `mksm.ini` na raiz do projeto (uma `VARIAVEL=valor` por linha; a lista está no começo do [`scripts/jogar.sh`](scripts/jogar.sh)). Teclas: **F11** tela cheia, **F10** captura de tela (`capturas/`), **F9** grava a cena atual para relatar defeito (`gsrec/`; são dados do jogo, não publique). **Menu Gráfico:** **R3** no controle nos menus, na pausa do Select e no mapa, ou **F1** a qualquer hora (resolução interna, 16:9, FXAA, filtro de ampliação, mistura de campos, renderizador; grava no `mksm.ini`). **F12** abre o painel de depuração.

**Pastas portáteis:** depois do build, `scripts/empacotar_linux.sh` monta `portatil/MKSM-linux` (roda em outro Linux sem instalar nada) e `scripts/build_windows.sh` monta `portatil/MKSM-windows` (dois cliques no `Jogar.bat`). Elas levam os arquivos do seu jogo: são só para você.

**Notebook com duas placas de vídeo:** sem isso a janela pode abrir na placa integrada. Rode com `prime-run` na frente (ou `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia`).

**Controle:** um controle comum (USB/Bluetooth) funciona; o analógico tem zona morta de 25% (`PS2X_DEADZONE` no `mksm.ini`). Cada jogador remapeia os próprios botões na aba **Controles**: o jogador 1 com F1/R3, o jogador 2 apertando o **R3 do segundo controle** (útil para controles genéricos, que mapeiam os botões diferente; fica como `PS2X_PAD2_*`). No segundo controle, o **direcional para cima** liga e desliga a defesa contínua (como segurar L2), para uma pessoa jogar o Ko-op com um controle só.

Variáveis de ambiente úteis (todas no [`ARQUITETURA.md`](ARQUITETURA.md) §6):

| Variável | Efeito |
|---|---|
| `MKSM_SKIP_INTRO=1` | Pula os vídeos de abertura |
| `PS2X_VOL_MASTER`, `PS2X_VOL_MUSIC`, `PS2X_VOL_SFX` | Volumes, de 0 a 100 |
| `PS2X_REVERB=22` | Eco nos efeitos sonoros (0 desliga) |
| `PS2X_FXAA=0` | Sem suavização de bordas (ligada por padrão) |
| `PS2X_GS_HW=0` | Renderizador antigo (resolução do PS2, exato) no lugar do novo |
| `PS2X_SCALE=1` | Resolução interna do renderizador novo, 1 a 4 (padrão 2; 1 para placa fraca) |
| `PS2X_WIDESCREEN=1` | Tela 16:9 (3D mais largo; o 2D/HUD estica; filmes ficam 4:3) |
| `PS2X_RUMBLE=0` | Sem vibração no controle |
| `PS2X_DEINTERLACE=0` | Mostra um campo por vez, sem misturar os dois (imagem mais dura) |
| `PS2X_UNCAPPED=1` | Sem trava de tempo real (medir vazão; o jogo acelera) |
| `PS2X_PERF=1` | Mostra fps, carga do GS e da GPU e para onde vai o tempo de cada quadro, a cada 2 s |
| `PS2X_PIN=0` | Não fixa as quatro threads pesadas em núcleos físicos separados |
| `PS2X_GS_GPU=0` | Com `PS2X_GS_HW=0`: o renderizador antigo só na CPU |
| `PS2X_GS_RASTER=0` | Tiles em compute na GPU em vez do rasterizador |
| `PS2X_VU1_THREAD=0` | VU1 na thread do jogo |

## Outros lutadores

- **Liberados:** os 8 lutadores do Versus (Liu Kang, Kung Lao, Sub-Zero, Scorpion, Baraka, Reptile, Kitana, Johnny Cage), e Sub-Zero e Scorpion na seleção da história (o jogo normalmente os libera depois de zerar com cada monge). `MKSM_VERSUS_TODOS=0` no `mksm.ini` volta às liberações originais.
- **História e Ko-op com outro lutador:** num **jogo novo**, na tela *Select Difficulty*, cada jogador aperta **L2/R2** no próprio controle (**Shift esquerdo/direito** no teclado, jogador 1) para escolher qualquer lutador da lista abaixo. A escolha fica no save e não muda depois, para os golpes comprados nunca se misturarem entre personagens. Na história, os especiais são **R1 + um botão**.

| Lutador | Golpes | Especiais | Situação |
|---|---|---|---|
| Liu Kang, Kung Lao, Sub-Zero, Scorpion | sim | sim | Confirmados jogando |
| Johnny Cage | sim | sim (bola verde, chute de sombra) | A lista de golpes do jogo mostra nomes genéricos |
| Reptile, Baraka, Kitana | sim | não testados um a um | Devem se comportar como o Johnny Cage |
| Kintaro, Shadow Priest, Orochi | sim (próprios) | — | Experimentais: grandes, câmera e colisão estranhas; sem defesa de verdade (com L2 levam 20% do dano, mas o jogo não conta como defesa: trechos que pedem defender não avançam) |
| Ermac e os personagens cortados Armor Lion, homem de terno e Shiva | **não** | — | Só para ver: carregam e andam, mas não têm golpes de jogador (homem de terno e Shiva sem animação) |

- **Ainda não é perfeito:** os lutadores do Versus foram feitos para luta 1 contra 1. A loja de golpes, as fatalities da história e as cutscenes (que continuam mostrando os monges) podem não casar. Dar ao Ermac e aos cortados os golpes de outro lutador exige misturar os pacotes de dados de dois personagens, o que ainda não foi descoberto. Situação, números dos personagens e a fórmula de dano do jogo: [`PLANO_PERSONAGENS.md`](PLANO_PERSONAGENS.md).
- **Teste:** a pasta portátil do Windows traz o `TESTAR.txt`, um roteiro passo a passo (RPG, lutadores, Ko-op, Versus, saves).

## Modo RPG (opcional)

Um modo opcional, escolhido só ao começar um jogo novo, em que a experiência dá **níveis** e cada nível dá um **ponto de atributo**. A economia do jogo não muda: os inimigos dão o mesmo XP e os golpes custam o mesmo.

- **Ligar:** Single Player ou Ko-op → personagem → na *Select Difficulty*, cursor no **Hard** e aperte **L3** (**F2** no teclado). Aparece "RPG" dourado ao lado do Hard. O RPG é sempre no Hard, com inimigos mais fortes no começo (+30% de dano e +30% de vida): o começo é mais duro que o Hard e vai ficando mais fácil conforme você evolui.
- **Níveis:** o nível sai de todo o XP ganho (comprar golpe não tira nível). Do 1 para o 2 custa 300 de XP, depois 400, 550, 750... até o nível 100. O nível e o progresso (`Nv 3 · 120/550`) aparecem acima do "EXP"; no Ko-op, um para cada jogador.
- **Atributos** (1 ponto por nível, até 20 em cada por enquanto): Força (+5% de dano causado), Defesa (−3% de dano recebido), Vida (+5% de vida máxima), Roubo de vida (cura 1% do dano causado), Regeneração (0,1% da vida máxima por segundo), Sabedoria (+3% de XP para o nível). A velocidade nunca muda: golpes, combos e colisões ficam os originais.
- **Distribuir:** pausa (Select) → **R3** (ou **F1**) → aba **RPG** (L1/R1 trocam de aba). X gasta um ponto; "Redistribuir pontos" (X duas vezes) devolve todos. No Ko-op, cada jogador vê só o próprio nível e pontos: o jogador 2 abre a janela com o R3 do segundo controle.
- **Saves:** um save feito no modo RPG continua RPG. Na tela *Load Game* ele aparece com a tag "RPG · Nv N". Os dados do RPG ficam ao lado do `mksm.ini`, em `rpg_mc0_slot<n>.ini` (um por slot); o save do memory card não muda e abre sem o modo. No backup, copie esses arquivos junto com o `mc0/`.
- **Ajustes:** todos os números (curva de XP, efeito por ponto, tetos, força dos inimigos) são chaves `RPG_*` do `mksm.ini` (lista no começo do [`scripts/jogar.sh`](scripts/jogar.sh)). Com o modo desligado, o jogo roda igual ao original.
- Desenho, endereços e o que já foi testado: [`PLANO_RPG.md`](PLANO_RPG.md).

## Como o repositório é organizado

O PS2Recomp **não é copiado para cá**. O `scripts/aplicar_patches.sh` clona-o no commit de [`patches/UPSTREAM_COMMIT`](patches/UPSTREAM_COMMIT) e aplica o [`patches/runtime_atual.diff`](patches/runtime_atual.diff) mais os arquivos novos listados em [`patches/arquivos.txt`](patches/arquivos.txt). A pasta `PS2Recomp/` resultante é ignorada pelo git: você trabalha nela e roda `scripts/atualizar_patches.sh` para trazer as mudanças de volta para `patches/`.

| Caminho | O que é |
|---|---|
| `sm.toml` | Configuração do PS2Recomp para este jogo (stubs, overrides, laços ociosos) |
| `patches/` | Nossas mudanças no runtime, IOP, recompilador e testes do PS2Recomp |
| `scripts/` | Compilação, patches e testes |
| [`ARQUITETURA.md`](ARQUITETURA.md) | Arquitetura: threads, locks, o caminho de um quadro, tempo, armadilhas do jogo, testes sem bootar o jogo. **Comece por aqui.** |
| [`PLANO_DESEMPENHO.md`](PLANO_DESEMPENHO.md) | O plano ativo: desempenho, imagem, tarefas em aberto, medições |
| [`PLANO_RPG.md`](PLANO_RPG.md) | O modo RPG opcional: desenho, endereços do jogo, o que foi testado |
| [`PLANO_PERSONAGENS.md`](PLANO_PERSONAGENS.md) | Lutadores extras: liberação, números dos personagens, fórmula de dano, o que funciona na história |
| [`PLANO.md`](PLANO.md) | Histórico: o diário de investigação até 13/11, com a evidência de cada correção |
| [`MODDING.md`](MODDING.md) | Endereços e formatos do jogo (level select, dados das fases, bloom...) |
| [`ESTADO.md`](ESTADO.md) | Estado técnico e passo a passo manual |
| `notas/` | Notas de investigação |

## Contribuir

Veja o [`CONTRIBUTING.md`](CONTRIBUTING.md). Em resumo: nunca envie dados do jogo, mantenha o renderizador bit a bit exato (há testes de replay para isso) e mantenha a documentação em dia com o código.

## Licença

[GPL-3.0](LICENSE), a mesma do PS2Recomp, de onde `patches/` deriva.

## Créditos

- [PS2Recomp](https://github.com/ran-j/PS2Recomp), de ran-j e colaboradores: o recompilador e o runtime sobre os quais este projeto é feito.
- *Mortal Kombat: Shaolin Monks* © Midway / Warner Bros. Interactive Entertainment. Projeto de fãs, sem fins lucrativos e sem afiliação com os detentores dos direitos.
