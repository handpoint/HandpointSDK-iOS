#pragma once

#include <exception>

class heft_exception : public std::exception
{
public:
	virtual NSString* stringId() = 0;
};

class timeout1_exception : public heft_exception{
public:
	virtual NSString* stringId(){return @"Timeout on ack";} // thrown if more than 20s pass while waiting for a DLE ACK sequence from the card reader
};

class timeout2_exception : public heft_exception{
public:
	virtual NSString* stringId(){return @"Timeout on response";} // thrown if more than 15s or 1s pass while waiting for data from the card reader
};

class timeout4_exception : public heft_exception{
public:
	virtual NSString* stringId(){return @"Timeout on finance request";} // thrown if more than 45s pass while waiting for a financial response from the card reader
    // note that this is a generic limitation of the iOS SDK such that if the card reader is busy with something (such as waiting for card holder input) then the SDK will give up after 45s
};

class communication_exception : public heft_exception{
public:
    communication_exception() { message = @""; }
    communication_exception(NSString* msg) {message = msg;}
    ~communication_exception() { message = nil; }
    
	virtual NSString* stringId(){return [NSString stringWithFormat:@"Communication error <%@>", message];} // thrown if corruption is detected during communication
private:
    NSString* message;
};

class connection_broken_exception : public heft_exception{
public:
	virtual NSString* stringId(){return @"Connection broken";} // thrown if the card reader send a DLE EOT sequence
};
