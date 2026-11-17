@echo off
rem ShaolinMonks RPG, instalador do Windows: ponha a sua ISO em coloque_o_jogo_aqui e de dois cliques aqui.
rem Compila dentro do WSL (Ubuntu) e entrega portatil\MKSM-windows, que roda nativo no Windows (Jogar.bat).
setlocal
cd /d "%~dp0"
set "TEMISO="
for %%f in ("coloque_o_jogo_aqui\*.iso") do set "TEMISO=1"
if not defined TEMISO (
  echo Coloque a ISO do seu jogo ^(PS2, USA, SLUS-210.87^) na pasta coloque_o_jogo_aqui e rode de novo.
  pause
  exit /b 1
)

wsl -d Ubuntu -- true >nul 2>&1
if errorlevel 1 (
  echo O WSL com Ubuntu ainda nao esta instalado. Vou instalar agora ^(pede permissao de administrador^).
  echo Depois: reinicie o PC, abra o Ubuntu uma vez pelo menu Iniciar para criar usuario e senha,
  echo e de dois cliques no Instalar.bat de novo.
  powershell -NoProfile -Command "Start-Process wsl -ArgumentList '--install','-d','Ubuntu' -Verb RunAs -Wait"
  pause
  exit /b 1
)

echo Compilando dentro do WSL. A primeira vez leva algumas horas; pode deixar rodando.
wsl -d Ubuntu --cd "%~dp0." -- bash -c "bash scripts/instalar_wsl.sh \"$PWD\""
if errorlevel 1 (
  echo.
  echo Algo deu errado ^(veja as mensagens acima^). Rode o Instalar.bat de novo: as etapas prontas sao puladas.
  pause
  exit /b 1
)
echo.
echo Pronto! Abra a pasta portatil\MKSM-windows e de dois cliques em Jogar.bat.
pause
