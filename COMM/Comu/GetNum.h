#if !defined(AFX_GETNUM_H__A9EE1BC7_2D30_11D2_A4C7_9FC4A1F50839__INCLUDED_)
#define AFX_GETNUM_H__A9EE1BC7_2D30_11D2_A4C7_9FC4A1F50839__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000
// GetNum.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// CGetNum dialog

class CGetNum : public CDialog
{
// Construction
public:
	CGetNum(CWnd* pParent = NULL);   // standard constructor

	BOOL IsUseExt();
	CString GetExt();
	CString GetNum();

	// Dialog Data
	//{{AFX_DATA(CGetNum)
	enum { IDD = IDD_DIALOG_CONNECT };
	CString	m_edPhoneNum;
	BOOL	m_chkExt;
	CString	m_edExt;
	//}}AFX_DATA


// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CGetNum)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:

	// Generated message map functions
	//{{AFX_MSG(CGetNum)
		// NOTE: the ClassWizard will add member functions here
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_GETNUM_H__A9EE1BC7_2D30_11D2_A4C7_9FC4A1F50839__INCLUDED_)
