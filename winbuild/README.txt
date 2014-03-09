Tools needed
------------
1. Visual Studio Express - found at http://www.visualstudio.com/en-US/products/visual-studio-express-vs
2. Windows SDK - can be downloaded from microsoft.com


Installing dependencies
-----------------------

1. PThreads
-----------
- go to ftp://sourceware.org/pub/pthreads-win32 and download latest source code release
- extract to some folder
x86 version:
	- open Visual Studio Command Prompt (x86)
	- go to pthreads.2 folder and execute:
		nmake clean VC-static
	- copy newly created pthreadVC2.lib to winbuild\dist\lib\x86\ folder
x64 version:
	- go to pthreads.2 folder and execute:
		nmake clean VC-static
	- copy newly created pthreadVC2.lib to winbuild\dist\lib\x64\ folder

2. Install AMD APP SDK (OpenCL), latest version
-----------------------------------------------
- go to http://developer.amd.com/tools-and-sdks/heterogeneous-computing/amd-accelerated-parallel-processing-app-sdk/downloads/ and download appropriate version (x86/x64) and install
- copy C:\Program Files (x86)\AMD APP SDK\2.9\lib\x86\OpenCL.lib to winbuild/dist/lib/x86/
- copy C:\Program Files (x86)\AMD APP SDK\2.9\bin\x86\OpenCL.dll to winbuild/dist/dll/x86/
- copy C:\Program Files (x86)\AMD APP SDK\2.9\lib\x86_64\OpenCL.lib to winbuild/dist/lib/x64/
- copy C:\Program Files (x86)\AMD APP SDK\2.9\bin\x86_64\OpenCL.dll to winbuild/dist/dll/x64/
- copy C:\Program Files (x86)\AMD APP SDK\2.9\include\* winbuild/dist/include/


3. PDCurses
-----------
- download source http://sourceforge.net/projects/pdcurses/files/pdcurses/3.4/pdcurs34.zip/download and extract it somewhere
- copy curses.h to winbuild\dist\include\
x86 version:
	- open Visual Studio Command Prompt (x86)
	- go to win32 folder
	- execute: nmake -f vcwin32.mak WIDE=1 UTF8=1 pdcurses.lib
	- copy newly created pdcurses.lib to winbuild\dist\lib\x86\ folder
x64 version:
- open Visual Studio Command Prompt (x64)
	- go to win32 folder
	- edit vcwin32.mak end change line:
		cvtres /MACHINE:IX86 /NOLOGO /OUT:pdcurses.obj pdcurses.res
		to
		cvtres /MACHINE:X64 /NOLOGO /OUT:pdcurses.obj pdcurses.res
	- execute: nmake -f vcwin32.mak WIDE=1 UTF8=1 pdcurses.lib
	- copy newly created pdcurses.lib to winbuild\dist\lib\x64\ folder


3. OpenSSL (needed for Curl)
----------------------------
- go to http://slproweb.com/products/Win32OpenSSL.html and download latest full installer x86 and/or x64 (not light version)
- install to default location (e.g C:\OpenSSL-Win32 or C:\OpenSSL-Win64) and select bin/ folder when asked
- install Visual C++ (x86/x64) Redistributables if needed

4. Curl
-------
- go to http://curl.haxx.se/download.html and download latest source and extract it somewhere
- replace original curl winbuild\MakefileBuild.vc with provided winbuild\MakefileBuild.vc (corrected paths and static library names for VC)

x86 version:
- open Visual Studio Command Prompt (x86)
	- go to winbuild folder and execute:
		nmake -f Makefile.vc mode=static VC=10 WITH_DEVEL=C:\OpenSSL-Win32 WITH_SSL=static ENABLE_SSPI=no ENABLE_IPV6=no ENABLE_IDN=no GEN_PDB=no DEBUG=no MACHINE=x86
	- copy builds\libcurl-vc10-x86-release-static-ssl-static-spnego\lib\libcurl_a.lib to winbuild\dist\lib\x86
	- copy builds\libcurl-vc10-x86-release-static-ssl-static-spnego\include\* winbuild\dist\include\

x64 version:
- open Visual Studio Command Prompt (x64)
	- go to winbuild folder and execute:
		nmake -f Makefile.vc mode=static VC=10 WITH_DEVEL=C:\OpenSSL-Win64 WITH_SSL=static ENABLE_SSPI=no ENABLE_IPV6=no ENABLE_IDN=no GEN_PDB=no DEBUG=no MACHINE=x64
	- copy builds\libcurl-vc10-x64-release-static-ssl-static-spnego\lib\libcurl_a.lib to winbuild\dist\lib\x64
	- copy builds\libcurl-vc10-x64-release-static-ssl-static-spnego\include\* winbuild\dist\include\
