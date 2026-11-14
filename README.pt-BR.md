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
| GS na GPU (Vulkan: compute + rasterizador exato com interlock por pixel) | ✅ Funcionando, bit a bit igual ao renderizador da CPU |
| VU1 numa thread própria, JIT x86-64 | ✅ Funcionando |
| Velocidade cheia na gameplay (60 campos/s) | ✅ 60 numa GTX 1050; nas cenas pesadas o jogo pula quadros em vez de ficar em câmera lenta |
| Filmes CRI (FMV) | ✅ Abertura e os 8 filmes tocam; Start pula |
| Memory card (salvar e carregar) | ✅ Funcionando (arquivos em `extraido_full/mc0/`) |
| Som na gameplay | ✅ 48 kHz sem distorção; eco (reverb) do SPU2 aproximado (`PS2X_REVERB`) |
| Som dos filmes | ✅ Tocado direto dos arquivos `.SFD` (sem chiado) |
| Kung Lao como parceiro | ✅ Aparece (era invisível) |
| Resto das fases testadas do início ao fim | ❌ Falta |
| Build para Windows | ❌ Não testado |
| Chão, paredes e raios de luz no Goro's Lair | ✅ Como no original (o VIF agora anda na frente da VU1: o jogo manda as cores de cada lote logo depois de começá-lo) |
| Liu Kang dá um mortal de 3 quadros a cada poucos segundos parado | ❌ Aberto ([`PLANO_DESEMPENHO.md`](PLANO_DESEMPENHO.md), N04b) |
| Momentos pesados da cutscene (chegada do Raiden) | 🟡 Caem para ~35 quadros/s por alguns segundos (N08/N09) |
| Tela cheia | ✅ F11 |
| Resolução interna maior, widescreen | 🟡 Renderizador experimental `PS2X_GS_HW=1 PS2X_SCALE=2` (mais lento); widescreen planejado |

Estado detalhado: [`ESTADO.md`](ESTADO.md). Plano de desempenho com medições: [`PLANO_DESEMPENHO.md`](PLANO_DESEMPENHO.md).

## O que você precisa

- Sua própria cópia do jogo (PS2, USA, `SLUS-210.87`).
- Linux (testado no Arch/CachyOS com GCC). O Windows/MSVC é o alvo principal do PS2Recomp, mas ainda não foi testado aqui.
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

Ele lê configurações opcionais do `mksm.ini` na raiz do projeto (uma `VARIAVEL=valor` por linha; a lista está no começo do [`scripts/jogar.sh`](scripts/jogar.sh)). Teclas: **F11** tela cheia, **F10** captura de tela (`capturas/`), **F9** grava a cena atual para relatar defeito (`gsrec/`; são dados do jogo, não publique).

**Notebook com duas placas de vídeo:** sem isso a janela pode abrir na placa integrada. Rode com `prime-run` na frente (ou `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia`).

**Controle:** um controle comum (USB/Bluetooth) funciona; o analógico tem zona morta de 25% (`PS2X_DEADZONE` no `mksm.ini`).

Variáveis de ambiente úteis (todas no [`ARQUITETURA.md`](ARQUITETURA.md) §6):

| Variável | Efeito |
|---|---|
| `MKSM_SKIP_INTRO=1` | Pula os vídeos de abertura |
| `PS2X_VOL_MASTER`, `PS2X_VOL_MUSIC`, `PS2X_VOL_SFX` | Volumes, de 0 a 100 |
| `PS2X_REVERB=22` | Eco nos efeitos sonoros (0 desliga) |
| `PS2X_FXAA=1` | Suaviza as bordas na janela |
| `PS2X_RUMBLE=0` | Sem vibração no controle |
| `PS2X_DEINTERLACE=0` | Mostra um campo por vez, sem misturar os dois (imagem mais dura) |
| `PS2X_UNCAPPED=1` | Sem trava de tempo real (medir vazão; o jogo acelera) |
| `PS2X_PERF=1` | Mostra fps e carga do GS e da GPU a cada 2 s |
| `PS2X_PIN=0` | Não fixa as quatro threads pesadas em núcleos físicos separados |
| `PS2X_GS_GPU=0` | Só o renderizador da CPU |
| `PS2X_GS_RASTER=0` | Tiles em compute na GPU em vez do rasterizador |
| `PS2X_VU1_THREAD=0` | VU1 na thread do jogo |

## Como o repositório é organizado

O PS2Recomp **não é copiado para cá**. O `scripts/aplicar_patches.sh` clona-o no commit de [`patches/UPSTREAM_COMMIT`](patches/UPSTREAM_COMMIT) e aplica o [`patches/runtime_atual.diff`](patches/runtime_atual.diff) mais os arquivos novos listados em [`patches/arquivos.txt`](patches/arquivos.txt). A pasta `PS2Recomp/` resultante é ignorada pelo git: você trabalha nela e roda `scripts/atualizar_patches.sh` para trazer as mudanças de volta para `patches/`.

| Caminho | O que é |
|---|---|
| `sm.toml` | Configuração do PS2Recomp para este jogo (stubs, overrides, laços ociosos) |
| `patches/` | Nossas mudanças no runtime, IOP, recompilador e testes do PS2Recomp |
| `scripts/` | Compilação, patches e testes |
| [`ARQUITETURA.md`](ARQUITETURA.md) | Arquitetura: threads, locks, o caminho de um quadro, tempo, armadilhas do jogo, testes sem bootar o jogo. **Comece por aqui.** |
| [`PLANO.md`](PLANO.md) | Diário de cada correção, com evidências |
| [`PLANO_DESEMPENHO.md`](PLANO_DESEMPENHO.md) | Plano de desempenho e medições |
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
