#if !defined(AFX_COMCFG_H__56796CDB_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_)
#define AFX_COMCFG_H__56796CDB_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000
// ComCfg.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// CComCfg dialog

class CComCfg : public CDialog
{
// Construction
public:
	CComCfg(CWnd* pParent = NULL);   // standard constructor

	UINT m_nPort;
	UINT m_nBaudRate;

	UINT GetPort();
	UINT GetBaudRate();

// Dialog Data
	//{{AFX_DATA(CComCfg)
	enum { IDD = IDD_DIALOG_COM };
		// NOTE: the ClassWizard will add data members here
	//}}AFX_DATA


// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CComCfg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:

	// Generated message map functions
	//{{AFX_MSG(CComCfg)
	afx_msg void OnRadioCom1();
	afx_msg void OnRadioCom2();
	afx_msg void OnRadioCom3();
	afx_msg void OnRadioCom4();
	afx_msg void OnRadioBaud1();
	afx_msg void OnRadioBaud2();
	afx_msg void OnRadioBaud3();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_COMCFG_H__56796CDB_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_)
