::---------------------------------------------------------------------------
:: Compile code
::   Assemble twice: 1 to generate listing, 2 to generate object
::---------------------------------------------------------------------------
cd ..\build

:: Game
ca65 -I ..\src -t apple2 ..\src\game.asm -l game.dis || exit
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\game.asm apple2.lib  -o game.apple2 -C ..\src\start2000.cfg || exit

::---------------------------------------------------------------------------
:: Build disk
::---------------------------------------------------------------------------

:: Start with a blank prodos disk
copy ..\disk\template_prodos.dsk lores.dsk  || exit

:: Game
:: java -jar C:\jar\AppleCommander.jar -p  lores.dsk game.system sys < C:\cc65\target\apple2\util\loader.system || exit
java -jar C:\jar\AppleCommander.jar -as lores.dsk game.system sys < game.apple2  || exit

:: Throw on basic
java -jar C:\jar\AppleCommander.jar -p   lores.dsk basic.system sys < ..\disk\BASIC.SYSTEM  || exit

:: Copy results out of the build directory
copy lores.dsk ..\disk || exit

::---------------------------------------------------------------------------
:: Test on emulator
::---------------------------------------------------------------------------

C:\AppleWin\Applewin.exe -no-printscreen-dlg -d1 lores.dsk

