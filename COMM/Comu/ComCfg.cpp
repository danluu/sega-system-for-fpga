// ComCfg.cpp : implementation file
//

#include "stdafx.h"
#include "Comu.h"
#include "ComCfg.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CComCfg dialog


CComCfg::CComCfg(CWnd* pParent /*=NULL*/)
	: CDialog(CComCfg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CComCfg)
		// NOTE: the ClassWizard will add member initialization here
	//}}AFX_DATA_INIT

	// Return Value √ ±‚»≠
	m_nPort= 2;
	m_nBaudRate= 38400;
}


void CComCfg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CComCfg)
		// NOTE: the ClassWizard will add DDX and DDV calls here
	//}}AFX_DATA_MAP
}


BEGIN_MESSAGE_MAP(CComCfg, CDialog)
	//{{AFX_MSG_MAP(CComCfg)
	ON_BN_CLICKED(IDC_RADIO_COM1, OnRadioCom1)
	ON_BN_CLICKED(IDC_RADIO_COM2, OnRadioCom2)
	ON_BN_CLICKED(IDC_RADIO_COM3, OnRadioCom3)
	ON_BN_CLICKED(IDC_RADIO_COM4, OnRadioCom4)
	ON_BN_CLICKED(IDC_RADIO_BAUD1, OnRadioBaud1)
	ON_BN_CLICKED(IDC_RADIO_BAUD2, OnRadioBaud2)
	ON_BN_CLICKED(IDC_RADIO_BAUD3, OnRadioBaud3)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CComCfg message handlers

// Selection Processing
void CComCfg::OnRadioCom1() 
{
	m_nPort= 1;	
}

void CComCfg::OnRadioCom2() 
{
	m_nPort= 2;	
}

void CComCfg::OnRadioCom3() 
{
	m_nPort= 3;	
}

void CComCfg::OnRadioCom4() 
{
	m_nPort= 4;	
}

void CComCfg::OnRadioBaud1() 
{
	m_nBaudRate= 9600;	
}

void CComCfg::OnRadioBaud2() 
{
	m_nBaudRate= 19200;	
}

void CComCfg::OnRadioBaud3() 
{
	m_nBaudRate= 38400;	
}

// Value Extrtaction
UINT CComCfg::GetPort()
{
	return m_nPort;
}

UINT CComCfg::GetBaudRate()
{
	return m_nBaudRate;
}
