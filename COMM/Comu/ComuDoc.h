// ComuDoc.h : interface of the CComuDoc class
//
/////////////////////////////////////////////////////////////////////////////

#if !defined(AFX_COMUDOC_H__56796CCE_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_)
#define AFX_COMUDOC_H__56796CCE_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


class CComuDoc : public CDocument
{
protected: // create from serialization only
	CComuDoc();
	DECLARE_DYNCREATE(CComuDoc)

// Attributes
public:

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CComuDoc)
	public:
	virtual BOOL OnNewDocument();
	virtual void Serialize(CArchive& ar);
	//}}AFX_VIRTUAL

// Implementation
public:
	virtual ~CComuDoc();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(CComuDoc)
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_COMUDOC_H__56796CCE_2A7E_11D2_A0DD_006097AEB8A7__INCLUDED_)
