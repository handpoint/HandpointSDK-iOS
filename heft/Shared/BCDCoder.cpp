#include "StdAfx.h"
#include "BCDCoder.h"

void BCDCoder::Encode(const PCSTR pStr, UINT8* pBuf, int size){
	ATLASSERT(!size || pBuf);
	PCSTR p = pStr;
	for(int i = 0; i < size; ++i){
		unsigned char c_hi = (*p++ - '0') & 0x0f;
		unsigned char c_lo = *p ? (*p++ - '0') & 0x0f : 0;
		pBuf[i] = c_hi << 4 | c_lo;
	}
}

string BCDCoder::Decode(const UINT8* pBuf, int size){
	ATLASSERT(!size || pBuf);
	string result;
	const UINT8* p = pBuf;
	for(int i = 0; i < size; ++i){
		unsigned char c_hi = (*p >> 4) + '0';
		unsigned char c_lo = (*p++ & 0x0f) + '0';
		result += c_hi;
		result += c_lo;
	}
	return result;
}
