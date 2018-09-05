#pragma once

class RequestCommand;
class ConnectRequestCommand;
class SendRequestCommand;
class PostRequestCommand;
class ReceiveRequestCommand;
class DisconnectRequestCommand;
class SignatureRequestCommand;
class ChallengeRequestCommand;

@protocol IHostProcessor

- (RequestCommand*)processConnect:(ConnectRequestCommand*)pRequest;
- (RequestCommand*)processSend:(SendRequestCommand*)pRequest;
- (RequestCommand*)processPost:(PostRequestCommand*)pRequest;
- (RequestCommand*)processReceive:(ReceiveRequestCommand*)pRequest;
- (RequestCommand*)processDisconnect:(DisconnectRequestCommand*)pRequest;
- (RequestCommand*)processSignature:(SignatureRequestCommand*)pRequest;
- (RequestCommand*)processChallenge:(ChallengeRequestCommand*)pRequest;

@end


class IRequestProcess{
public:
	virtual RequestCommand* Process(id<IHostProcessor> handler) = 0;
};
