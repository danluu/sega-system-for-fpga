// ComuDoc.cpp : implementation of the CComuDoc class
//

#include "stdafx.h"
#include "Comu.h"

#include "ComuDoc.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CComuDoc

IMPLEMENT_DYNCREATE(CComuDoc, CDocument)

BEGIN_MESSAGE_MAP(CComuDoc, CDocument)
	//{{AFX_MSG_MAP(CComuDoc)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CComuDoc construction/destruction

CComuDoc::CComuDoc()
{
}

CComuDoc::~CComuDoc()
{
}

BOOL CComuDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;

	return TRUE;
}



/////////////////////////////////////////////////////////////////////////////
// CComuDoc serialization

void CComuDoc::Serialize(CArchive& ar)
{
	if (ar.IsStoring())
	{
	}
	else
	{
	}
}

/////////////////////////////////////////////////////////////////////////////
// CComuDoc diagnostics

#ifdef _DEBUG
void CComuDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void CComuDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CComuDoc commands
