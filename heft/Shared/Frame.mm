// #include "stdafx.h"
#include "Frame.h"
#include "Crc.h"
#include "debug.h"

#import <Foundation/Foundation.h>


#include "Exception.h"
#include "Logger.h"

#include <cstdint>

Frame::Frame(const std::uint8_t* pData, int len, bool partial) : write_data(ciMinSize + len), bPartial(partial), m_pData(0), m_len(0){
	FramePayload* pFrame = GetPayload<FramePayload>();
	pFrame->StartSequence = FRAME_START;

	memcpy(&pFrame->iCommand, pData, len);

	std::uint16_t etx = bPartial ? FRAME_PARTIAL_END : FRAME_END;
	memcpy(&pFrame->iCommand + len, &etx, sizeof etx);

	AddCRC();
}

Frame::Frame(const std::uint8_t* pData, int len) : m_pData(pData), m_len(len){
	if(len < ciMinSize){
		LOG(@"Frame less than min size");
		throw communication_exception();
	}
	// const FrameEndPayload* pFrameEnd = GetEndPayload();
	//if(pFrameEnd->EndSequence != FRAME_END && pFrameEnd->EndSequence != FRAME_PARTIAL_END) throw;
	// ATLASSERT(pFrameEnd->EndSequence == FRAME_END || pFrameEnd->EndSequence == FRAME_PARTIAL_END);
}

void Frame::AddCRC(){
	FramePayload* pFrame = GetPayload<FramePayload>();
	std::uint16_t crc = htons(CRC::CalcCRC(&pFrame->iCommand, write_data.size() - sizeof(pFrame->StartSequence) - sizeof(crc)));
	std::uint8_t* pCrc = &write_data[write_data.size() - sizeof crc];
	memcpy(pCrc, &crc, sizeof crc);
}

bool Frame::isValidCrc(){
	const FramePayload* pFrame = reinterpret_cast<const FramePayload*>(m_pData);
	std::uint16_t crc = htons(CRC::CalcCRC(&pFrame->iCommand, m_len - sizeof(pFrame->StartSequence) - sizeof(crc)));
	return crc == GetEndPayload()->crc;
}

//#ifdef HEFT_EXPORTS
NSString* Frame::dump(NSString* prefix)const{
	const std::uint8_t* pBegin = m_pData;
	int len = m_len;
	if(!pBegin){
		pBegin = &write_data[0];
		len = (int)write_data.size();
	}
	return ::dump(prefix, pBegin, len);
}
//#endif
