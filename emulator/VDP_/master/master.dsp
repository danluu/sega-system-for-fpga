# Microsoft Developer Studio Project File - Name="master" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=master - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "master.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "master.mak" CFG="master - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "master - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "master - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "master - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir ""
# PROP Intermediate_Dir ""
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /MT /W4 /GX /ZI /Od /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /FR /YX /FD /GZ /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x809 /d "NDEBUG"
# ADD RSC /l 0x809 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 user32.lib gdi32.lib winmm.lib ddraw.lib dsound.lib dinput.lib dxguid.lib comdlg32.lib comctl32.lib /nologo /subsystem:windows /incremental:yes /debug /machine:I386 /out:"dega.exe"

!ELSEIF  "$(CFG)" == "master - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir ""
# PROP Intermediate_Dir ""
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /MTd /W4 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x809 /d "_DEBUG"
# ADD RSC /l 0x809 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept
# ADD LINK32 user32.lib gdi32.lib winmm.lib ddraw.lib dsound.lib dinput.lib dxguid.lib comdlg32.lib comctl32.lib /nologo /subsystem:windows /debug /machine:I386 /out:"Dega.exe" /pdbtype:sept

!ENDIF 

# Begin Target

# Name "master - Win32 Release"
# Name "master - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\app.h
# End Source File
# Begin Source File

SOURCE=.\app.rc
# End Source File
# Begin Source File

SOURCE=.\conf.cpp
# End Source File
# Begin Source File

SOURCE=..\ece554\doze_554.cpp
# End Source File
# Begin Source File

SOURCE=.\emu.cpp
# End Source File
# Begin Source File

SOURCE=.\frame.cpp
# End Source File
# Begin Source File

SOURCE=.\load.cpp
# End Source File
# Begin Source File

SOURCE=.\main.cpp
# End Source File
# Begin Source File

SOURCE=..\ece554\micro_inst.cpp
# End Source File
# Begin Source File

SOURCE=.\misc.cpp
# End Source File
# Begin Source File

SOURCE=.\resource.h
# End Source File
# Begin Source File

SOURCE=.\run.cpp
# End Source File
# Begin Source File

SOURCE=.\state.cpp
# End Source File
# Begin Source File

SOURCE=..\ece554\z80_decoder.cpp
# End Source File
# Begin Source File

SOURCE=..\ece554\z80_I_run.cpp
# End Source File
# Begin Source File

SOURCE=..\ece554\z80_uOP_run.cpp
# End Source File
# End Group
# Begin Group "Media"

# PROP Default_Filter ""
# Begin Source File

SOURCE=.\dinp.cpp
# End Source File
# Begin Source File

SOURCE=.\disp.cpp
# End Source File
# Begin Source File

SOURCE=.\dsound.cpp
# End Source File
# Begin Source File

SOURCE=.\input.cpp
# End Source File
# Begin Source File

SOURCE=.\loop.cpp
# End Source File
# Begin Source File

SOURCE=.\render.cpp
# End Source File
# Begin Source File

SOURCE=.\shot.cpp
# End Source File
# End Group
# Begin Group "Other Files"

# PROP Default_Filter ""
# Begin Source File

SOURCE=.\dega.ini
# End Source File
# Begin Source File

SOURCE=.\dega.txt
# End Source File
# Begin Source File

SOURCE=.\icon1.ico
# End Source File
# Begin Source File

SOURCE=.\zzd.txt
# End Source File
# End Group
# Begin Group "Compression"

# PROP Default_Filter ""
# Begin Source File

SOURCE=.\zconf.h
# End Source File
# Begin Source File

SOURCE=.\zlib.h
# End Source File
# Begin Source File

SOURCE=.\zlib.lib
# End Source File
# End Group
# Begin Source File

SOURCE=..\ece554\DataValue.h
# End Source File
# Begin Source File

SOURCE=..\ece554\micro_ISA_ID.h
# End Source File
# Begin Source File

SOURCE=..\ece554\z80_uOP_run.h
# End Source File
# End Target
# End Project
