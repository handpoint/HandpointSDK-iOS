
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
BOOL stop = false;

FrameManager::FrameManager(const RequestCommand& request, int max_frame_size)
{
    
    stop = false;
    // max_frame_size is the total frame size, i.e. the combined length of [stx] [data] [ptx/etx] [crc]
    if( max_frame_size >= ( Frame::GetMetaDataSize() + 2 ) ) // the +2 is because we need to be
                                                             // able to escape one DLE character into two DLE DLE
    {
        int max_data_size = max_frame_size - Frame::GetMetaDataSize();
        // you should "step" through this code using a max_data_size of 2

        const std::uint8_t* pSrc        = request.GetData();
        const std::uint8_t* pSrcEnd     = pSrc + request.GetLength();

        std::vector<std::uint8_t> frame_data(max_data_size);
        std::uint8_t* pDataBegin  = &frame_data[0];
        std::uint8_t* pData       = pDataBegin;
        std::uint8_t* pDataEnd    = pData + max_data_size;


        while( pSrc != pSrcEnd )
        {
            std::uint8_t data_char = *pSrc++;
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

/*
// a copy constructor
FrameManager::FrameManager(const FrameManager& other)
    : frames(other.frames), data(other.data)
{
    LOG(@"FrameManager::FrameManager(const FrameManager& other)");
}

FrameManager& FrameManager::operator= (const FrameManager& other)
{
    LOG(@"FrameManager& FrameManager::operator= (const FrameManager& other)");
    if (this != &other)
    {
        frames = other.frames;
        data = other.data;
    }
    return *this;
}

FrameManager::FrameManager(FrameManager&& other)
    : frames(std::move(other.frames)), data(std::move(other.data))
{
    LOG(@"FrameManager::FrameManager(FrameManager&& other)");
}


FrameManager::~FrameManager()
{
    LOG(@"FrameManager::~FrameManager()");
}
*/

void FrameManager::TearDown()
{
    stop = true;
}

void FrameManager::Write(HeftConnection* connection)
{
    stop = false;
    for(auto& frame : frames) {
		int i = 0;
        
        // TODO: refactor and remove the retries - the writeData method
        //       should always work - even though that data is not written
        //       immediately. The retries are waiting for a ACK instead
        //       of a NAK - but is that good? Will we ever get a NAK but then
        //       later an ACK for the same Frame?
        
        // this code is syncrounous, that is, one write, then a read waiting
        // for an ack. Should use GCD and a serial queue.
		for(; i < MAX_ATTEMPTS; ++i) {
            [connection writeData:frame.GetData() length:frame.GetLength()];
            // LOG_RELEASE(Logger::eFinest, frame.dump(@"Frame sent:"));
			std::uint16_t ack = [connection readAck];
			if(ack == POSITIVE_ACK) {
				LOG_RELEASE(Logger::eFinest, @"Acknowledgment received: ACK");
				break;
			}
			else if(ack == NEGATIVE_ACK) {
				LOG_RELEASE(Logger::eFinest, @"Acknowledgment received: NAK");
				continue;
			}
            NSString* message = [NSString stringWithFormat:@"Instead of ACK: %04x", ack];
            LOG(@"%@", message);
			throw communication_exception(message);
		}
		if(i == MAX_ATTEMPTS) {
			[connection writeAck:SESSION_END];
			LOG(@"Session end sent");
			throw communication_exception(@"Session end sent");
		}        
	}
}

void FrameManager::WriteWithoutAck(HeftConnection* connection){
    stop = false;
	// ATLASSERT(frames.size() == 1);
    for(auto& frame: frames)
    {
		[connection writeData:frame.GetData() length:frame.GetLength()];
		LOG_RELEASE(Logger::eFinest, frame.dump(@"Frame sent:"));
	}
}

int FrameManager::EndPos(const std::uint8_t* pData, int pos, int len){
    for(int i = pos; i <= len - 4; ++i)
    {
		if(pData[i] == cuiDle)
        {
			switch(pData[i + 1])
            {
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
    stop = false;
	do{
		std::uint8_t* pData = &buf[0];
		int len = (int)buf.size();

		int frame_len = EndPos(pData, pos, len);
		if(frame_len != -1)
        {
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
                if (stop) {
                    break;
                }
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
        {
            pos = std::max(static_cast<int>(buf.size()) - 4, 0);
        }

		[connection readData:buf timeout:eResponseTimeout];
	} while(true && !stop);

	return true;
}

ResponseCommand* FrameManager::Read(HeftConnection* connection, bool finance_timeout) {
    FramePayload* pCommand;
    int nread;
	std::vector<std::uint8_t> buf;
    buf.reserve(8192); // reserve a "big" buffer since we can afford it - and because reasons!
	data.clear();
    stop = false;
    while(true && !stop)
    {
        while((buf.size() < sizeof(pCommand->StartSequence)) && !stop)
        {
            nread = [connection readData:buf timeout:finance_timeout ? eFinanceTimeout : eResponseTimeout];
            LOG(@"FrameManager::Read, got %d bytes from readData", nread);
            if(!nread) {
                if(finance_timeout)
                    throw timeout4_exception();
                else
                    throw timeout2_exception();
            }
        }
		pCommand = reinterpret_cast<FramePayload*>(&buf[0]);
        switch(pCommand->StartSequence){
		case FRAME_START:
            LOG(@"FrameManager::Read FRAME_START");
			if(ReadFrames(connection, buf))
            {
            	return ResponseCommand::Create(data);
            }
            else
            {
                LOG(@"FrameManager::Read FRAME_START, ReadFrames failed. Nothing done.");
                // what if readFrames fails? At least log it.
            }
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
			throw communication_exception(@"pCommand->StartSequence POLLING_SEQ or default case.");
		}
	}
    
	return 0;
}
