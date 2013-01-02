#include "stdafx.h"
#include "Frame.h"
#include "Crc.h"

Frame::Frame(const UINT8* pData, int len, bool partial) : write_data(ciMinSize + len), bPartial(partial), m_pData(0), m_len(0){
	FramePayload* pFrame = GetPayload<FramePayload>();
	pFrame->StartSequence = FRAME_START;

	memcpy(&pFrame->iCommand, pData, len);

	UINT16 etx = bPartial ? FRAME_PARTIAL_END : FRAME_END;
	memcpy(&pFrame->iCommand + len, &etx, sizeof etx);

	AddCRC();
}

Frame::Frame(const UINT8* pData, int len) : m_pData(pData), m_len(len){
	if(len < ciMinSize){
		LOG(_T("Frame less than min size"));
		throw communication_exception();
	}
	const FrameEndPayload* pFrameEnd = GetEndPayload();
	//if(pFrameEnd->EndSequence != FRAME_END && pFrameEnd->EndSequence != FRAME_PARTIAL_END) throw;
	ATLASSERT(pFrameEnd->EndSequence == FRAME_END || pFrameEnd->EndSequence == FRAME_PARTIAL_END);
}

void Frame::AddCRC(){
	FramePayload* pFrame = GetPayload<FramePayload>();
	UINT16 crc = htons(CalcCRC(&pFrame->iCommand, write_data.size() - sizeof(pFrame->StartSequence) - sizeof(crc)));
	UINT8* pCrc = &write_data[write_data.size() - sizeof crc];
	memcpy(pCrc, &crc, sizeof crc);
}

bool Frame::isValidCrc(){
	const FramePayload* pFrame = reinterpret_cast<const FramePayload*>(m_pData);
	UINT16 crc = htons(CalcCRC(&pFrame->iCommand, m_len - sizeof(pFrame->StartSequence) - sizeof(crc)));
	return crc == GetEndPayload()->crc;
}

//#ifdef HEFT_EXPORTS
NSString* Frame::dump(NSString* prefix)const{
	const UINT8* pBegin = m_pData;
	int len = m_len;
	if(!pBegin){
		pBegin = &write_data[0];
		len = write_data.size();
	}
	return ::dump(prefix, pBegin, len);
}
//#endif
