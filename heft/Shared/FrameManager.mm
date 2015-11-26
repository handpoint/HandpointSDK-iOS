
// #include "StdAfx.h"
#include "FrameManager.h"
#include "Frame.h"
//#include "IConnection.h"
#include "../HeftConnection.h"
#include "RequestCommand.h"
#include "ResponseCommand.h"
#include "debug.h"

#import <Foundation/Foundation.h>

#include "Logger.h"
#include "Exception.h"

#include <vector>

const std::uint8_t cuiDle = 0x10;
const std::uint8_t cuiEtx = 0x03;
const std::uint8_t cuiEtb = 0x17;
/*
const std::uint8_t cuiStx = 0x02;
const std::uint8_t cuiEot = 0x04;
const std::uint8_t cuiEnq = 0x05;
const std::uint8_t cuiAck = 0x06;
const std::uint8_t cuiNak = 0x15;
 */
const int MAX_ATTEMPTS = 3;

FrameManager::FrameManager(const RequestCommand& request, int max_frame_size){
    // max_frame_size is the total frame size, i.e. the combined length of [stx] [data] [ptx/etx] [crc]
    if( max_frame_size >= ( Frame::GetMetaDataSize() + 2 ) ) // the +2 is because we need to be able to escape one DLE character into two DLE DLE
    {
        int max_data_size = max_frame_size - Frame::GetMetaDataSize();
        // you should "step" through this code using a max_data_size of 2

        std::uint8_t data_char;
	    const std::uint8_t *pSrc, *pSrcEnd;
        std::uint8_t *pDataBegin, *pData, *pDataEnd;
        std::vector<std::uint8_t> frame_data(max_data_size);

        pSrc        = request.GetData();
        pSrcEnd     = pSrc + request.GetLength();

        pDataBegin  = &frame_data[0];
        pData       = pDataBegin;
        pDataEnd    = pData + max_data_size;

        while( pSrc != pSrcEnd )
        {
            data_char = *pSrc++;
            *pData++ = data_char;

            if(data_char == cuiDle)
            {
                *pData++ = data_char;
            }

            if( ( pDataEnd - pData ) < 2 )
            {
                if( ( pDataEnd != pData ) && ( pSrc != pSrcEnd ) && ( ( data_char = *pSrc ) != cuiDle ) )
                {
                    ++pSrc;
                    *pData++ = data_char; // we have now filled the frame completely
                }
                // else the frame is full OR there is no more data OR we found a DLE at the frame boundary that we can't escape (because there is only one byte left)

                frames.push_back(Frame(pDataBegin, (int)(pData - pDataBegin), ( pSrc != pSrcEnd ) ? true : false));

                if( pSrc == pSrcEnd )
                {
                    return;
                }

                pData = pDataBegin;
            }
        }

        // we will only ever get here if we haven't constructed the last frame yet.
	    frames.push_back(Frame(pDataBegin, (int)(pData - pDataBegin), false));
    }
}

void FrameManager::Write(HeftConnection* connection){
    for(auto& frame : frames) {
		int i = 0;
		for(; i < MAX_ATTEMPTS; ++i) {
            [connection writeData:frame.GetData() length:frame.GetLength()];
            LOG_RELEASE(Logger::eFinest, frame.dump(@"Frame sent:"));
			std::uint16_t ack = [connection readAck];
			if(ack == POSITIVE_ACK) {
				LOG_RELEASE(Logger::eFinest, @"Acknowledgment received: ACK");
				break;
			}
			else if(ack == NEGATIVE_ACK) {
				LOG_RELEASE(Logger::eFinest, @"Acknowledgment received: NAK");
				continue;
			}
			LOG(@"Instead of ACK: %04x", ack);
			throw communication_exception();
		}
		if(i == MAX_ATTEMPTS) {
			[connection writeAck:SESSION_END];
			LOG(@"Session end sent");
			throw communication_exception();
		}
	}
}

void FrameManager::WriteWithoutAck(HeftConnection* connection){
	// ATLASSERT(frames.size() == 1);
    // for(vector<Frame>::iterator it = frames.begin(); it != frames.end(); ++it){
    for(auto& frame: frames){
		[connection writeData:frame.GetData() length:frame.GetLength()];
		LOG_RELEASE(Logger::eFinest, frame.dump(@"Frame sent:"));
	}
}

int FrameManager::EndPos(const std::uint8_t* pData, int pos, int len){
	for(int i = pos; i <= len - 4; ++i){
		if(pData[i] == cuiDle){
			switch(pData[i + 1]){
			case cuiDle://skip doubled DLE
				++i;
				continue;
			case cuiEtx:
			case cuiEtb:
				return i + 4;
			}
		}
	}
	return -1;
}

bool FrameManager::ReadFrames(HeftConnection* connection, std::vector<std::uint8_t>& buf){
	int pos = 0;
	do{
		std::uint8_t* pData = &buf[0];
		int len = (int)buf.size();

		int frame_len = EndPos(pData, pos, len);
		if(frame_len != -1){
			len = frame_len;
			Frame frame(pData, len);

			if(!frame.isValidCrc()){
				LOG_RELEASE(Logger::eWarning, frame.dump(@"Received invalid frame:"));
				[connection writeAck:NEGATIVE_ACK];
				LOG_RELEASE(Logger::eFinest, @"Acknowledgment sent: NAK");
				buf.erase(buf.begin(), buf.begin() + len);
				return false;
			}
			LOG_RELEASE(Logger::eFinest, frame.dump(@"Frame received:"));
			[connection writeAck:POSITIVE_ACK];
			LOG_RELEASE(Logger::eFinest, @"Acknowledgment sent: ACK");

			//remove DLE doubles
			data.reserve(data.size() + len - Frame::ciMinSize);
			for(int j = 2; j < len - 4; ++j){
				data.push_back(pData[j]);
				if(pData[j] == cuiDle)
					++j;
			}

			if(!frame.isPartial()){
				// ATLASSERT(buf.size() == len);
				break;
			}

			buf.erase(buf.begin(), buf.begin() + len);
			pos = 0;
			if(buf.size())
				continue;
		}
		else
			pos = std::max(static_cast<int>(buf.size()) - 4, 0);

		[connection readData:buf timeout:eResponseTimeout];
	}while(true);

	return true;
}

ResponseCommand* FrameManager::Read(HeftConnection* connection, bool finance_timeout) {
    FramePayload* pCommand;
    int nread;
	std::vector<std::uint8_t> buf;
	data.clear();
	while(true){
        if(buf.size() < sizeof(pCommand->StartSequence))
        {
            nread = [connection readData:buf timeout:finance_timeout ? eFinanceTimeout : eResponseTimeout];
            if(!nread) {
                if(finance_timeout)
                    throw timeout4_exception();
                else
                    throw timeout2_exception();
            }
            if(nread < sizeof(pCommand->StartSequence))
            {
                // this is not an error ...
                // ... it just means that more bytes are required
                LOG(@"FrameManager::Read I need more data. Read size: %i  Read bytes: %02X",nread,buf[0]);
                continue;
            }
        }
        else
        {
            nread = (int)buf.size();
        }
		pCommand = reinterpret_cast<FramePayload*>(&buf[0]);
		switch(pCommand->StartSequence){
		case FRAME_START:
			if(ReadFrames(connection, buf/*, bCancel*/))
				return ResponseCommand::Create(data);
			break;
		case SESSION_END:
			LOG(@"FrameManager::Read SESSION_END");
			throw connection_broken_exception();
		case POSITIVE_ACK:
			LOG_RELEASE(Logger::eWarning, @"Acknowledgement received instead of data frame, this is only OK in case of transaction cancelling");
			buf.erase(buf.begin(), buf.begin() + sizeof(pCommand->StartSequence));
			continue;
		case NEGATIVE_ACK:
			LOG(@"FrameManager::Read NEGATIVE_ACK");
		case POLLING_SEQ:
		default:
			throw communication_exception();
		}
	}
	return 0;
}
