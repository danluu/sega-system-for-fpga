// ComuView.cpp : implementation of the CComuView class
//

#include "stdafx.h"
#include "Comu.h"

#include "MainFrm.h"
#include "ComuDoc.h"
#include "ComuView.h"

#include "ComCfg.h"
#include "GetNum.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

// Max Value Define
#define MAX_ANSI_LEN 11

// Window Definition For CommThread Message 
HWND hCommWnd;

/////////////////////////////////////////////////////////////////////////////
// CComuView

IMPLEMENT_DYNCREATE(CComuView, CView)

BEGIN_MESSAGE_MAP(CComuView, CView)
	//{{AFX_MSG_MAP(CComuView)
	ON_WM_CREATE()
	ON_COMMAND(IDM_SERIAL_SET, OnSerialSet)
	ON_COMMAND(IDM_SERIAL_INIT, OnSerialInit)
	ON_COMMAND(IDM_MODEM_CONNECT, OnModemConnect)
	ON_COMMAND(IDM_MODEM_INIT, OnModemInit)
	ON_COMMAND(IDM_MODEM_DISCONNECT, OnModemDisconnect)
	ON_WM_CHAR()
	ON_MESSAGE(WM_COMM_READ, OnCommunication)    // Communication Message Handleer
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CComuView construction/destruction

CComuView::CComuView()
{
	//{{AFX_DATA_INIT(CComuView)
	//}}AFX_DATA_INIT

	m_nPort= 0;

	// Set Flag
	m_bPortInit= FALSE;
	m_bAnsiStart= FALSE;

	for( int i= 0; i< 30; i++ ) m_strLine[i].Empty();

	m_nLinePos= 0;
	m_nColPos= 0;
}

CComuView::~CComuView()
{
}

BOOL CComuView::PreCreateWindow(CREATESTRUCT& cs)
{
	return CView::PreCreateWindow(cs);
}

/////////////////////////////////////////////////////////////////////////////
// CComuView drawing

void CComuView::OnDraw(CDC* pDC)
{
	CComuDoc* pDoc = GetDocument();
	ASSERT_VALID(pDoc);

	hCommWnd= m_hWnd;
}

/////////////////////////////////////////////////////////////////////////////
// CComuView diagnostics

#ifdef _DEBUG
void CComuView::AssertValid() const
{
	CView::AssertValid();
}

void CComuView::Dump(CDumpContext& dc) const
{
	CView::Dump(dc);
}

CComuDoc* CComuView::GetDocument() // non-debug version is inline
{
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(CComuDoc)));
	return (CComuDoc*)m_pDocument;
}
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CComuView message handlers

// Error Message processing
void CComuView::ProcessErrorMessage( CString msg )
{
	((CMainFrame *)AfxGetMainWnd())->m_wndStatusBar.SetWindowText(msg);
}

// Window Size에 맞는 Font크기를 구한다.
int CComuView::OnCreate(LPCREATESTRUCT lpCreateStruct) 
{
	if (CView::OnCreate(lpCreateStruct) == -1)
		return -1;

	// Client영역의 크기를 구한다.
	CRect rect;
	GetClientRect(rect);

	// 현재의 Text Matrics를 구한다.
	CDC *pDC;
	TEXTMETRIC tm;

	pDC= GetDC();
	pDC->GetTextMetrics(&tm);

	// 화면 Size는 80x25
	tm.tmHeight= (rect.bottom-rect.top)/25;

	// 새로 사용할 Font를 Create
	CFont newFont;

	newFont.CreateFont( tm.tmHeight, tm.tmHeight, 
						0, 0, tm.tmWeight, tm.tmItalic, tm.tmUnderlined, tm.tmStruckOut, 
						tm.tmCharSet, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, 
						DEFAULT_QUALITY, DEFAULT_PITCH, "굴림체" );

	pDC->SelectObject(&newFont);

	return 0;
}

// Simple Editor Function
void CComuView::ClearAll()
{
	CDC *pDC;
	CRect rect;
	CBrush brush;

	pDC= GetDC();
	GetClientRect(rect);

	brush.CreateSolidBrush(RGB(255,255,255));

	pDC->FillRect( &rect, &brush );

	Invalidate(TRUE);

	for( int i= 0; i< 30; i++ )
		m_strLine[i].Empty();
}

void CComuView::PutChar(unsigned char ch)
{
	CDC *pDC;
	TEXTMETRIC tm;

	pDC= GetDC();
	pDC->GetTextMetrics(&tm);

	if( ch==10 ) 
	{
		m_nLinePos++;
		if( m_nLinePos>25 ) 
		{
			m_nLinePos= 0;
			m_nColPos= 0;
			ClearAll();
		}
	}
	else if( ch==13 )
	{
		m_nColPos= 0;
	}
	else
	{
		// 현 Cursor 위치에 글자를 쓴다.
		m_strLine[m_nLinePos].Insert( m_nColPos, ch );

		pDC->TextOut(0,m_nLinePos*tm.tmHeight,m_strLine[m_nLinePos]);
		m_nColPos++;
	}
}

void CComuView::DeleteLine(int pos, int type)
{
	CDC *pDC;
	TEXTMETRIC tm;
	CRect rect;
	CBrush brush;

	pDC= GetDC();
	pDC->GetTextMetrics(&tm);
	GetClientRect(rect);
	brush.CreateSolidBrush(RGB(255,255,255));

	if( type== 0 )
	{
		rect.top= m_nLinePos*tm.tmHeight;
		rect.bottom= (m_nLinePos+1)*tm.tmHeight;
	}
	else
	{
		rect.left= m_nColPos*tm.tmHeight;
		rect.top= m_nLinePos*tm.tmHeight;
		rect.bottom= m_nLinePos*(tm.tmHeight+1);
	}

	pDC->FillRect( &rect, &brush );
	Invalidate(TRUE);

	m_strLine[m_nLinePos].Empty();
	m_nColPos= 0;
	m_nLinePos--;
}

void CComuView::DelChar()
{
	CDC *pDC;
	TEXTMETRIC tm;
	CString strTemp;
	CRect rect;
	CBrush brush;

	pDC= GetDC();
	pDC->GetTextMetrics(&tm);
	GetClientRect(rect);
	brush.CreateSolidBrush(RGB(255,255,255));

	if( m_strLine[m_nLinePos].GetLength()== 0 ) return;
	else if( m_strLine[m_nLinePos].GetLength()== 1 ) 
	{
		m_strLine[m_nLinePos].Empty();
	}
	else
	{
		strTemp.Empty();
		strTemp+= m_strLine[m_nLinePos].Left(m_strLine[m_nLinePos].GetLength()-1);
		m_strLine[m_nLinePos].Empty();
		m_strLine[m_nLinePos]+= strTemp;
	}

	rect.top= m_nLinePos*tm.tmHeight;
	rect.bottom= (m_nLinePos+1)*tm.tmHeight;
	pDC->FillRect( &rect, &brush );

	pDC->TextOut(0,m_nLinePos*tm.tmHeight,m_strLine[m_nLinePos]);
	m_nColPos--;
}

// Serial Port 관련 메뉴
void CComuView::OnSerialSet() 
{
	CComCfg dlg;
	
	if( dlg.DoModal()== IDOK )
	{
		m_nPort= dlg.GetPort();
		m_nBaudRate= dlg.GetBaudRate();
	}
}

void CComuView::OnSerialInit() 
{
	if( m_nPort== 0 )
	{
		ProcessErrorMessage(_T("포트를 Setting 해 주십시오."));
		return;
	}

	CString strTemp;
	strTemp.Format("COM%d", m_nPort);
	if( !m_ComuPort.OpenPort( strTemp, m_nBaudRate, m_nPort ) )
	{
		ProcessErrorMessage(_T("포트를 초기화 실패."));
	}
	else
	{
		CString strTemp;
		strTemp.Format( "포트 COM%d초기화 성공", m_nPort );
		ProcessErrorMessage(strTemp);

		m_bPortInit= TRUE;
	}	
}

// Process Keyboard Hit Message
void CComuView::OnChar(UINT nChar, UINT nRepCnt, UINT nFlags) 
{
	CString strTemp;

	if( !m_bPortInit )
	{
		ProcessErrorMessage("포트가 Open되지 않았습니다.");
		CView::OnChar(nChar, nRepCnt, nFlags);
		return;
	}
	else
	{
		if( nChar== 10 ) // Process only /r when /n/r input
		{
			strTemp.Format( "%c", 13 );
			m_ComuPort.WriteComm((unsigned char*)(LPCTSTR)strTemp,strTemp.GetLength());
		}
		else 
		{
			strTemp.Format( "%c", nChar );
			m_ComuPort.WriteComm((unsigned char*)(LPCTSTR)strTemp,strTemp.GetLength());		
		}
	}	
	
	CView::OnChar(nChar, nRepCnt, nFlags);
}

//
// ANSI Command Processing
//
BOOL CComuView::IsAnsiCommand( unsigned char ch )
{
	unsigned char AnsiCommand[22]= { 'm','K','h','l','J','G','F','s','u','A','B','C','D',
									 'L','M','@','P','Z','H','r','t','d' };

	for( int i= 0; i< 22; i++ )
		if( ch==AnsiCommand[i] ) return TRUE;

	return FALSE;
}

void CComuView::ProcessAnsi()
{
	int nBrench, nCount;
	int nVal[3], nIndex;
	LONG nStart=0, nEnd=0;

	nBrench= m_strAnsi.GetLength();

	// Process Delete ANSI
	if( m_strAnsi.Right(1)==_T("K") || m_strAnsi.Right(1)==_T("J") )
	{
		if( nBrench==1 ) // ESC J or ESC K
		{
			DeleteLine( m_nColPos,1 );
		}
		else if( nBrench==2 && m_strAnsi[0]=='[' ) // ESC[J or ESC[K
		{
			DeleteLine( m_nColPos,1 );
		}
		else if( m_strAnsi[1]=='1' )
		{
			DeleteLine( m_nColPos, 0 );
		}
		else if( m_strAnsi[1]=='2' )
		{
			ClearAll();			
		}
	}

	// Process Cursor Move ANSI
	nVal[0]= 0;
	nVal[1]= 0;
	nVal[3]= 0;
	nCount= 0;
	nIndex= 0;
	if( m_strAnsi.Right(1)==_T("H") || m_strAnsi.Right(1)==_T("f") )
	{
		for( nCount= 1; nCount< nBrench-1; nCount++ )
		{
			if( m_strAnsi[nCount]==';' )
			{
				nIndex++;
			}
			else
			{
				nVal[nIndex]= nVal[nIndex]*10 + (m_strAnsi[nCount]-'0');
			}
		}

		m_nLinePos= nVal[0];
		m_nColPos= nVal[1];
	}
}

//
// Process Serial Port Read Message
//
LONG CComuView::OnCommunication(UINT port, LONG lParam)
{
	unsigned char ch;
	char buff[2048]="";
	BYTE aByte;

	int size= (m_ComuPort.m_QueueRead).GetSize();
	for( int i=0; i< size; i++ )
	{
		(m_ComuPort.m_QueueRead).GetByte(&aByte);
		if( aByte!= NULL ) buff[i]= aByte;
		else { i--; size--; }
	}

	for( i= 0; i< size; i++ )
	{
		ch= buff[i];

		if( ch==8 ) // Back Space
		{
			DelChar();
		}
		else if( ch==0x1B ) // ESC ( ANSI Start )
		{
			m_bAnsiStart= TRUE;
			m_nAnsiCount= 0;
			m_strAnsi.Empty();
		}
		else
		{
			if( m_bAnsiStart )
			{
				m_strAnsi+= ch;
				m_nAnsiCount++;

				if( IsAnsiCommand(ch) )
				{
					ProcessAnsi();
					m_bAnsiStart= FALSE;
					m_nAnsiCount= 0;
					m_strAnsi.Empty();
				}

				if( m_nAnsiCount==MAX_ANSI_LEN )
				{
					m_bAnsiStart= FALSE;
					m_nAnsiCount= 0;
					m_strAnsi.Empty();
				}

				return 0;
			} 
			
			PutChar((unsigned char)ch);
		}
	}

	return 0;
}

//
// Modem Control Menu
//
void CComuView::OnModemConnect() 
{
	CGetNum dlg;
	CString strTemp;

	if( dlg.DoModal()==IDOK )
	{
		if( dlg.IsUseExt() )
		{
			strTemp.Format( "ATDT%s,%s\r", dlg.GetExt(), dlg.GetNum() );
			
			m_ComuPort.WriteComm((unsigned char*)(LPCTSTR)strTemp,strTemp.GetLength());
		}
		else
		{
			strTemp.Format( "ATDT%s\r", dlg.GetNum() );

			m_ComuPort.WriteComm((unsigned char*)(LPCTSTR)strTemp,strTemp.GetLength());
		}
	}
}

void CComuView::OnModemInit() 
{
	CString strTemp;
		
	if( !m_bPortInit )
	{
		ProcessErrorMessage("포트가 Open되지 않았습니다.");
		return ;
	}
	else
	{
		strTemp.Format( "ATZ\r");
		m_ComuPort.WriteComm((unsigned char*)(LPCTSTR)strTemp,strTemp.GetLength());

		Sleep(500);

		strTemp.Format( "AT&C1X3\r");
		m_ComuPort.WriteComm((unsigned char*)(LPCTSTR)strTemp,strTemp.GetLength());
	}		
}

void CComuView::OnModemDisconnect() 
{
	CString strTemp;
	unsigned char esc[4]="+++";
		
	if( !m_bPortInit )
	{
		ProcessErrorMessage("포트가 Open되지 않았습니다.");
		return ;
	}
	else
	{
		strTemp.Format( "%s", esc );
		m_ComuPort.WriteComm((unsigned char*)(LPCTSTR)strTemp,strTemp.GetLength());

		Sleep(5000);

		strTemp.Format( "ATH\r" );
		m_ComuPort.WriteComm((unsigned char*)(LPCTSTR)strTemp,strTemp.GetLength());
	}		
}

