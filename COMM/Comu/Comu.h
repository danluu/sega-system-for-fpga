// Comu.h : main header file for the COMU application
//

#if !defined(AFX_COMU_H__56796CC8_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_)
#define AFX_COMU_H__56796CC8_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"       // main symbols

/////////////////////////////////////////////////////////////////////////////
// CComuApp:
// See Comu.cpp for the implementation of this class
//

class CComuApp : public CWinApp
{
public:
	CComuApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CComuApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation
	//{{AFX_MSG(CComuApp)
	afx_msg void OnAppAbout();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_COMU_H__56796CC8_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_)
