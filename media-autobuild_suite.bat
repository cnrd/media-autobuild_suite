::-------------------------------------------------------------------------------------
:: LICENSE -------------------------------------------------------------------------
::-------------------------------------------------------------------------------------
::  This Windows Batchscript is for setup a compiler environment for building ffmpeg and other media tools under Windows.
::
::    Copyright (C) 2013  jb_alvarado
::
::    This program is free software: you can redistribute it and/or modify
::    it under the terms of the GNU General Public License as published by
::    the Free Software Foundation, either version 3 of the License, or
::    (at your option) any later version.
::
::    This program is distributed in the hope that it will be useful,
::    but WITHOUT ANY WARRANTY; without even the implied warranty of
::    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
::    GNU General Public License for more details.
::
::    You should have received a copy of the GNU General Public License
::    along with this program.  If not, see <http://www.gnu.org/licenses/>.
::-------------------------------------------------------------------------------------
::-------------------------------------------------------------------------------------
::
::  This is version 3.3
::  See HISTORY file for more information
::
::-------------------------------------------------------------------------------------

@echo off
color 80
title media-autobuild_suite

setlocal
set instdir=%CD%
set "ini=build\media-autobuild_suite.ini"

if not exist %instdir% (
    echo -------------------------------------------------------------------------------
    echo. You have probably run the script in a path with spaces.
    echo. This is not supported.
    echo. Please move the script to use a path without spaces. Ex.:
    echo. Incorrect: C:\build suite\
    echo. Correct:   C:\build_suite\
    pause
    exit
    )

set build=%instdir%\build
if not exist %build% mkdir %build%

set msyspackages=asciidoc autoconf automake-wrapper autogen bison diffstat dos2unix help2man ^
intltool libtool patch python scons xmlto make zip unzip git subversion wget p7zip mercurial man-db ^
gperf winpty-git texinfo

set mingwpackages=cmake dlfcn doxygen libpng gcc nasm pcre tools-git yasm ninja pkg-config

set ffmpeg_options=--enable-gnutls --enable-frei0r --enable-libbluray --enable-libcaca ^
--enable-libass --enable-libgsm --enable-libilbc --enable-libmodplug --enable-libmp3lame ^
--enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger ^
--enable-libsoxr --enable-libtwolame --enable-libspeex --enable-libtheora --enable-libvorbis ^
--enable-libopus --enable-libvidstab --enable-libxavs --enable-libxvid --enable-libtesseract ^
--enable-libzvbi --enable-libdcadec --enable-libbs2b --enable-libmfx --enable-libcdio --enable-libfreetype ^
--enable-fontconfig --enable-libfribidi --enable-opengl --enable-libvpx --enable-libx264 --enable-libx265 ^
--enable-libkvazaar --enable-libwebp --enable-decklink --enable-libgme --enable-librubberband ^
--disable-w32threads --enable-opencl --enable-libzimg --enable-gmp ^
--enable-nonfree --enable-nvenc --enable-openssl

set iniOptions=msys2Arch arch license2 vpx x264 x265 other265 flac fdkaac mediainfo soxB ffmpegB ffmpegUpdate ^
ffmpegChoice mp4box rtmpdump mplayer mpv cores deleteSource strip pack xpcomp logging

set previousOptions=0
set msys2ArchINI=0

if exist %ini% GOTO checkINI
:selectmsys2Arch
    set deleteIni=1
    if %msys2ArchINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Select the msys2 system:
    echo. 1 = 32 bit msys2
    echo. 2 = 64 bit msys2 [recommended]
    echo.
    echo. Choose the same as your operating system.
    echo.
    echo. If you make a mistake, delete the media-autobuild_suite.ini file
    echo. and re-run this file.
    echo.
    echo. These questions should only be asked once.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P msys2Arch="msys2 system: " ) else set msys2Arch=%msys2ArchINI%
    if %msys2Arch% GTR 2 GOTO selectmsys2Arch

    echo.[compiler list]>%ini%
    echo.msys2Arch=^%msys2Arch%>>%ini%

    if %previousOptions%==0 for %%a in (%iniOptions%) do set %%aINI=0
    set msys2ArchINI=%msys2Arch%

    GOTO systemVars

:checkINI
set deleteIni=0
for %%a in (%iniOptions%) do (
    findstr %%a %ini% > nul
    if errorlevel 1 set deleteIni=1 && set %%aINI=0
    if errorlevel 0 for /F "tokens=2 delims==" %%b in ('findstr %%a %ini%') do (
        set %%aINI=%%b
        if %%b==0 set deleteIni=1
        )
    )
if %deleteINI%==1 (
    del %ini%
    set previousOptions=1
    GOTO selectmsys2Arch
    )

:systemVars
set msys2Arch=%msys2ArchINI%
if %msys2Arch%==1 set "msys2=msys32"
if %msys2Arch%==2 set "msys2=msys64"

:selectSystem
set "writeArch=no"
if %archINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Select the build target system:
    echo. 1 = both [32 bit and 64 bit]
    echo. 2 = 32 bit build system
    echo. 3 = 64 bit build system
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildEnv="Build System: "
    ) else set buildEnv=%archINI%
if %deleteINI%==1 set "writeArch=yes"

if %buildEnv%==1 (
    set "build32=yes"
    set "build64=yes"
    )
if %buildEnv%==2 (
    set "build32=yes"
    set "build64=no"
    )
if %buildEnv%==3 (
    set "build32=no"
    set "build64=yes"
    )
if %buildEnv% GTR 3 GOTO selectSystem
if %writeArch%==yes echo.arch=^%buildEnv%>>%ini%

:ffmpeglicense
set "writeLicense=no"
if %license2INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FFmpeg/rtmpdump with which license?
    echo. 1 = Non-free [unredistributable, but can include anything]
    echo. 2 = GPLv3 [disables OpenSSL and FDK-AAC]
    echo. 3 = GPLv2.1
    echo.   [Same disables as GPLv3 with addition of gmp, opencore codecs,
    echo.    vo-aacenc and NNEDI3 prescaler in mpv]
    echo. 4 = LGPLv3
    echo.   [Disables x264, x265, XviD, GPL filters, etc.
    echo.    but reenables OpenSSL/FDK-AAC]
    echo. 5 = LGPLv2.1 [same disables as LGPLv3 + GPLv2.1]
    echo.
    echo. If building for yourself, it's OK to choose non-free.
    echo. If building to redistribute online, choose GPL or LGPL.
    echo. If building to include in a GPLv2.1 binary, choose LGPLv2.1 or GPLv2.1.
    echo. If you want to use FFmpeg together with closed source software, choose LGPL
    echo. and follow instructions in https://www.ffmpeg.org/legal.html
    echo.
    echo. In the case of rtmpdump, since it's the binary is GPL, it will be compiled
    echo. with GnuTLS if LGPL is chosen, but if Non-free will use OpenSSL.
    echo. If not building rtmpdump, but just librtmp ^(which is LGPL^) to use in FFmpeg,
    echo. OpenSSL can be used.
    echo.
    echo. OpenSSL and FDK-AAC have licenses incompatible with GPL but compatible
    echo. with LGPL, so they won't be disabled automatically.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P ffmpegLicense="FFmpeg license: "
    ) else set ffmpegLicense=%license2INI%
if %deleteINI%==1 set "writeLicense=yes"

if %ffmpegLicense%==1 set "license2=nonfree"
if %ffmpegLicense%==2 set "license2=gplv3"
if %ffmpegLicense%==3 set "license2=gpl"
if %ffmpegLicense%==4 set "license2=lgplv3"
if %ffmpegLicense%==5 set "license2=lgpl"
if %ffmpegLicense% GTR 5 GOTO ffmpeglicense
if %writeLicense%==yes echo.license2=^%ffmpegLicense%>>%ini%

:vpx
set "writevpx=no"
if %vpxINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build vpx [VP8/VP9 encoder] binary?
    echo. 1 = Yes [static]
    echo. 2 = Build library only
    echo. 3 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildvpx="Build vpx: "
    ) else set buildvpx=%vpxINI%
if %deleteINI%==1 set "writevpx=yes"

if %buildvpx%==1 set "vpx=y"
if %buildvpx%==2 set "vpx=l"
if %buildvpx%==3 set "vpx=n"
if %buildvpx% GTR 3 GOTO vpx
if %writevpx%==yes echo.vpx=^%buildvpx%>>%ini%

:x264
set "writex264=no"
if %x264INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build x264 [H.264 encoder]?
    echo. 1 = 8 and 10-bit binaries and 8-bit library [static]
    echo. 2 = Build library only
    echo. 3 = No
    echo. 4 = 8 and 10-bit binaries with libavformat and library [static]
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildx264="Build x264: "
    ) else set buildx264=%x264INI%
if %deleteINI%==1 set "writex264=yes"

if %buildx264%==1 set "x264=y"
if %buildx264%==2 set "x264=l"
if %buildx264%==3 set "x264=n"
if %buildx264%==4 set "x264=f"
if %buildx264% GTR 4 GOTO x264
if %writex264%==yes echo.x264=^%buildx264%>>%ini%

:xpcomp
set "writexpcomp=no"
if %xpcompINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build libraries/binaries compatible with Windows XP when possible?
    echo. 1 = Yes
    echo. 2 = No [recommended]
    echo.
    echo. Examples: x265, disabled QuickSync and mpv, etc.
    echo. This usually causes worse performance in all systems.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildxpcomp="Build with XP compatibilty: "
    ) else set buildxpcomp=%xpcompINI%
if %deleteINI%==1 set "writexpcomp=yes"

if %buildxpcomp%==1 set "xpcomp=y"
if %buildxpcomp%==2 set "xpcomp=n"
if %buildxpcomp% GTR 2 GOTO xpcomp
if %writexpcomp%==yes echo.xpcomp=^%buildxpcomp%>>%ini%

:x265
set "writex265=no"
if %x265INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build x265 [H.265 encoder]?
    echo. 1 = Static x265.exe and library with Main, Main10 and Main12 included
    echo. 2 = Static library only with Main, Main10 and Main12 included
    echo. 3 = No
    echo. 4 = Static x265.exe and library [Main] with shared high bit-depth libraries
    echo. 5 = Static x265.exe and library [Main]
    echo. 6 = Static library only [Main]
    echo. 7 = Same as 1 with addition of non-XP compatible x265-numa.exe
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildx265="Build x265: "
    ) else set buildx265=%x265INI%
if %deleteINI%==1 set "writex265=yes"

if %buildx265%==1 set "x265=y"
if %buildx265%==2 set "x265=l"
if %buildx265%==3 set "x265=n"
if %buildx265%==4 set "x265=s"
if %buildx265%==5 set "x265=y8"
if %buildx265%==6 set "x265=l8"
if %buildx265%==7 set "x265=d"
if %buildx265% GTR 7 GOTO x265
if %writex265%==yes echo.x265=^%buildx265%>>%ini%

:other265
set "writeother265=no"
if %other265INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build H.265 encoders other than x265?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Included: kvazaar and f265
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildother265="Build other265: "
    ) else set buildother265=%other265INI%
if %deleteINI%==1 set "writeother265=yes"

if %buildother265%==1 set "other265=y"
if %buildother265%==2 set "other265=n"
if %buildother265% GTR 2 GOTO other265
if %writeother265%==yes echo.other265=^%buildother265%>>%ini%

:flac
set "writeflac=no"
if %flacINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FLAC? [Free Lossless Audio Codec]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildflac="Build flac: "
    ) else set buildflac=%flacINI%
if %deleteINI%==1 set "writeflac=yes"

if %buildflac%==1 set "flac=y"
if %buildflac%==2 set "flac=n"
if %buildflac% GTR 2 GOTO flac
if %writeflac%==yes echo.flac=^%buildflac%>>%ini%

:fdkaac
set "writefdkaac=no"
if %fdkaacINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FDK-AAC library and binary? [AAC-LC/HE/HEv2 codec]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Note FFmpeg's aac encoder is no longer experimental and considered equal or
    echo. better in quality from 96kbps and above. It still doesn't support AAC-HE/HEv2
    echo. so if you need that or want better quality at lower bitrates than 96kbps,
    echo. use FDK-AAC.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildfdkaac="Build fdkaac: "
    ) else set buildfdkaac=%fdkaacINI%
if %deleteINI%==1 set "writefdkaac=yes"

if %buildfdkaac%==1 set "fdkaac=y"
if %buildfdkaac%==2 set "fdkaac=n"
if %buildfdkaac% GTR 2 GOTO fdkaac
if %writefdkaac%==yes echo.fdkaac=^%buildfdkaac%>>%ini%

:mediainfo
set "writemediainfo=no"
if %mediainfoINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build mediainfo binaries [Multimedia file information tool]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildmediainfo="Build mediainfo: "
    ) else set buildmediainfo=%mediainfoINI%
if %deleteINI%==1 set "writemediainfo=yes"

if %buildmediainfo%==1 set "mediainfo=y"
if %buildmediainfo%==2 set "mediainfo=n"
if %buildmediainfo% GTR 2 GOTO mediainfo
if %writemediainfo%==yes echo.mediainfo=^%buildmediainfo%>>%ini%

:sox
set "writesox=no"
if %soxBINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build sox binaries [Sound processing tool]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildsox="Build sox: "
    ) else set buildsox=%soxBINI%
if %deleteINI%==1 set "writesox=yes"

if %buildsox%==1 set "sox=y"
if %buildsox%==2 set "sox=n"
if %buildsox% GTR 2 GOTO sox
if %writesox%==yes echo.soxB=^%buildsox%>>%ini%

:ffmpeg
set "writeFF=no"
if %ffmpegBINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FFmpeg binaries and libraries:
    echo. 1 = Yes [static] [recommended]
    echo. 2 = No
    echo. 3 = Shared
    echo. 4 = Both static and shared [shared goes to an isolated directory]
    echo.
    echo. Note: mpv needs FFmpeg static libraries.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpeg="Build FFmpeg: "
    ) else set buildffmpeg=%ffmpegBINI%
if %deleteINI%==1 set "writeFF=yes"

if %buildffmpeg%==1 set "ffmpeg=y"
if %buildffmpeg%==2 set "ffmpeg=n"
if %buildffmpeg%==3 set "ffmpeg=s"
if %buildffmpeg%==4 set "ffmpeg=b"
if %buildffmpeg% GTR 4 GOTO ffmpeg
if %writeFF%==yes echo.ffmpegB=^%buildffmpeg%>>%ini%

:ffmpegUp
set "writeFFU=no"
if %ffmpegUpdateINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Always build FFmpeg when libraries have been updated?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. FFmpeg is updated a lot so you only need to select this if you
    echo. absolutely need updated external libraries in FFmpeg.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpegUp="Build ffmpeg if lib is new: "
    ) else set buildffmpegUp=%ffmpegUpdateINI%
if %deleteINI%==1 set "writeFFU=yes"

if %buildffmpegUp%==1 set "ffmpegUpdate=y"
if %buildffmpegUp%==2 set "ffmpegUpdate=n"
if %buildffmpegUp% GTR 2 GOTO ffmpegUp
if %writeFFU%==yes echo.ffmpegUpdate=^%buildffmpegUp%>>%ini%

:ffmpegChoice
set "writeFFC=no"
if %ffmpegChoiceINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Choose ffmpeg optional libraries?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. If you select yes, we will create a file with the default options
    echo. we use with FFmpeg. You can remove any that you don't need.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpegChoice="Choose ffmpeg optional libs: "
    ) else set buildffmpegChoice=%ffmpegChoiceINI%
if %deleteINI%==1 set "writeFFC=yes"

if %buildffmpegChoice%==1 (
    set "ffmpegChoice=y"
    if not exist %build%\ffmpeg_options.txt (
        for %%i in (%ffmpeg_options%) do echo.%%i>>%build%\ffmpeg_options.txt
        echo -------------------------------------------------------------------------------
        echo. File with default options has been created in
        echo. %build%\ffmpeg_options.txt
        echo.
        echo. Edit it now or leave it unedited to compile according to defaults.
        echo -------------------------------------------------------------------------------
        pause
        )
    )
if %buildffmpegChoice%==2 set "ffmpegChoice=n"
if %writeFFC%==yes echo.ffmpegChoice=^%buildffmpegChoice%>>%ini%

:mp4boxStatic
set "writeMP4Box=no"
if %mp4boxINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static mp4box [mp4 muxer/toolbox] binary?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildMp4box="Build mp4box: "
    ) else set buildMp4box=%mp4boxINI%
if %deleteINI%==1 set "writeMP4Box=yes"

if %buildMp4box%==1 set "mp4box=y"
if %buildMp4box%==2 set "mp4box=n"
if %buildMp4box% GTR 2 GOTO mp4boxStatic
if %writeMP4Box%==yes echo.mp4box=^%buildMp4box%>>%ini%

:rtmpdump
set "writertmpdump=no"
if %rtmpdumpINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static rtmpdump binaries [rtmp tools]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildrtmpdump="Build rtmpdump: "
    ) else set buildrtmpdump=%rtmpdumpINI%
if %deleteINI%==1 set "writertmpdump=yes"

if %buildrtmpdump%==1 set "rtmpdump=y"
if %buildrtmpdump%==2 set "rtmpdump=n"
if %buildrtmpdump% GTR 2 GOTO rtmpdump
if %writertmpdump%==yes echo.rtmpdump=^%buildrtmpdump%>>%ini%

:mplayer
set "writeMPlayer=no"
if %mplayerINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static mplayer/mencoder binary?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildmplayer="Build mplayer: "
    ) else set buildmplayer=%mplayerINI%
if %deleteINI%==1 set "writeMPlayer=yes"

if %buildmplayer%==1 set "mplayer=y"
if %buildmplayer%==2 set "mplayer=n"
if %buildmplayer% GTR 2 GOTO mplayer
if %writeMPlayer%==yes echo.mplayer=^%buildmplayer%>>%ini%

:mpv
set "writeMPV=no"
if %mpvINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static mpv binary?
    echo. 1 = Yes
    echo. 2 = No
    echo. 3 = compile with Vapoursynth, if installed [see Warning]
    echo.
    echo. Note: Requires at least Windows Vista.
    echo. Warning: the third option isn't completely static. There's no way to include
    echo. a library dependant on Python statically. All users of the compiled binary
    echo. will need VapourSynth installed using the official package to even open mpv!
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildmpv="Build mpv: "
    ) else set buildmpv=%mpvINI%
if %deleteINI%==1 set "writeMPV=yes"

if %buildmpv%==1 set "mpv=y"
if %buildmpv%==2 set "mpv=n"
if %buildmpv%==3 set "mpv=v"
if %buildmpv% GTR 3 GOTO mpv
if %writeMPV%==yes echo.mpv=^%buildmpv%>>%ini%

:numCores
set "writeCores=no"
if %NUMBER_OF_PROCESSORS% GTR 1 set /a coreHalf=%NUMBER_OF_PROCESSORS%/2
if %coresINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Number of CPU Cores/Threads for compiling:
    echo. [it is non-recommended to use all cores/threads!]
    echo.
    echo. Recommended: %coreHalf%
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P cpuCores="Core/Thread Count: "
    ) else set cpuCores=%coresINI%
    for /l %%a in (1,1,%cpuCores%) do (
        set cpuCount=%%a
        )
if %deleteINI%==1 set "writeCores=yes"

if "%cpuCount%"=="" GOTO :numCores
if %writeCores%==yes echo.cores=^%cpuCount%>>%ini%

:delete
set "writeDel=no"
if %deleteSourceINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Delete versioned source folders after compile is done?
    echo. 1 = Yes [recommended]
    echo. 2 = No
    echo.
    echo. This will save a bit of space for libraries not compiled from git/hg/svn.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P deleteS="Delete source: "
    ) else set deleteS=%deleteSourceINI%
if %deleteINI%==1 set "writeDel=yes"

if %deleteS%==1 set "deleteSource=y"
if %deleteS%==2 set "deleteSource=n"
if %deleteS% GTR 2 GOTO delete
if %writeDel%==yes echo.deleteSource=^%deleteS%>>%ini%

:stripEXE
set "writeStrip=no"
if %stripINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Strip compiled files binaries?
    echo. 1 = Yes [recommended]
    echo. 2 = No
    echo.
    echo. Makes binaries smaller at only a small time cost after compiling.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P stripF="Strip files: "
    ) else set stripF=%stripINI%
if %deleteINI%==1 set "writeStrip=yes"

if %stripF%==1 set "stripFile=y"
if %stripF%==2 set "stripFile=n"
if %stripF% GTR 2 GOTO stripEXE
if %writeStrip%==yes echo.strip=^%stripF%>>%ini%

:packEXE
set "writePack=no"
if %packINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Pack compiled files?
    echo. 1 = Yes
    echo. 2 = No [recommended]
    echo.
    echo. Attention: Some security applications may detect packed binaries as malware.
    echo. Makes binaries a lot smaller at a big time cost after compiling.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P packF="Pack files: "
    ) else set packF=%packINI%
if %deleteINI%==1 set "writePack=yes"

if %packF%==1 set "packFile=y"
if %packF%==2 set "packFile=n"
if %packF% GTR 2 GOTO packEXE
if %writePack%==yes echo.pack=^%packF%>>%ini%

:logging
set "writeLogging=no"
if %loggingINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Write logs of compilation commands?
    echo. 1 = Yes [recommended]
    echo. 2 = No
    echo.
    echo Note: Setting this to yes will also hide output from these commands.
    echo On successful compilation, these logs are deleted since they aren't needed.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P loggingF="Write logs: "
    ) else set loggingF=%loggingINI%
if %deleteINI%==1 set "writeLogging=yes"

if %loggingF%==1 set "logging=y"
if %loggingF%==2 set "logging=n"
if %loggingF% GTR 2 GOTO logging
if %writeLogging%==yes echo.logging=^%loggingF%>>%ini%

::------------------------------------------------------------------
::download and install basic msys2 system:
::------------------------------------------------------------------
if exist "%instdir%\%msys2%\usr\bin\wget.exe" GOTO getMintty
    echo -------------------------------------------------------------
    echo.
    echo - Download wget
    echo.
    echo -------------------------------------------------------------
    if exist %build%\install-wget.js del %build%\install-wget.js
    cd build
    if exist %build%\msys2-base.tar.xz GOTO unpack
    if exist %build%\wget.exe GOTO checkmsys2
    echo.var wshell = new ActiveXObject("WScript.Shell"); var xmlhttp = new ActiveXObject("MSXML2.ServerXMLHTTP"); var adodb = new ActiveXObject("ADODB.Stream"); var FSO = new ActiveXObject("Scripting.FileSystemObject"); function http_get(url, is_binary) {xmlhttp.open("GET", url); xmlhttp.send(); WScript.echo("retrieving " + url); while (xmlhttp.readyState != 4); WScript.Sleep(10); if (xmlhttp.status != 200) {WScript.Echo("http get failed: " + xmlhttp.status); WScript.Quit(2)}; return is_binary ? xmlhttp.responseBody : xmlhttp.responseText}; function save_binary(path, data) {adodb.type = 1; adodb.open(); adodb.write(data); adodb.saveToFile(path, 2)}; function download_wget() {var base_url = "http://blog.pixelcrusher.de/downloads/media-autobuild_suite/wget.zip"; var filename = "wget.zip"; var installer_data = http_get(base_url, true); save_binary(filename, installer_data); return FSO.GetAbsolutePathName(filename)}; function extract_zip(zip_file, dstdir) {var shell = new ActiveXObject("shell.application"); var dst = shell.NameSpace(dstdir); var zipdir = shell.NameSpace(zip_file); dst.CopyHere(zipdir.items(), 0)}; function install_wget(zip_file) {var rootdir = wshell.CurrentDirectory; extract_zip(zip_file, rootdir)}; install_wget(download_wget())>>install-wget.js

    cscript install-wget.js
    del install-wget.js
    del wget.zip
    del 7zip-license.txt
    del COPYING.txt

:checkmsys2
if exist "%instdir%\%msys2%\msys2_shell.bat" GOTO getMintty
    echo -------------------------------------------------------------------------------
    echo.
    echo.- Download and install msys2 basic system
    echo.
    echo -------------------------------------------------------------------------------
    if %msys2%==msys32 (
    set "msysprefix=i686"
    ) else set "msysprefix=x86_64"
    set "msysbase=https://www.mirrorservice.org/sites/download.sourceforge.net/pub/sourceforge/m/ms/msys2/Base/%msysprefix%"
    for /F %%b in (
        '%build%\wget --no-check-certificate -qO- "%msysbase%/?C=M;O=D" ^| ^
        %build%\grep -oPm 1 "(?<=href=.)msys2-base-%msysprefix%-\d{8}.tar.xz"'
        ) do (
        %build%\wget --no-check-certificate --tries=20 --retry-connrefused --waitretry=2 -c -O msys2-base.tar.xz %msysbase%/%%b
        )
    
:unpack
if exist %build%\msys2-base.tar.xz (
    %build%\7za.exe x msys2-base.tar.xz -so | %build%\7za.exe x -aoa -si -ttar -o..
    del %build%\msys2-base.tar.xz
    )
    
if not exist %instdir%\%msys2%\usr\bin\msys-2.0.dll (
    echo -------------------------------------------------------------------------------
    echo.
    echo.- Download msys2 basic system failed,
    echo.- please download it manually from:
    echo.- http://downloads.sourceforge.net/project/msys2
    echo.- and copy the uncompressed folder to:
    echo.- %build%
    echo.- and start the batch script again!
    echo.
    echo -------------------------------------------------------------------------------
    pause
    GOTO unpack
    )

:getMintty
set "mintty=%instdir%\%msys2%\usr\bin\mintty.exe -d -i /msys2.ico"
if not exist %instdir%\mintty.lnk (
    echo -------------------------------------------------------------------------------
    echo.
    echo.- make a first run
    echo.
    echo -------------------------------------------------------------------------------
    (
        echo.sleep ^4
        echo.exit
        )>%build%\firstrun.sh
    %mintty% --log 2>&1 %build%\firstrun.log /usr/bin/bash --login %build%\firstrun.sh
    del %build%\firstrun.sh

    echo.-------------------------------------------------------------------------------
    echo.first update
    echo.-------------------------------------------------------------------------------
    (
        echo.echo -ne "\033]0;first msys2 update\007"
        echo.pacman --noconfirm -Sy --force --asdeps pacman-mirrors
        echo.clear
        echo.echo ""
        echo.echo -------------------------------------------------------------------------------
        echo.echo "You probably will need to manually close this window or"
        echo.echo "run 'exit' after this if closing or pressing Alt+F4"
        echo.echo "doesn't work."
        echo.echo -------------------------------------------------------------------------------
        echo.pacman --noconfirm -S --needed --asdeps bash pacman msys2-runtime
        echo.sleep ^4
        echo.exit
        )>%build%\firstUpdate.sh
    %mintty% --log 2>&1 %build%\firstUpdate.log /usr/bin/bash --login %build%\firstUpdate.sh
    del %build%\firstUpdate.sh

    echo.-------------------------------------------------------------------------------
    echo.second update
    echo.-------------------------------------------------------------------------------
    (
        echo.echo -ne "\033]0;second msys2 update\007"
        echo.pacman --noconfirm -Syu --force --asdeps
        echo.exit
        )>%build%\secondUpdate.sh
    %mintty% --log 2>&1 %build%\secondUpdate.log /usr/bin/bash --login %build%\secondUpdate.sh
    del %build%\secondUpdate.sh
    cls

    (
        echo.Set Shell = CreateObject^("WScript.Shell"^)
        echo.Set link = Shell.CreateShortcut^("%instdir%\mintty.lnk"^)
        echo.link.Arguments = "-i /msys2.ico /usr/bin/bash --login"
        echo.link.Description = "msys2 shell console"
        echo.link.TargetPath = "%instdir%\%msys2%\usr\bin\mintty.exe"
        echo.link.WindowStyle = ^1
        echo.link.IconLocation = "%instdir%\%msys2%\msys2.ico"
        echo.link.WorkingDirectory = "%instdir%\%msys2%\usr\bin"
        echo.link.Save
        )>%build%\setlink.vbs
    cscript /nologo %build%\setlink.vbs
    del %build%\setlink.vbs
    )

    if exist "%instdir%\%msys2%\home\%USERNAME%\.minttyrc" GOTO hgsettings
    if not exist "%instdir%\%msys2%\home\%USERNAME%" mkdir "%instdir%\%msys2%\home\%USERNAME%"
        (
            echo.BoldAsFont=no
            echo.BackgroundColour=57,57,57
            echo.ForegroundColour=221,221,221
            echo.Transparency=medium
            echo.FontHeight=^9
            echo.FontSmoothing=full
            echo.AllowBlinking=yes
            echo.Font=DejaVu Sans Mono
            echo.Columns=120
            echo.Rows=30
            echo.Term=xterm-256color
            echo.CursorType=block
            echo.ClicksPlaceCursor=yes
            echo.Black=38,39,41
            echo.Red=249,38,113
            echo.Green=166,226,46
            echo.Yellow=253,151,31
            echo.Blue=102,217,239
            echo.Magenta=158,111,254
            echo.Cyan=94,113,117
            echo.White=248,248,242
            echo.BoldBlack=85,68,68
            echo.BoldRed=249,38,113
            echo.BoldGreen=166,226,46
            echo.BoldYellow=253,151,31
            echo.BoldBlue=102,217,239
            echo.BoldMagenta=158,111,254
            echo.BoldCyan=163,186,191
            echo.BoldWhite=248,248,242
            )>>"%instdir%\%msys2%\home\%USERNAME%\.minttyrc"

:hgsettings
if exist "%instdir%\%msys2%\home\%USERNAME%\.hgrc" GOTO gitsettings
    (
        echo.[ui]
        echo.username = %USERNAME%
        echo.verbose = True
        echo.editor = vim
        echo.
        echo.[web]
        echo.cacerts=/usr/ssl/cert.pem
        echo.
        echo.[extensions]
        echo.color =
        echo.
        echo.[color]
        echo.status.modified = magenta bold
        echo.status.added = green bold
        echo.status.removed = red bold
        echo.status.deleted = cyan bold
        echo.status.unknown = blue bold
        echo.status.ignored = black bold
        )>>"%instdir%\%msys2%\home\%USERNAME%\.hgrc"

:gitsettings
if exist "%instdir%\%msys2%\home\%USERNAME%\.gitconfig" GOTO rebase
    (
        echo.[user]
        echo.name = %USERNAME%
        echo.email = %USERNAME%@%COMPUTERNAME%
        echo.
        echo.[color]
        echo.ui = true
        echo.
        echo.[core]
        echo.editor = vim
        echo.autocrlf =
        echo.
        echo.[merge]
        echo.tool = vimdiff
        echo.
        echo.[push]
        echo.default = simple
        )>>"%instdir%\%msys2%\home\%USERNAME%\.gitconfig"

:rebase
if %msys2%==msys32 (
    echo.-------------------------------------------------------------------------------
    echo.rebase msys32 system
    echo.-------------------------------------------------------------------------------
    call %instdir%\msys32\autorebase.bat
    )

:installbase
if exist "%instdir%\%msys2%\etc\pac-base.pk" del "%instdir%\%msys2%\etc\pac-base.pk"
for %%i in (%msyspackages%) do echo.%%i>>%instdir%\%msys2%\etc\pac-base.pk

if exist %instdir%\%msys2%\usr\bin\make.exe GOTO sethgBat
    echo.-------------------------------------------------------------------------------
    echo.install msys2 base system
    echo.-------------------------------------------------------------------------------
    (
    echo.echo -ne "\033]0;install base system\007"
    echo.pacman --noconfirm -S --force $(cat /etc/pac-base.pk ^| sed -e 's#\\##'^)
    echo.sleep ^3
    echo.exit
        )>%build%\pacman.sh
    %mintty% --log 2>&1 %build%\pacman.log /usr/bin/bash --login %build%\pacman.sh
    del %build%\pacman.sh

    for %%i in (%instdir%\%msys2%\usr\ssl\cert.pem) do (
        if %%~zi==0 (
            (
                echo.update-ca-trust
                echo.sleep ^3
                echo.exit
                )>%build%\cert.sh
            %mintty% --log 2>&1 %build%\cert.log /usr/bin/bash --login %build%\cert.sh
            del %build%\cert.sh
            )
        )

:sethgBat
if exist %instdir%\%msys2%\usr\bin\hg.bat GOTO getmingw32
(
    echo.@echo off
    echo.
    echo.setlocal
    echo.set HG=^%%~f0
    echo.
    echo.set PYTHONHOME=
    echo.set in=^%%*
    echo.set out=^%%in: ^{= ^"^{^%%
    echo.set out=^%%out:^} =^}^" ^%%
    echo.
    echo.^%%~dp0python2 ^%%~dp0hg ^%%out^%%
    )>>%instdir%\%msys2%\usr\bin\hg.bat

:getmingw32
if exist "%instdir%\%msys2%\etc\pac-mingw.pk" del "%instdir%\%msys2%\etc\pac-mingw.pk"
for %%i in (%mingwpackages%) do echo.%%i>>%instdir%\%msys2%\etc\pac-mingw.pk

if %build32%==yes (
    if exist %instdir%\%msys2%\mingw32\bin\gcc.exe GOTO getmingw64
    echo.-------------------------------------------------------------------------------
    echo.install 32 bit compiler
    echo.-------------------------------------------------------------------------------
    (
        echo.echo -ne "\033]0;install 32 bit compiler\007"
        echo.pacman --noconfirm -S --force $(cat /etc/pac-mingw.pk ^| sed -e 's#\\##' -e 's#.*#mingw-w64-i686-^&#g'^)
        echo.sleep ^3
        echo.exit
        )>%build%\mingw32.sh
    %mintty% --log 2>&1 %build%\mingw32.log /usr/bin/bash --login %build%\mingw32.sh
    del %build%\mingw32.sh
    
    if not exist %instdir%\%msys2%\mingw32\bin\gcc.exe (
        echo -------------------------------------------------------------------------------
        echo.
        echo.MinGW32 GCC compiler isn't installed; maybe the download didn't work
        echo.Do you want to try it again?
        echo.
        echo -------------------------------------------------------------------------------
        set /P try32="try again [y/n]: "

        if %packF%==y (
            GOTO getmingw32
            ) else exit
        )
    )
    
:getmingw64
if %build64%==yes (
    if exist %instdir%\%msys2%\mingw64\bin\gcc.exe GOTO updatebase
    echo.-------------------------------------------------------------------------------
    echo.install 64 bit compiler
    echo.-------------------------------------------------------------------------------
        (
        echo.echo -ne "\033]0;install 64 bit compiler\007"
        echo.pacman --noconfirm -S --force $(cat /etc/pac-mingw.pk ^| sed -e 's#\\##' -e 's#.*#mingw-w64-x86_64-^&#g'^)
        echo.sleep ^3
        echo.exit
            )>%build%\mingw64.sh
    %mintty% --log 2>&1 %build%\mingw64.log /usr/bin/bash --login %build%\mingw64.sh
    del %build%\mingw64.sh

    if not exist %instdir%\%msys2%\mingw64\bin\gcc.exe (
        echo -------------------------------------------------------------------------------
        echo.
        echo.MinGW64 GCC compiler isn't installed; maybe the download didn't work
        echo.Do you want to try it again?
        echo.
        echo -------------------------------------------------------------------------------
        set /P try64="try again [y/n]: "

        if %packF%==y (
            GOTO getmingw64
            ) else exit
        )
    )

:updatebase
echo.-------------------------------------------------------------------------------
echo.update autobuild suite
echo.-------------------------------------------------------------------------------

cd %build%
set scripts=compile helper update
for %%s in (%scripts%) do (
    if not exist "%build%\media-suite_%%s.sh" (
        %instdir%\%msys2%\usr\bin\wget.exe -t 20 --retry-connrefused --waitretry=2 -c ^
        https://github.com/jb-alvarado/media-autobuild_suite/raw/master/build/media-suite_%%s.sh
        )
    )

%mintty% --log 2>&1 %build%\update.log /usr/bin/bash --login %build%\media-suite_update.sh ^
--build32=%build32% --build64=%build64% --remove=%deleteSource%

cls

:rebase2
if %msys2%==msys32 (
    echo.-------------------------------------------------------------------------------
    echo.second rebase msys32 system
    echo.-------------------------------------------------------------------------------
    call %instdir%\msys32\autorebase.bat
    )

:checkdyn

if %build32%==yes (
    if not exist %instdir%\local32\share (
        echo.-------------------------------------------------------------------------------
        echo.create local32 folders
        echo.-------------------------------------------------------------------------------
        mkdir %instdir%\local32
        mkdir %instdir%\local32\bin
        mkdir %instdir%\local32\bin-audio
        mkdir %instdir%\local32\bin-global
        mkdir %instdir%\local32\bin-video
        mkdir %instdir%\local32\etc
        mkdir %instdir%\local32\include
        mkdir %instdir%\local32\lib
        mkdir %instdir%\local32\lib\pkgconfig
        mkdir %instdir%\local32\share
        )
    )

if %build64%==yes (
    if not exist %instdir%\local64\share (
        echo.-------------------------------------------------------------------------------
        echo.create local64 folders
        echo.-------------------------------------------------------------------------------
        mkdir %instdir%\local64
        mkdir %instdir%\local64\bin
        mkdir %instdir%\local64\bin-audio
        mkdir %instdir%\local64\bin-global
        mkdir %instdir%\local64\bin-video
        mkdir %instdir%\local64\etc
        mkdir %instdir%\local64\include
        mkdir %instdir%\local64\lib
        mkdir %instdir%\local64\lib\pkgconfig
        mkdir %instdir%\local64\share
        )
    )

if not exist %instdir%\%msys2%\etc\fstab. GOTO writeFstab
set "removefstab=no"

for /f "tokens=2 delims=/" %%b in ('findstr /i build32 %instdir%\%msys2%\etc\fstab.') do set searchRes=oldbuild
if "%searchRes%"=="oldbuild" set "removefstab=yes"

for /f "tokens=2 delims=/" %%a in ('findstr /i trunk %instdir%\%msys2%\etc\fstab.') do set searchRes=%%a
if not "%searchRes%"=="trunk" set "removefstab=yes"

for /f "tokens=2 delims=/" %%a in ('findstr /i local32 %instdir%\%msys2%\etc\fstab.') do set searchRes=%%a
if "%searchRes%"=="local32" (
    if "%build32%"=="no" set "removefstab=yes"
    ) else (
    if "%build32%"=="yes" set "removefstab=yes"
    )

for /f "tokens=2 delims=/" %%a in ('findstr /i local64 %instdir%\%msys2%\etc\fstab.') do set searchRes=%%a
if "%searchRes%"=="local64" (
    if "%build64%"=="no" set "removefstab=yes"
    ) else (
    if "%build64%"=="yes" set "removefstab=yes"
    )

if "%removefstab%"=="yes" (
    del %instdir%\%msys2%\etc\fstab.
    GOTO writeFstab
    )

if "%searchRes%"=="local32" GOTO writeProfile32
if "%searchRes%"=="local64" (
    GOTO writeProfile32
    ) else del %instdir%\%msys2%\etc\fstab.

    :writeFstab
    echo -------------------------------------------------------------------------------
    echo.
    echo.- write fstab mount file
    echo.
    echo -------------------------------------------------------------------------------

    set cygdrive=no

    if exist %instdir%\%msys2%\etc\fstab. (
        for /f %%b in ('findstr /i binary %instdir%\%msys2%\etc\fstab.') do set cygdrive=yes
        )
    if "%cygdrive%"=="no" echo.none / cygdrive binary,posix=0,noacl,user 0 ^0>>%instdir%\%msys2%\etc\fstab.
    (
        echo.
        echo.%instdir%\ /trunk
        echo.%instdir%\build\ /build
        echo.%instdir%\%msys2%\mingw32\ /mingw32
        echo.%instdir%\%msys2%\mingw64\ /mingw64
        )>>%instdir%\%msys2%\etc\fstab.
    if exist %instdir%\local32 echo.%instdir%\local32\ /local32>>%instdir%\%msys2%\etc\fstab.
    if exist %instdir%\local64 echo.%instdir%\local64\ /local64>>%instdir%\%msys2%\etc\fstab.

::------------------------------------------------------------------
:: write config profiles:
::------------------------------------------------------------------

:writeProfile32
if %build32%==yes (
    if exist %instdir%\local32\etc\profile.local GOTO writeProfile64
        echo -------------------------------------------------------------------------------
        echo.
        echo.- write profile for 32 bit compiling
        echo.
        echo -------------------------------------------------------------------------------
        (
            echo.#
            echo.# /local32/etc/profile.local
            echo.#
            echo.
            echo.MSYSTEM=MINGW32
            echo.
            echo.# package build directory
            echo.LOCALBUILDDIR=/build
            echo.# package installation prefix
            echo.LOCALDESTDIR=/local32
            echo.export LOCALBUILDDIR LOCALDESTDIR
            echo.
            echo.bits='32bit'
            echo.MINGW_CHOST="i686-w64-mingw32"
            echo.MINGW_PREFIX="/mingw32"
            echo.MINGW_PACKAGE_PREFIX="mingw-w64-i686"
            echo.
            echo.# rest is the same in both profiles
            echo.alias dir='ls -la --color=auto'
            echo.alias ls='ls --color=auto'
            echo.export CC=gcc
            echo.export python=/usr/bin/python
            echo.
            echo.MSYS2_PATH="/usr/local/bin:/usr/bin"
            echo.MANPATH="/usr/share/man:${MINGW_PREFIX}/share/man:${LOCALDESTDIR}/man:${LOCALDESTDIR}/share/man"
            echo.INFOPATH="/usr/local/info:/usr/share/info:/usr/info:${MINGW_PREFIX}/share/info"
            echo.
            echo.DXSDK_DIR="${MINGW_PREFIX}/${MINGW_CHOST}"
            echo.ACLOCAL_PATH="${MINGW_PREFIX}/share/aclocal:/usr/share/aclocal"
            echo.PKG_CONFIG="${MINGW_PREFIX}/bin/pkg-config --static"
            echo.PKG_CONFIG_PATH="${LOCALDESTDIR}/lib/pkgconfig:${MINGW_PREFIX}/lib/pkgconfig"
            echo.CPPFLAGS="-I${LOCALDESTDIR}/include -D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1"
            echo.CFLAGS="-I${LOCALDESTDIR}/include -mthreads -mtune=generic -O2 -pipe"
            echo.CXXFLAGS="${CFLAGS}"
            echo.LDFLAGS="-L${LOCALDESTDIR}/lib -pipe"
            echo.export DXSDK_DIR ACLOCAL_PATH PKG_CONFIG PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM
            echo.
            echo.PYTHONHOME=/usr
            echo.PYTHONPATH="/usr/lib/python2.7:/usr/lib/python2.7/Tools/Scripts"
            echo.
            echo.LANG=en_US.UTF-8
            echo.PATH="${LOCALDESTDIR}/bin-audio:${LOCALDESTDIR}/bin-global:${LOCALDESTDIR}/bin-video:${LOCALDESTDIR}/bin:${MINGW_PREFIX}/bin:${MSYS2_PATH}:${INFOPATH}:${PYTHONHOME}:${PYTHONPATH}:${PATH}"
            echo.PS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '
            echo.HOME="/home/${USERNAME}"
            echo.GIT_GUI_LIB_DIR=`cygpath -w /usr/share/git-gui/lib`
            echo.export LANG PATH PS1 HOME GIT_GUI_LIB_DIR
            )>>%instdir%\local32\etc\profile.local
        )

:writeProfile64
if %build64%==yes (
    if exist %instdir%\local64\etc\profile.local GOTO loginProfile
        echo -------------------------------------------------------------------------------
        echo.
        echo.- write profile for 64 bit compiling
        echo.
        echo -------------------------------------------------------------------------------
        (
            echo.#
            echo.# /local64/etc/profile.local
            echo.#
            echo.
            echo.MSYSTEM=MINGW64
            echo.
            echo.# package build directory
            echo.LOCALBUILDDIR=/build
            echo.# package installation prefix
            echo.LOCALDESTDIR=/local64
            echo.export LOCALBUILDDIR LOCALDESTDIR
            echo.
            echo.bits='64bit'
            echo.MINGW_CHOST="x86_64-w64-mingw32"
            echo.MINGW_PREFIX="/mingw64"
            echo.MINGW_PACKAGE_PREFIX="mingw-w64-x86_64"
            echo.
            echo.# rest is the same in both profiles
            echo.alias dir='ls -la --color=auto'
            echo.alias ls='ls --color=auto'
            echo.export CC=gcc
            echo.export python=/usr/bin/python
            echo.
            echo.MSYS2_PATH="/usr/local/bin:/usr/bin"
            echo.MANPATH="/usr/share/man:${MINGW_PREFIX}/share/man:${LOCALDESTDIR}/man:${LOCALDESTDIR}/share/man"
            echo.INFOPATH="/usr/local/info:/usr/share/info:/usr/info:${MINGW_PREFIX}/share/info"
            echo.
            echo.DXSDK_DIR="${MINGW_PREFIX}/${MINGW_CHOST}"
            echo.ACLOCAL_PATH="${MINGW_PREFIX}/share/aclocal:/usr/share/aclocal"
            echo.PKG_CONFIG="${MINGW_PREFIX}/bin/pkg-config --static"
            echo.PKG_CONFIG_PATH="${LOCALDESTDIR}/lib/pkgconfig:${MINGW_PREFIX}/lib/pkgconfig"
            echo.CPPFLAGS="-I${LOCALDESTDIR}/include -D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1"
            echo.CFLAGS="-I${LOCALDESTDIR}/include -mthreads -mtune=generic -O2 -pipe"
            echo.CXXFLAGS="${CFLAGS}"
            echo.LDFLAGS="-L${LOCALDESTDIR}/lib -pipe"
            echo.export DXSDK_DIR ACLOCAL_PATH PKG_CONFIG PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM
            echo.
            echo.PYTHONHOME=/usr
            echo.PYTHONPATH="/usr/lib/python2.7:/usr/lib/python2.7/Tools/Scripts"
            echo.
            echo.LANG=en_US.UTF-8
            echo.PATH="${LOCALDESTDIR}/bin-audio:${LOCALDESTDIR}/bin-global:${LOCALDESTDIR}/bin-video:${LOCALDESTDIR}/bin:${MINGW_PREFIX}/bin:${MSYS2_PATH}:${INFOPATH}:${PYTHONHOME}:${PYTHONPATH}:${PATH}"
            echo.PS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '
            echo.HOME="/home/${USERNAME}"
            echo.GIT_GUI_LIB_DIR=`cygpath -w /usr/share/git-gui/lib`
            echo.export LANG PATH PS1 HOME GIT_GUI_LIB_DIR
            )>>%instdir%\local64\etc\profile.local
        )

:loginProfile
if %build64%==yes GOTO loginProfile64
    %instdir%\%msys2%\usr\bin\grep -q -e 'profile.local' %instdir%\%msys2%\etc\profile || (
        echo -------------------------------------------------------------------------------
        echo.
        echo.- write default profile [32 bit]
        echo.
        echo -------------------------------------------------------------------------------
        (
            echo.
            echo.if [[ -z "$MSYSTEM" ^&^& -f /local32/etc/profile.local ]]; then
            echo.       source /local32/etc/profile.local
            echo.fi
            )>>%instdir%\%msys2%\etc\profile.
    )

    GOTO compileLocals

:loginProfile64
    %instdir%\%msys2%\usr\bin\grep -q -e 'profile.local' %instdir%\%msys2%\etc\profile || (
        echo -------------------------------------------------------------------------------
        echo.
        echo.- write default profile [64 bit]
        echo.
        echo -------------------------------------------------------------------------------
        (
            echo.
            echo.if [[ -z "$MSYSTEM" ^&^& -f /local64/etc/profile.local ]]; then
            echo.       source /local64/etc/profile.local
            echo.fi
            )>>%instdir%\%msys2%\etc\profile.
    )

:compileLocals
cd %instdir%
IF ERRORLEVEL == 1 (
    ECHO Something goes wrong...
    pause
  )

start %instdir%\%msys2%\usr\bin\mintty.exe --log 2>&1 %build%\compile.log -i /msys2.ico /usr/bin/bash --login %build%\media-suite_compile.sh ^
--cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --deleteSource=%deleteSource% --mp4box=%mp4box% ^
--vpx=%vpx% --x264=%x264% --x265=%x265% --other265=%other265% --flac=%flac% --fdkaac=%fdkaac% --mediainfo=%mediainfo% ^
--sox=%sox% --ffmpeg=%ffmpeg% --ffmpegUpdate=%ffmpegUpdate% --ffmpegChoice=%ffmpegChoice% --mplayer=%mplayer% ^
--mpv=%mpv% --license=%license2%  --stripping=%stripFile% --packing=%packFile% --xpcomp=%xpcomp% --rtmpdump=%rtmpdump% ^
--logging=%logging%

endlocal
goto:eof
