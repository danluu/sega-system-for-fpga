// ComuView.h : interface of the CComuView class
//
/////////////////////////////////////////////////////////////////////////////

#if !defined(AFX_COMUVIEW_H__56796CD0_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_)
#define AFX_COMUVIEW_H__56796CD0_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "CommThread.h"

class CComuView : public CView
{
protected: // create from serialization only
	CComuView();
	DECLARE_DYNCREATE(CComuView)

// Attributes
public:
	CComuDoc* GetDocument();

	// Flags
	BOOL m_bPortInit;   // Com Port Initialized ?
	BOOL m_bAnsiStart;  // ANSI character process ?

	// Com Port Variables
	UINT m_nPort;
	UINT m_nBaudRate;
	CCommThread m_ComuPort;

	// Buffer
	CString m_strAnsi;
	CString m_strLine[30];

	// Text Position
	int m_nAnsiCount;
	int m_nLinePos;
	int m_nColPos;

	// Simple Edit Function
	void ClearAll();
	void PutChar(unsigned char ch);
	void DeleteLine(int pos, int type);
	void DelChar();

	void ProcessErrorMessage( CString msg );

	// ANSI Processing
	BOOL IsAnsiCommand( unsigned char ch );
	void ProcessAnsi();

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CComuView)
	public:
	virtual BOOL PreCreateWindow(CREATESTRUCT& cs);
	protected:
	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
	//}}AFX_VIRTUAL
	afx_msg LONG OnCommunication(UINT, LONG); // Communication Message

// Implementation
public:
	virtual ~CComuView();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(CComuView)
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
	afx_msg void OnSerialSet();
	afx_msg void OnSerialInit();
	afx_msg void OnModemConnect();
	afx_msg void OnModemInit();
	afx_msg void OnModemDisconnect();
	afx_msg void OnChar(UINT nChar, UINT nRepCnt, UINT nFlags);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG  // debug version in ComuView.cpp
inline CComuDoc* CComuView::GetDocument()
   { return (CComuDoc*)m_pDocument; }
#endif

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_COMUVIEW_H__56796CD0_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_)
