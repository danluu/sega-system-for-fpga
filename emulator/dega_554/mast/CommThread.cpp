#include "stdafx.h"
#include "CommThread.h"



int READ_BUF;

// 메세지를 받을 윈도우 핸들, 부모 윈도우에서 HWND hCommWnd= this->m_hWnd로
// 설정해 준다.
//extern HWND hCommWnd;

// CQueue 구현부========================================= 

// Queue의 생성자
CQueue::CQueue()
{
	Clear();
}

// Queue를 초기화
void CQueue::Clear()
{
	m_iHead = m_iTail = 0;
	memset(buff, 0, BUFF_SIZE);
}

// Queue에 들어 있는 자료 개수.
int CQueue::GetSize()
{
	return (m_iHead - m_iTail + BUFF_SIZE) % BUFF_SIZE;
}

// Queue에 1 byte 넣음.
BOOL CQueue::PutByte(BYTE b)
{
	if (GetSize() == (BUFF_SIZE-1)) return FALSE;
	buff[m_iHead++] = b;
	m_iHead %= BUFF_SIZE;
	return TRUE;
}

// Queue에서 1 byte 꺼냄.
BOOL CQueue::GetByte(BYTE* pb)
{
	if (GetSize() == 0) return FALSE;
	*pb = buff[m_iTail++];
	m_iTail %= BUFF_SIZE;
	return TRUE;
}


// 포트 sPortName을 dwBaud 속도로 연다.
// ThreadWatchComm 함수에서 포트에 무언가 읽혔을 때 MainWnd에 알리기
// 위해 WM_COMM_READ메시지를 보낼때 같이 보낼 wPortID값을 전달 받는다.
BOOL CCommThread::OpenPort(CString sPortName, DWORD dwBaud, WORD wPortID)
{
	// Local 변수.
	COMMTIMEOUTS	timeouts;
	DCB				dcb;
	DWORD			dwThreadID;

	// 변수 초기화
	m_bConnected = FALSE;
	m_wPortID	= wPortID; // COM1-> 0, COM2->1,,,,,

	// overlapped structure 변수 초기화.
	m_osRead.Offset = 0;
	m_osRead.OffsetHigh = 0;
	if (! (m_osRead.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL)))	
		return FALSE;
	m_osWrite.Offset = 0;
	m_osWrite.OffsetHigh = 0;
	if (! (m_osWrite.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL)))
		return FALSE;
	
	// 포트 열기
	m_sPortName = sPortName;
	m_hComm = CreateFile( m_sPortName, 
		GENERIC_READ | GENERIC_WRITE, 0, NULL,
		OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OVERLAPPED, 
		NULL);
	if (m_hComm == (HANDLE) -1) return FALSE;

	// 포트 상태 설정.

	// EV_RXCHAR event 설정
	SetCommMask( m_hComm, EV_RXCHAR);	

	// InQueue, OutQueue 크기 설정.
	SetupComm( m_hComm, 8192, 8192);	

	// 포트 비우기.
	PurgeComm( m_hComm,					
		PURGE_TXABORT | PURGE_TXCLEAR | PURGE_RXABORT | PURGE_RXCLEAR);

	// timeout 설정.
	timeouts.ReadIntervalTimeout = 0xFFFFFFFF;
	timeouts.ReadTotalTimeoutMultiplier = 0;
	timeouts.ReadTotalTimeoutConstant = 0;
	timeouts.WriteTotalTimeoutMultiplier = 2*CBR_9600 / dwBaud;
	timeouts.WriteTotalTimeoutConstant = 0;
	SetCommTimeouts( m_hComm, &timeouts);

	// dcb 설정
	dcb.DCBlength = sizeof(DCB);
	GetCommState( m_hComm, &dcb);	// 예전 값을 읽음.
	dcb.BaudRate = dwBaud;
	dcb.ByteSize = 8;
	dcb.Parity = 0;
	dcb.StopBits = 0;
	dcb.fInX = dcb.fOutX = 0;		// Xon, Xoff 사용.
	dcb.XonChar = ASCII_XON;
	dcb.XoffChar = ASCII_XOFF;
	dcb.XonLim = 100;
	dcb.XoffLim = 100;
	if (! SetCommState( m_hComm, &dcb))	return FALSE;

	// 포트 감시 쓰레드 생성.
	m_bConnected = TRUE;
//	m_hThreadWatchComm = CreateThread( NULL, 0, 
//		(LPTHREAD_START_ROUTINE)ThreadWatchComm, this, 0, &dwThreadID);
//	if (! m_hThreadWatchComm)
//	{
//		ClosePort();
//		return FALSE;
//	}

	return TRUE;
}
	
// 포트를 닫는다.
void CCommThread::ClosePort()
{
	m_bConnected = FALSE;
	SetCommMask( m_hComm, 0);
	PurgeComm( m_hComm,					
		PURGE_TXABORT | PURGE_TXCLEAR | PURGE_RXABORT | PURGE_RXCLEAR);
	CloseHandle( m_hComm);
}

// 포트에 pBuff의 내용을 nToWrite만큼 쓴다.
// 실제로 쓰여진 Byte수를 리턴한다.
DWORD CCommThread::WriteComm(BYTE *pBuff, DWORD nToWrite)
{
	DWORD	dwWritten, dwError, dwErrorFlags;
	COMSTAT	comstat;

	if (! WriteFile( m_hComm, pBuff, nToWrite, &dwWritten, &m_osWrite))
	{
		if (GetLastError() == ERROR_IO_PENDING)
		{
			// 읽을 문자가 남아 있거나 전송할 문자가 남아 있을 경우 Overapped IO의
			// 특성에 따라 ERROR_IO_PENDING 에러 메시지가 전달된다.
			//timeouts에 정해준 시간만큼 기다려준다.
			while (! GetOverlappedResult( m_hComm, &m_osWrite, &dwWritten, TRUE))
			{
				dwError = GetLastError();
				if (dwError != ERROR_IO_INCOMPLETE)
				{
					ClearCommError( m_hComm, &dwErrorFlags, &comstat);
					break;
				}
			}
		}
		else
		{
			dwWritten = 0;
			ClearCommError( m_hComm, &dwErrorFlags, &comstat);
		}
	}

	return dwWritten;
}

// 포트로부터 pBuff에 nToWrite만큼 읽는다.
// 실제로 읽혀진 Byte수를 리턴한다.
DWORD CCommThread::ReadComm(BYTE *pBuff, DWORD nToRead)
{
	DWORD	dwRead, dwError, dwErrorFlags;
	COMSTAT	comstat;

	//----------------- system queue에 도착한 byte수만 미리 읽는다.
	ClearCommError( m_hComm, &dwErrorFlags, &comstat);
	dwRead = comstat.cbInQue;
	READ_BUF = (int)dwRead;
	if (dwRead > 0)
	{
		if (! ReadFile( m_hComm, pBuff, nToRead, &dwRead, &m_osRead))
		{
			if (GetLastError() == ERROR_IO_PENDING)
			{
				//--------- timeouts에 정해준 시간만큼 기다려준다.
				while (! GetOverlappedResult( m_hComm, &m_osRead, &dwRead, TRUE))
				{
					dwError = GetLastError();
					if (dwError != ERROR_IO_INCOMPLETE)
					{
						ClearCommError( m_hComm, &dwErrorFlags, &comstat);
						break;
					}
				}
			}
			else
			{
				dwRead = 0;
				ClearCommError( m_hComm, &dwErrorFlags, &comstat);
			}
		}
	}

	return dwRead;
}

// 포트를 감시하고, 읽힌 내용이 있으면 
// m_ReadData에 저장한 뒤에 MainWnd에 메시지를 보내어 Buffer의 내용을
// 읽어가라고 신고한다.


/*
DWORD	ThreadWatchComm(CCommThread* pComm)
{
	DWORD		dwEvent;
	OVERLAPPED	os;
	BOOL		bOk = TRUE;
	BYTE		buff[2048];	 // 읽기 버퍼
	DWORD		dwRead;	 // 읽은 바이트수.

	// Event, OS 설정.
	memset( &os, 0, sizeof(OVERLAPPED));
	if (! (os.hEvent = CreateEvent( NULL, TRUE, FALSE, NULL)))
		bOk = FALSE;
	if (! SetCommMask( pComm->m_hComm, EV_RXCHAR))
		bOk = FALSE;
	if (! bOk)
	{
		AfxMessageBox("Error while creating ThreadWatchComm, " + pComm->m_sPortName);
		return FALSE;
	}

	// 포트를 감시하는 루프.
	while (pComm->m_bConnected)
	{
		dwEvent = 0;

		// 포트에 읽을 거리가 올때까지 기다린다.
		WaitCommEvent( pComm->m_hComm, &dwEvent, NULL);
		
		if ((dwEvent & EV_RXCHAR) == EV_RXCHAR)
		{
			// 포트에서 읽을 수 있는 만큼 읽는다.
			do	
			{
				dwRead = pComm->ReadComm( buff, 2048);
				
				if (BUFF_SIZE - pComm->m_QueueRead.GetSize() > (int)dwRead)
				{
					for ( WORD i = 0; i < dwRead; i++)
						pComm->m_QueueRead.PutByte(buff[i]);
				}
				else
					AfxMessageBox("m_QueueRead FULL!");
			  
			} while (dwRead);
			//	읽어 가도록 메시지를 보낸다.
			::PostMessage(hCommWnd,WM_COMM_READ, pComm->m_wPortID, 0);
		}
	}	
	
	// 포트가 ClosePort에 의해 닫히면 m_bConnected 가 FALSE가 되어 종료.

	CloseHandle( os.hEvent);
	pComm->m_hThreadWatchComm = NULL;

	return TRUE;
}
*/