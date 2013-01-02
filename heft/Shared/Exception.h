#pragma once

class heft_exception : public exception{
public:
	virtual NSString* stringId() = 0;
};

class timeout1_exception : public heft_exception{
public:
	virtual NSString* stringId(){return @"Timeout on ack";}
};

class timeout2_exception : public heft_exception{
public:
	virtual NSString* stringId(){return @"Timeout on response";}
};

class timeout4_exception : public heft_exception{
public:
	virtual NSString* stringId(){return @"Timeout on finance request";}
};

class communication_exception : public heft_exception{
public:
	virtual NSString* stringId(){return @"Communication error";}
};

class connection_broken_exception : public heft_exception{
public:
	virtual NSString* stringId(){return @"Connection broken";}
};
