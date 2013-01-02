inline int AtlHexEncodeGetRequiredLength(int nSrcLen)
{
	__int64 nRet64=2*static_cast<__int64>(nSrcLen)+1;
	ATLASSERT(nRet64 <= INT_MAX && nRet64 >= INT_MIN);
	int nRet = static_cast<int>(nRet64);
	return nRet;
}

inline bool AtlHexEncode(
	const BYTE *pbSrcData,
	int nSrcLen,
	LPSTR szDest,
	int *pnDestLen) throw()
{
	static const char s_chHexChars[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
										  'A', 'B', 'C', 'D', 'E', 'F'};

	if (!pbSrcData || !szDest || !pnDestLen)
	{
		return false;
	}
	
	if(*pnDestLen < AtlHexEncodeGetRequiredLength(nSrcLen))
	{
		ATLASSERT(false);
		return false;
	}

	int nRead = 0;
	int nWritten = 0;
	BYTE ch;
	while (nRead < nSrcLen)
	{
		ch = *pbSrcData++;
		nRead++;
		*szDest++ = s_chHexChars[(ch >> 4) & 0x0F];
		*szDest++ = s_chHexChars[ch & 0x0F];
		nWritten += 2;
	}

	*pnDestLen = nWritten;

	return true;
}

inline int AtlHexDecodeGetRequiredLength(int nSrcLen) throw()
{
	return nSrcLen/2;
}

#define ATL_HEX_INVALID ((char)(-1))

inline char AtlGetHexValue(char ch) throw()
{
	if (ch >= '0' && ch <= '9')
		return (ch - '0');
	if (ch >= 'A' && ch <= 'F')
		return (ch - 'A' + 10);
	if (ch >= 'a' && ch <= 'f')
		return (ch - 'a' + 10);
	return ATL_HEX_INVALID;
}

inline bool AtlHexDecode(
						 LPCSTR pSrcData,
						 int nSrcLen,
						 LPBYTE pbDest,
						 int* pnDestLen) throw()
{
	if (!pSrcData || !pbDest || !pnDestLen)
	{
		return FALSE;
	}
	
	if(*pnDestLen < AtlHexDecodeGetRequiredLength(nSrcLen))
	{
		ATLASSERT(FALSE);
		return FALSE;
	}
	
	int nRead = 0;
	int nWritten = 0;
	while (nRead < nSrcLen)
	{
		char ch1 = AtlGetHexValue((char)*pSrcData++);
		char ch2 = AtlGetHexValue((char)*pSrcData++);
		if ((ch1==ATL_HEX_INVALID) || (ch2==ATL_HEX_INVALID))
		{
			return FALSE;
		}
		*pbDest++ = (BYTE)(16*ch1+ch2);
		nWritten++;
		nRead += 2;
	}
	
	*pnDestLen = nWritten;
	return TRUE;
}
