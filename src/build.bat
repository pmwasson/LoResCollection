::---------------------------------------------------------------------------
:: Compile code
::   Assemble twice: 1 to generate listing, 2 to generate object
::---------------------------------------------------------------------------
cd ..\build

:: Lander
ca65 -I ..\src -t apple2 ..\src\lander.asm -l lander.dis || exit
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\lander.asm apple2.lib  -o lander.apple2 -C ..\src\start2000.cfg || exit

:: Escape
ca65 -I ..\src -t apple2 ..\src\escape.asm -l escape.dis || exit
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\escape.asm apple2.lib  -o escape.apple2 -C ..\src\start2000.cfg || exit

::---------------------------------------------------------------------------
:: Build disk
::---------------------------------------------------------------------------

:: Start with a blank prodos disk
copy ..\disk\template_prodos.dsk lores.dsk  || exit


java -jar C:\jar\AppleCommander.jar -as lores.dsk lander.system sys < lander.apple2  || exit
java -jar C:\jar\AppleCommander.jar -as lores.dsk escape.system sys < escape.apple2  || exit

:: Throw on basic
java -jar C:\jar\AppleCommander.jar -p   lores.dsk basic.system sys < ..\disk\BASIC.SYSTEM  || exit

:: Copy results out of the build directory
copy lores.dsk ..\disk || exit

::---------------------------------------------------------------------------
:: Test on emulator
::---------------------------------------------------------------------------

C:\AppleWin\Applewin.exe -no-printscreen-dlg -d1 lores.dsk

