; CLW file contains information for the MFC ClassWizard

[General Info]
Version=1
LastClass=CComuView
LastTemplate=CDialog
NewFileInclude1=#include "stdafx.h"
NewFileInclude2=#include "Comu.h"
LastPage=0

ClassCount=8
Class1=CComuApp
Class2=CComuDoc
Class3=CComuView
Class4=CMainFrame

ResourceCount=5
Resource1=IDD_ABOUTBOX
Resource2=IDD_COMU_FORM
Class5=CAboutDlg
Resource3=IDR_MAINFRAME
Class6=CComCfg
Resource4=IDD_DIALOG_COM
Class7=CGetNum
Class8=CRZ
Resource5=IDD_DIALOG_CONNECT

[CLS:CComuApp]
Type=0
HeaderFile=Comu.h
ImplementationFile=Comu.cpp
Filter=N

[CLS:CComuDoc]
Type=0
HeaderFile=ComuDoc.h
ImplementationFile=ComuDoc.cpp
Filter=N

[CLS:CComuView]
Type=0
HeaderFile=ComuView.h
ImplementationFile=ComuView.cpp
Filter=D
BaseClass=CView
VirtualFilter=VWC
LastObject=CComuView

[CLS:CMainFrame]
Type=0
HeaderFile=MainFrm.h
ImplementationFile=MainFrm.cpp
Filter=T
BaseClass=CFrameWnd
VirtualFilter=fWC
LastObject=IDM_ZMODEM_RECV




[CLS:CAboutDlg]
Type=0
HeaderFile=Comu.cpp
ImplementationFile=Comu.cpp
Filter=D

[DLG:IDD_ABOUTBOX]
Type=1
Class=CAboutDlg
ControlCount=4
Control1=IDC_STATIC,static,1342177283
Control2=IDC_STATIC,static,1342308480
Control3=IDC_STATIC,static,1342308352
Control4=IDOK,button,1342373889

[MNU:IDR_MAINFRAME]
Type=1
Class=CMainFrame
Command1=ID_FILE_NEW
Command2=ID_FILE_OPEN
Command3=ID_FILE_SAVE
Command4=ID_FILE_SAVE_AS
Command5=ID_FILE_MRU_FILE1
Command6=ID_APP_EXIT
Command7=ID_EDIT_UNDO
Command8=ID_EDIT_CUT
Command9=ID_EDIT_COPY
Command10=ID_EDIT_PASTE
Command11=ID_VIEW_TOOLBAR
Command12=ID_VIEW_STATUS_BAR
Command13=IDM_SERIAL_SET
Command14=IDM_SERIAL_INIT
Command15=IDM_MODEM_INIT
Command16=IDM_MODEM_CONNECT
Command17=IDM_MODEM_DISCONNECT
Command18=ID_APP_ABOUT
CommandCount=18

[ACL:IDR_MAINFRAME]
Type=1
Class=CMainFrame
Command1=ID_FILE_NEW
Command2=ID_FILE_OPEN
Command3=ID_FILE_SAVE
Command4=ID_FILE_PRINT
Command5=ID_EDIT_UNDO
Command6=ID_EDIT_CUT
Command7=ID_EDIT_COPY
Command8=ID_EDIT_PASTE
Command9=ID_EDIT_UNDO
Command10=ID_EDIT_CUT
Command11=ID_EDIT_COPY
Command12=ID_EDIT_PASTE
Command13=ID_NEXT_PANE
Command14=ID_PREV_PANE
CommandCount=14

[DLG:IDD_COMU_FORM]
Type=1
Class=CComuView
ControlCount=0

[TB:IDR_MAINFRAME]
Type=1
Class=?
Command1=ID_FILE_NEW
Command2=ID_FILE_OPEN
Command3=ID_FILE_SAVE
Command4=ID_EDIT_CUT
Command5=ID_EDIT_COPY
Command6=ID_EDIT_PASTE
Command7=ID_FILE_PRINT
Command8=ID_APP_ABOUT
CommandCount=8

[DLG:IDD_DIALOG_COM]
Type=1
Class=CComCfg
ControlCount=11
Control1=IDOK,button,1342242817
Control2=IDCANCEL,button,1342242816
Control3=IDC_STATIC,button,1342177287
Control4=IDC_RADIO_COM1,button,1342308361
Control5=IDC_RADIO_COM2,button,1342177289
Control6=IDC_RADIO_COM3,button,1342177289
Control7=IDC_RADIO_COM4,button,1342177289
Control8=IDC_STATIC,button,1342177287
Control9=IDC_RADIO_BAUD1,button,1342308361
Control10=IDC_RADIO_BAUD2,button,1342177289
Control11=IDC_RADIO_BAUD3,button,1342177289

[CLS:CComCfg]
Type=0
HeaderFile=ComCfg.h
ImplementationFile=ComCfg.cpp
BaseClass=CDialog
Filter=D
LastObject=CComCfg
VirtualFilter=dWC

[DLG:IDD_DIALOG_CONNECT]
Type=1
Class=CGetNum
ControlCount=7
Control1=IDOK,button,1342242817
Control2=IDCANCEL,button,1342242816
Control3=IDC_CHECK_EXT,button,1342242819
Control4=IDC_EDIT_EXT,edit,1350631552
Control5=IDC_STATIC,button,1342177287
Control6=IDC_STATIC,button,1342177287
Control7=IDC_EDIT_NUM,edit,1350631552

[CLS:CGetNum]
Type=0
HeaderFile=GetNum.h
ImplementationFile=GetNum.cpp
BaseClass=CDialog
Filter=D
LastObject=IDC_EDIT_NUM
VirtualFilter=dWC

[CLS:CRZ]
Type=0
HeaderFile=RZ.h
ImplementationFile=RZ.cpp
BaseClass=CDialog
Filter=D
LastObject=CRZ
VirtualFilter=dWC

