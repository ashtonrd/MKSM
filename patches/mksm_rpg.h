#pragma once
// Modo RPG do Shaolin Monks (PLANO_RPG.md): o XP ganho dá níveis, cada nível um ponto para os atributos.
// Só os .cpp que usam incluem este header (nunca o ps2_runtime.h: recompilaria o código gerado).
#include <cstdint>
#include <string>

class PS2Runtime;

namespace mksm_rpg
{
    enum Attr { Forca, Defesa, Vida, Roubo, Regen, Sabedoria, AttrCount };

    struct Snapshot
    {
        bool active = false, coop = false; // o jogo carregado é RPG; no co-op cada jogador tem perfil
        int level = 1, maxLevel = 100, freePoints = 0, cap = 0, pointsPerLevel = 1;
        int64_t xpGained = 0, xpInLevel = 0, xpStep = 0; // progresso: xpInLevel / xpStep (0 no nível máximo)
        int points[AttrCount] = {};
    };

    void install(PS2Runtime &runtime); // game_overrides_mksm.cpp: troca as funções do jogo
    Snapshot snapshot(int player = 0); // 0 = jogador 1, 1 = jogador 2
    bool addPoint(int player, int attr); // false: sem ponto livre ou no teto
    void resetPoints(int player);
    const char *attrName(int attr);
    std::string attrEffect(int attr, int points); // "+15% de dano causado"
    int takeLevelUps(int player, int &newLevel); // níveis ganhos desde a última chamada (aviso na tela)

    // Tela de dificuldade de um jogo novo: L3 (F2) arma o RPG; vale se o jogo começar no Hard.
    bool difficultyScreen(const uint8_t *rdram, bool &cursorHard);
    bool armed();
    void setArmed(bool on);
    void setInStory(bool on); // janela: há uma partida de história/co-op carregada (fora dela, o RPG não aparece)
    // Lutador do jogo novo (-1 = o da seleção do jogo): vale só ao começar um jogo novo (save+0xCC / save+0xD0).
    int fighterPick(int player);
    void setFighterPick(int player, int id);

    // O save do MKSM é um arquivo por cartão com 9 slots; o perfil RPG fica em rpg_mc<cartão>_slot<n>.ini.
    constexpr int kSlots = 9;
    bool slotIsRpg(int port, int slot, int &level); // tag na tela de load
    bool loadScreen(const uint8_t *rdram);          // a tela "Load Game" (lista de 9 slots) está aberta
    void noteCardFile(int port, const std::string &path); // MemoryCard.cpp: o jogo leu o save (guarda uma cópia)
    void onCardWrite(int port, const std::string &path);  // MemoryCard.cpp: o jogo gravou o save

    bool selfTest(); // curva e multiplicadores (PLANO_RPG.md, B1)
}
