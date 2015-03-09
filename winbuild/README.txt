Tools needed
------------
1. Windows 7 (if you are using Win 8 or above, you will need to use a VM Win 7)
2. Visual Studio C++ 2013 Express - found at http://www.visualstudio.com/en-us/downloads#d-2013-express
3. Windows 7.1 SDK - http://www.microsoft.com/en-us/download/details.aspx?id=8279

If you intend to build for native x64, then instead of using <Visual Studio Command Prompt>, you will need to use
Windows SDK 7.1 Command Prompt and run "setenv /x64 /Release" before starting to build anything.

Also, for x64, after you follow all the steps and you are ready to build. Go to "Project Properties -> VC++ Directories -> Library Directories" 
and add this folder to the library list: C:\Program Files\Microsoft SDKs\Windows\v7.1\Lib\x64

To run sgminer built using Visual Studios you will need to have Microsoft Visual C++ 2013 Redistributable Package (x86 or x64 depending on your sgminer version) installed. 

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
- go to http://developer.amd.com/tools-and-sdks/opencl-zone/amd-accelerated-parallel-processing-app-sdk/ and download appropriate version (x86/x64) and install
- copy C:\Program Files (x86)\AMD APP SDK\2.9\lib\x86\OpenCL.lib to winbuild/dist/lib/x86/
- copy C:\Program Files (x86)\AMD APP SDK\2.9\bin\x86\OpenCL.dll to winbuild/dist/dll/x86/
- copy C:\Program Files (x86)\AMD APP SDK\2.9\lib\x86_64\OpenCL.lib to winbuild/dist/lib/x64/
- copy C:\Program Files (x86)\AMD APP SDK\2.9\bin\x86_64\OpenCL.dll to winbuild/dist/dll/x64/
- copy C:\Program Files (x86)\AMD APP SDK\2.9\include\CL\* winbuild/dist/include/CL/


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
- go to http://curl.haxx.se/download.html and download latest source (>=7.39.0) and extract it somewhere
- replace original curl winbuild\MakefileBuild.vc with provided winbuild\MakefileBuild.vc (corrected paths and static library names for VC)

x86 version:
- open Visual Studio Command Prompt (x86)
	- go to winbuild folder and execute:
		nmake -f Makefile.vc mode=static VC=13 WITH_DEVEL=C:\OpenSSL-Win32 WITH_SSL=static ENABLE_SSPI=no ENABLE_IPV6=no ENABLE_IDN=no GEN_PDB=no DEBUG=no MACHINE=x86
	- copy builds\libcurl-vc13-x86-release-static-ssl-static-spnego\lib\libcurl_a.lib to winbuild\dist\lib\x86
	- copy builds	\libcurl-vc13-x86-release-static-ssl-static-spnego\include\* winbuild\dist\include\

x64 version:
- open Visual Studio Command Prompt (x64)
	- go to winbuild folder and execute:
		nmake -f Makefile.vc mode=static VC=13 WITH_DEVEL=C:\OpenSSL-Win64 WITH_SSL=static ENABLE_SSPI=no ENABLE_IPV6=no ENABLE_IDN=no GEN_PDB=no DEBUG=no MACHINE=x64
	- copy builds\libcurl-vc13-x64-release-static-ssl-static-spnego\lib\libcurl_a.lib to winbuild\dist\lib\x64
	- copy builds\libcurl-vc13-x64-release-static-ssl-static-spnego\include\* winbuild\dist\include\

5. Jansson
----------
If using git run commands below from sgminer/ folder:

  git submodule init
  git submodule update
  
or clone/extract Jansson source from https://github.com/akheron/jansson to submodules/jansson folder.
