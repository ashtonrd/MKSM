@echo off
rem ShaolinMonks RPG, instalador do Windows: ponha a sua ISO em coloque_o_jogo_aqui e de dois cliques aqui.
rem Compila no proprio Windows com o kit que vem no zip (sem instalar nada, sem internet), monta portatil\MKSM-windows
rem e apaga o kit no fim. A primeira vez leva algumas horas.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\instalar_windows.ps1"
if errorlevel 1 (
  echo.
  echo Algo deu errado ^(veja as mensagens acima^). Rode o Instalar.bat de novo: as etapas prontas sao puladas.
  pause
  exit /b 1
)
pause
