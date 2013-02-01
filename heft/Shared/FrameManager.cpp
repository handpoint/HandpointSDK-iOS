#include "StdAfx.h"
#include "FrameManager.h"
#include "Frame.h"
//#include "IConnection.h"
#import "HeftConnection.h"
#include "RequestCommand.h"
#include "ResponseCommand.h"

const UINT8 cuiDle = 0x10;
const UINT8 cuiEtx = 0x03;
const UINT8 cuiEtb = 0x17;
const UINT8 cuiStx = 0x02;
const UINT8 cuiEot = 0x04;
const UINT8 cuiEnq = 0x05;
const UINT8 cuiAck = 0x06;
const UINT8 cuiNak = 0x15;
const int ciMaxAttempts = 3;

FrameManager::FrameManager(const RequestCommand& request, int max_frame_size){
	max_frame_size -= Frame::ciMinSize;
	const UINT8* pBuf = request.GetData();
	int len = request.GetLength();
	vector<UINT8> data(len);
	vector<UINT8>::iterator pDest = data.begin();
	// DLE doubling
	int iDoubledDleCount = 0;
	for(int i = 0; i < len; ++i){
		UINT8 data_char = *pBuf++;
		*pDest++ = data_char;
		if(data_char == cuiDle){
			pDest = data.insert(pDest, data_char);
			++pDest;
			++iDoubledDleCount;
		}
	}
	len += iDoubledDleCount;

	//splitting
	pBuf = &data[0];
	while(len > max_frame_size){
		frames.push_back(Frame(pBuf, max_frame_size, true));
		pBuf += max_frame_size;
		len -= max_frame_size;
	}
	frames.push_back(Frame(pBuf, len, false));
}

void FrameManager::Write(HeftConnection* connection/*, volatile bool& bCancel*/){
	for(vector<Frame>::iterator it = frames.begin(); it != frames.end(); ++it){
		int i = 0;
		for(; i < ciMaxAttempts; ++i){
			//if(bCancel)
			//	return;

			[connection writeData:it->GetData() length:it->GetLength()];
			LOG_RELEASE(Logger::eFinest, it->dump(_T("Frame sent:")));
			UINT16 ack = [connection readAck];
			if(ack == POSITIVE_ACK){
				LOG_RELEASE(Logger::eFinest, _T("Acknowledgment received: ACK"));
				break;
			}
			else if(ack == NEGATIVE_ACK){
				LOG_RELEASE(Logger::eFinest, _T("Acknowledgment received: NAK"));
				continue;
			}
			LOG(_T("Instead of ACK: %04x"), ack);
			throw communication_exception();
		}
		if(i == ciMaxAttempts){
			[connection writeAck:SESSION_END];
			LOG(_T("Session end sent"));
			throw communication_exception();
		}
	}
}

void FrameManager::WriteWithoutAck(HeftConnection* connection/*, volatile bool& bCancel*/){
	ATLASSERT(frames.size() == 1);
	for(vector<Frame>::iterator it = frames.begin(); it != frames.end(); ++it){
		[connection writeData:it->GetData() length:it->GetLength()];
		LOG_RELEASE(Logger::eFinest, it->dump(_T("Frame sent:")));
	}
}

int FrameManager::EndPos(const UINT8* pData, int pos, int len){
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

bool FrameManager::ReadFrames(HeftConnection* connection, vector<UINT8>& buf){
	int pos = 0;
	do{
		UINT8* pData = &buf[0];
		int len = buf.size();

		int frame_len = EndPos(pData, pos, len);
		if(frame_len != -1){
			len = frame_len;
			Frame frame(pData, len);

			if(!frame.isValidCrc()){
				LOG_RELEASE(Logger::eWarning, frame.dump(_T("Received invalid frame:")));
				[connection writeAck:NEGATIVE_ACK];
				LOG_RELEASE(Logger::eFinest, _T("Acknowledgment sent: NAK"));
				buf.erase(buf.begin(), buf.begin() + len);
				return false;
			}
			LOG_RELEASE(Logger::eFinest, frame.dump(_T("Frame received:")));
			[connection writeAck:POSITIVE_ACK];
			LOG_RELEASE(Logger::eFinest, _T("Acknowledgment sent: ACK"));

			//remove DLE doubles
			data.reserve(data.size() + len - Frame::ciMinSize);
			for(int j = 2; j < len - 4; ++j){
				data.push_back(pData[j]);
				if(pData[j] == cuiDle)
					++j;
			}
			
			if(!frame.isPartial()){
				ATLASSERT(buf.size() == len);
				break;
			}

			buf.erase(buf.begin(), buf.begin() + len);
			pos = 0;
			if(buf.size())
				continue;
		}
		else
			pos = std::max(static_cast<int>(buf.size()) - 4, 0);

		//connection.Read(buf, eResponseTimeout);
		[connection readData:buf timeout:eResponseTimeout];
	}while(true);
	//}while(!bCancel);

	return true;
	//return !bCancel;
}

ResponseCommand* FrameManager::Read(HeftConnection* connection, bool finance_timeout){
	vector<UINT8> buf;
	data.clear();
	while(true){
	//while(!bCancel){
		//int nread = connection.Read(buf, finance_timeout ? eFinanceTimeout : eResponseTimeout);
		int nread = [connection readData:buf timeout:finance_timeout ? eFinanceTimeout : eResponseTimeout];
		if(!nread){
			if(finance_timeout)
				throw timeout4_exception();
			else
				throw timeout2_exception();
		}
		FramePayload* pCommand = reinterpret_cast<FramePayload*>(&buf[0]);
		ATLASSERT(nread >= sizeof(pCommand->StartSequence));
		if(nread < sizeof(pCommand->StartSequence))
			throw communication_exception();
		switch(pCommand->StartSequence){
		case FRAME_START:
			if(ReadFrames(connection, buf/*, bCancel*/))
				return ResponseCommand::Create(data);
			break;
		case SESSION_END:
			LOG(_T("FrameManager::Read SESSION_END"));
			throw connection_broken_exception();
		case POSITIVE_ACK:
			LOG_RELEASE(Logger::eWarning, _T("Acknowledgement received instead of data frame, this is only OK in case of transaction cancelling"));
			buf.erase(buf.begin(), buf.begin() + sizeof(pCommand->StartSequence));
			continue;
		case NEGATIVE_ACK:
			LOG(_T("FrameManager::Read NEGATIVE_ACK"));
		case POLLING_SEQ:
		default:
			throw communication_exception();
		}
	}
	return 0;
}
