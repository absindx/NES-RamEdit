@echo off
set OutputName=RamEdit
set Emulator=..\Mesen\Mesen.exe

rem Force update
if "%1"=="" goto Assemble
	del "%OutputName%.nes"
	start %Emulator% "%OutputName%"

:Assemble
nesasm -s -f Main.asm > build.log
type build.log

move Main.nes "%OutputName%.nes" > NUL 2>&1
move Main.fns "%OutputName%.fns" > NUL 2>&1

if "%1"=="" goto Return
	start %Emulator% "%OutputName%.nes"

:Return
