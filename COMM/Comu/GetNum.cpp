// GetNum.cpp : implementation file
//

#include "stdafx.h"
#include "Comu.h"
#include "GetNum.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CGetNum dialog


CGetNum::CGetNum(CWnd* pParent /*=NULL*/)
	: CDialog(CGetNum::IDD, pParent)
{
	//{{AFX_DATA_INIT(CGetNum)
	m_edPhoneNum = _T("");
	m_chkExt = FALSE;
	m_edExt = _T("");
	//}}AFX_DATA_INIT
}


void CGetNum::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CGetNum)
	DDX_Text(pDX, IDC_EDIT_NUM, m_edPhoneNum);
	DDX_Check(pDX, IDC_CHECK_EXT, m_chkExt);
	DDX_Text(pDX, IDC_EDIT_EXT, m_edExt);
	//}}AFX_DATA_MAP
}


BEGIN_MESSAGE_MAP(CGetNum, CDialog)
	//{{AFX_MSG_MAP(CGetNum)
		// NOTE: the ClassWizard will add message map macros here
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CGetNum message handlers
BOOL CGetNum::IsUseExt()
{
	return m_chkExt;
}

CString CGetNum::GetExt()
{
	return m_edExt;
}

CString CGetNum::GetNum()
{
	return m_edPhoneNum;
}