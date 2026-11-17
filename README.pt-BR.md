# ShaolinMonks RPG

*Mortal Kombat: Shaolin Monks* (PS2) recompilado para PC, com modo RPG e lutadores extras.

[English](README.md) · **Português (Brasil)**

O **ShaolinMonks RPG** é uma **recompilação estática** do *Mortal Kombat: Shaolin Monks* de **PlayStation 2** (USA, `SLUS-210.87`) para código nativo de PC, feita com o [**PS2Recomp**](https://github.com/ran-j/PS2Recomp).

Isto **não é um emulador** e **não é um remaster**. O código MIPS do jogo (o ELF) é traduzido para C++ e compilado como programa nativo. O hardware que não é CPU (GS, VU, DMA, IOP, SPU2) continua emulado pelo runtime do PS2Recomp, com as nossas mudanças por cima.

> **Este repositório não contém dados do jogo.** Nenhum ISO, ELF, código gerado, gravação ou arquivo do jogo, e ele não ajuda a obtê-los. Você precisa da sua própria cópia.

## O que o ShaolinMonks RPG traz

- **Modo RPG opcional:** o XP dá níveis e cada nível dá um ponto de atributo (Força, Defesa, Vida, Roubo de vida, Regeneração, Sabedoria). No Ko-op, cada jogador tem o próprio nível. O nível e a barra de XP aparecem no HUD, no estilo do jogo. [Detalhes](#modo-rpg-opcional).
- **67 lutadores na história e no Ko-op:** além dos monges e do Versus, Shao Kahn, Goro, Kano, Shang Tsung, Kintaro, Mileena, Jade, Jax, as versões Boss do Versus, inimigos da história e personagens cortados. Escolha com L2/R2 na tela de dificuldade de um jogo novo. [Detalhes](#outros-lutadores).
- **Todos os lutadores do Versus liberados**, e Sub-Zero e Scorpion já na seleção da história.
- **Ko-op com dois controles:** cada jogador remapeia os próprios botões (R3 no próprio controle), e o direcional para cima do controle 2 liga a defesa contínua.
- **Gráfico de PC:** resolução interna até 4x, tela 16:9, FXAA, tela cheia e um menu com predefinições para PC fraco.
- **Janela própria:** título "Mortal Kombat Shaolin Monks RPG" e o dragão do ícone do save do jogo.
- **Linux e Windows**, com pastas portáteis para levar a outro computador.

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
| Velocidade cheia (60 campos/s) | 🟡 Velocidade certa em tudo (sem câmera lenta); numa GTX 1050 a gameplay roda a ~55–60 quadros/s, e nas cenas pesadas o jogo pula quadros (`PLANO_DESEMPENHO.md`, N20; próximos passos na N22) |
| Filmes CRI (FMV) | ✅ Abertura e os 8 filmes tocam; Start pula |
| Memory card (salvar e carregar) | ✅ Funcionando (arquivos em `extraido_full/mc0/`) |
| Som na gameplay | ✅ 48 kHz sem distorção; eco (reverb) do SPU2 aproximado (`PS2X_REVERB`) |
| Som dos filmes | ✅ Tocado direto dos arquivos `.SFD` (sem chiado) |
| Kung Lao como parceiro | ✅ Aparece (era invisível) |
| Resto das fases testadas do início ao fim | ❌ Falta |
| Build para Windows | 🟡 Compilado com MinGW-w64 a partir do Linux (`scripts/build_windows.sh`); já jogado num Windows de verdade, com pequenos engasgos (plano N22 no [`PLANO_DESEMPENHO.md`](PLANO_DESEMPENHO.md)) |
| Chão, paredes e raios de luz no Goro's Lair | ✅ Como no original (o VIF agora anda na frente da VU1: o jogo manda as cores de cada lote logo depois de começá-lo) |
| Liu Kang girando parado (uma instrução MMI do R5900 lia o registrador errado) | ✅ Corrigido |
| Momentos pesados da cutscene (chegada do Raiden) | 🟡 Caem para ~35 quadros/s por alguns segundos, nos dois renderizadores (limite do EE/VU1, N20) |
| Lutadores | ✅ Os 8 liberados no Versus, e Sub-Zero e Scorpion na seleção da história (`MKSM_VERSUS_TODOS=0` volta às liberações originais); 67 lutadores (Versus, chefes como Shao Kahn, Goro e Shang Tsung, inimigos e personagens cortados) podem ser escolhidos para um jogo novo de história ou Ko-op com **L2/R2** na tela de dificuldade; a compatibilidade na história ainda está em teste ([`PLANO_PERSONAGENS.md`](PLANO_PERSONAGENS.md)) |
| Tela cheia | ✅ F11 |
| Janela | ✅ Título "Mortal Kombat Shaolin Monks RPG" e o dragão do ícone do save do jogo como ícone |
| Ko-op com dois controles | ✅ Cada jogador remapeia os próprios botões (R3 no próprio controle); defesa contínua no direcional para cima do controle 2 |
| Resolução interna maior | ✅ Renderizador novo em 2x por padrão, tão rápido quanto o antigo; `PS2X_GS_HW=0` volta ao antigo, `PS2X_SCALE=1..4` escolhe a escala |
| Menu de gráfico para PC fraco | ✅ R3 nos menus/pausa (ou F1): resolução interna, 16:9, FXAA, filtro, mistura de campos, renderizador; grava no `mksm.ini` |
| Widescreen | ✅ 16:9 no menu Gráfico ou `PS2X_WIDESCREEN=1` (o 3D ganha campo nas laterais; o 2D/HUD estica, como no PCSX2; filmes ficam 4:3) |
| Modo RPG (níveis e pontos de atributo) | 🟡 Implementado, Single Player e Ko-op, com nível e barra de XP no HUD no estilo do jogo (ver [Modo RPG](#modo-rpg-opcional)); equilíbrio ainda em teste |

Estado detalhado: [`ESTADO.md`](ESTADO.md). Plano de desempenho com medições: [`PLANO_DESEMPENHO.md`](PLANO_DESEMPENHO.md).

## O que você precisa

- Sua própria cópia do jogo (PS2, USA, `SLUS-210.87`).
- Linux (testado no Arch/CachyOS com GCC). O build para Windows é feito a partir do Linux com MinGW-w64 (`scripts/build_windows.sh`); compilar direto no Windows ainda não foi testado.
- `git`, `cmake`, `ninja`, `7z`, `g++`, `glslc` (Vulkan SDK / shaderc), `libvulkan`.
- GPU com Vulkan. Opcional, mas bem mais rápido: `VK_EXT_fragment_shader_interlock` (NVIDIA desde a Maxwell, AMD/Intel recentes). Sem Vulkan, o renderizador da CPU é usado.
- ~5 GB de RAM por job de compilação e algumas horas na primeira compilação (o código gerado é enorme).

> **Não há executável pronto para baixar, e não vai haver.** O executável contém o código do jogo traduzido, então distribuí-lo seria distribuir o jogo. Cada pessoa compila a partir da própria cópia com o script abaixo.

## Compilar e rodar

**Do jeito mais simples:**

1. Baixe o repositório (botão *Code → Download ZIP* no GitHub, ou `git clone`) e descompacte.
2. Ponha a ISO do seu jogo (PS2, USA, `SLUS-210.87`) na pasta `coloque_o_jogo_aqui`.
3. Dê dois cliques no instalador:
   - **Linux:** `Instalar.sh`. Ele instala o que faltar (pede a senha uma vez), compila e monta `portatil/MKSM-linux`.
   - **Windows:** `Instalar.bat`. Na primeira vez ele instala o WSL com Ubuntu (pede administrador; reinicie, abra o Ubuntu uma vez para criar usuário e senha e rode o `Instalar.bat` de novo). Depois compila dentro do WSL e entrega `portatil\MKSM-windows`, que roda **nativo** no Windows. O WSL só é usado para compilar.
4. Jogue: dois cliques em `jogar.sh` (Linux) ou `Jogar.bat` (Windows) dentro da pasta `portatil`.

A primeira compilação leva algumas horas. Se parar no meio, rode o instalador de novo: as etapas prontas são puladas. A pasta `portatil` leva o seu jogo: é só para você.

**Passo a passo manual** (o que os instaladores fazem por baixo):

Um comando extrai a ISO, baixa o PS2Recomp no commit fixado, aplica os nossos patches, recompila o ELF e compila tudo:

```bash
scripts/instalar.sh "caminho/da/sua.iso"
```

Use `JOBS=1` se faltar memória. Se parar no meio, rode de novo: as etapas prontas são puladas.

Opcional, no Linux: `scripts/pgo_runtime.sh` treina o runtime com o seu jogo (~15 min, abre a janela sozinho) e recompila com o perfil. A imagem fica idêntica, e a VU1 e o desenho ficam ~10% mais leves.

Para jogar:

```bash
scripts/jogar.sh
```

A janela se chama "Mortal Kombat Shaolin Monks RPG" e usa como ícone o dragão do ícone do save do jogo (`mc0/BASLUS-21087/game.icn`, criado no primeiro save; sem ele, fica o ícone padrão). Ele lê configurações opcionais do `mksm.ini` na raiz do projeto (uma `VARIAVEL=valor` por linha; a lista está no começo do [`scripts/jogar.sh`](scripts/jogar.sh)). Teclas: **F11** tela cheia, **F10** captura de tela (`capturas/`), **F9** grava a cena atual para relatar defeito (`gsrec/`; são dados do jogo, não publique). **Menu Gráfico:** **R3** no controle nos menus, na pausa do Select e no mapa, ou **F1** a qualquer hora (resolução interna, 16:9, FXAA, filtro de ampliação, mistura de campos, renderizador; grava no `mksm.ini`). **F12** abre o painel de depuração.

**Pastas portáteis:** depois do build, `scripts/empacotar_linux.sh` monta `portatil/MKSM-linux` (roda em outro Linux sem instalar nada) e `scripts/build_windows.sh` monta `portatil/MKSM-windows` (dois cliques no `Jogar.bat`). Elas levam os arquivos do seu jogo: são só para você.

**Notebook com duas placas de vídeo:** sem isso a janela pode abrir na placa integrada. Rode com `prime-run` na frente (ou `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia`).

**Controle:** um controle comum (USB/Bluetooth) funciona; o analógico tem zona morta de 25% (`PS2X_DEADZONE` no `mksm.ini`). Cada jogador remapeia os próprios botões na aba **Controles**: o jogador 1 com F1/R3, o jogador 2 apertando o **R3 do segundo controle** (útil para controles genéricos, que mapeiam os botões diferente; fica como `PS2X_PAD2_*`). No segundo controle, o **direcional para cima** liga e desliga a defesa contínua (como segurar L2), para uma pessoa jogar o Ko-op com um controle só.

Variáveis de ambiente úteis (todas no [`ARQUITETURA.md`](ARQUITETURA.md) §6):

| Variável | Efeito |
|---|---|
| `MKSM_SKIP_INTRO=1` | Pula os vídeos de abertura |
| `PS2X_VOL_MASTER`, `PS2X_VOL_MUSIC`, `PS2X_VOL_SFX` | Volumes, de 0 a 100 |
| `PS2X_REVERB=22` | Eco nos efeitos sonoros (0 desliga) |
| `PS2X_FXAA=1` | Suavização de bordas (ligada por padrão no Windows; no Linux vem desligada, que rende mais quadros) |
| `PS2X_GS_HW=0` | Renderizador antigo (resolução do PS2, exato) no lugar do novo |
| `PS2X_SCALE=1` | Resolução interna do renderizador novo, 1 a 4 (padrão 2; 1 para placa fraca) |
| `PS2X_WIDESCREEN=1` | Tela 16:9 (3D mais largo; o 2D/HUD estica; filmes ficam 4:3) |
| `PS2X_RUMBLE=0` | Sem vibração no controle |
| `PS2X_DEINTERLACE=1` | Mistura os dois campos (ligada por padrão no Windows; no Linux vem desligada, que alivia o processador) |
| `PS2X_VSYNC=1` | Sincronia vertical: a imagem troca junto com o monitor (contra engasgo com o jogo a 60; também no menu Gráfico) |
| `PS2X_UNCAPPED=1` | Sem trava de tempo real (medir vazão; o jogo acelera) |
| `PS2X_PERF=1` | Mostra fps, carga do GS e da GPU e para onde vai o tempo de cada quadro, a cada 2 s |
| `PS2X_PIN=0` | Não fixa as quatro threads pesadas em núcleos físicos separados (Linux e Windows) |
| `PS2X_GS_GPU=0` | Com `PS2X_GS_HW=0`: o renderizador antigo só na CPU |
| `PS2X_GS_RASTER=0` | Tiles em compute na GPU em vez do rasterizador |
| `PS2X_VU1_THREAD=0` | VU1 na thread do jogo |

## Outros lutadores

- **Liberados:** os 8 lutadores do Versus (Liu Kang, Kung Lao, Sub-Zero, Scorpion, Baraka, Reptile, Kitana, Johnny Cage), e Sub-Zero e Scorpion na seleção da história (o jogo normalmente os libera depois de zerar com cada monge). `MKSM_VERSUS_TODOS=0` no `mksm.ini` volta às liberações originais.
- **História e Ko-op com outro lutador:** num **jogo novo**, na tela *Select Difficulty*, cada jogador aperta **L2/R2** no próprio controle (**Shift esquerdo/direito** no teclado, jogador 1; segurado, passa sozinho) para escolher um dos 67 lutadores, na ordem da tabela abaixo. A escolha fica no save e não muda depois, para os golpes comprados nunca se misturarem entre personagens. Na história, os especiais são **R1 + um botão**.

| Grupo (na ordem da lista) | Lutadores | Situação |
|---|---|---|
| Monges e Versus | Liu Kang, Kung Lao, Sub-Zero, Scorpion, Kitana, Johnny Cage, Baraka, Reptile | Golpes, especiais e fatalities (são os únicos com animação de fatality nos dados do jogo) |
| Com especiais | Shao Kahn, Goro (dois), Kano, Shang Tsung, Inferno Scorpion, Ermac (o chefe), Kintaro (dois) | Golpes e especiais próprios; o Goro fica de braços abertos quando parado; o Shang Tsung não volta se sumir |
| Só golpes normais | Mileena, Jade, Jax, as versões de história do Versus (Scorpion Boss, Baraka Boss, Reptile Boss, Kitana Boss, Sub-Zero Boss, Johnny Cage Boss), Shadow Priest, Orochi Hellbeast, os inimigos da história (Mercs, Mask Guard, Oni Warlord, Demons, Tarkata, Corpses, Elemental Knight, Living Trees...) e alguns cortados (Shokan, Green Tarkata, Banshee) | Atacam, sem especial; Mileena e Jade se movem perfeitamente; os Corpses explodem e somem |
| Golpes, mas bugados | Oni (falha ao bater e correr), Female Ninja, Ninja Wraith, Chan Chan, Nagiri Swamp, Oni de Fogo, Oni de Chifre | Atacam, com animação quebrada |
| Sem golpes | Noob Saibot, Smoke, Raiden, Kabal, Sonya, o outro Shang Tsung, Ermac (do Versus), Burning Monk, Order of Light Monk, Armor Lion, homem de terno, Shiva | Só andam |

- **Ko-op: recomendado que um dos jogadores use um dos 4 clássicos** (Liu Kang, Kung Lao, Sub-Zero ou Scorpion). Alguns trechos da história pedem Brutality ou Multality, que só esses quatro fazem com certeza.
- **Todos fora do Versus e dos monges** não têm a defesa de jogador: com L2 segurado levam 20% do dano, mas o jogo não conta como defesa (trechos que pedem defender não avançam).
- **Fora da lista:** quem quebra a câmera, não fica de pé ou trava (bichos, árvores, chefes gigantes e alguns cortados). Ficam anotados no [`PLANO_PERSONAGENS.md`](PLANO_PERSONAGENS.md).

- **Ainda não é perfeito:** os lutadores do Versus foram feitos para luta 1 contra 1. A loja de golpes, as fatalities da história e as cutscenes (que continuam mostrando os monges) podem não casar. Dar golpes a quem não tem (e consertar a animação parada do Goro) exige misturar os pacotes de dados de dois personagens, o que ainda não foi descoberto. Situação, números dos personagens e a fórmula de dano do jogo: [`PLANO_PERSONAGENS.md`](PLANO_PERSONAGENS.md).
- **Teste:** a pasta portátil do Windows traz o `TESTAR.txt`, um roteiro passo a passo (RPG, lutadores, Ko-op, Versus, saves).

## Modo RPG (opcional)

Um modo opcional, escolhido só ao começar um jogo novo, em que a experiência dá **níveis** e cada nível dá um **ponto de atributo**. A economia do jogo não muda: os inimigos dão o mesmo XP e os golpes custam o mesmo.

- **Ligar:** Single Player ou Ko-op → personagem → na *Select Difficulty*, cursor no **Hard** e aperte **L3** (**F2** no teclado). Aparece "RPG" dourado ao lado do Hard. O RPG é sempre no Hard, com inimigos mais fortes no começo (+30% de dano e +30% de vida): o começo é mais duro que o Hard e vai ficando mais fácil conforme você evolui.
- **Níveis:** o nível sai de todo o XP ganho (comprar golpe não tira nível). Do 1 para o 2 custa 400 de XP, depois 500, 650, 850... (cada degrau custa +100 até o nível 10, +200 do 10 ao 29 e +300 do 30 em diante), até o nível 100. O nível, uma barra do XP até o próximo e o número (`120/550`) aparecem acima do "EXP", no estilo do HUD do jogo; um "+N" verde pisca quando há pontos para distribuir. No Ko-op, um para cada jogador.
- **Atributos** (1 ponto por nível, até 20 em cada e 5 na Sabedoria): Força (+5% de dano causado), Defesa (−3% de dano recebido), Vida (+5% de vida máxima), Roubo de vida (cura 1% do dano causado), Regeneração (0,1% da vida máxima por segundo), Sabedoria (+3% de XP para o nível). A velocidade nunca muda: golpes, combos e colisões ficam os originais.
- **Distribuir:** pausa (Select) → **R3** (ou **F1**) → aba **RPG** (L1/R1 trocam de aba). X gasta um ponto; "Redistribuir pontos" (X duas vezes) devolve todos. No Ko-op, cada jogador vê só o próprio nível e pontos: o jogador 2 abre a janela com o R3 do segundo controle.
- **Saves:** um save feito no modo RPG continua RPG. Na tela *Load Game* ele aparece com a tag "RPG · Nível N". Os dados do RPG ficam ao lado do `mksm.ini`, em `rpg_mc0_slot<n>.ini` (um por slot); o save do memory card não muda e abre sem o modo. No backup, copie esses arquivos junto com o `mc0/`.
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
