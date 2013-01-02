#pragma once

class BCDCoder{
public:
	static void Encode(const char* const pStr, UINT8* pBuf, int size);
	static string Decode(const UINT8* pBuf, int size);
};
