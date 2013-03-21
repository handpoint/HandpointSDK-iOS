//
//  SignView.m
//  iSign
//

#import "SignView.h"

@implementation SignView

CGLayerRef createLayer(CGSize size){
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef bmpContext = CGBitmapContextCreate (nil, size.width, size.height, 8,
													 0, colorSpace,
													 // this will give us an optimal BGRA format for the device:
													 (kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
	CGColorSpaceRelease(colorSpace);
	CGLayerRef result = CGLayerCreateWithContext(bmpContext, size, NULL);
	CGContextRelease(bmpContext);

	return result;
}

void initSign(CGContextRef bmpContext, CGSize size){
	CGContextSetBlendMode(bmpContext, kCGBlendModeCopy);
	CGContextSetLineWidth(bmpContext, 3);
	CGContextSetLineCap(bmpContext, kCGLineCapRound);
}

- (void)initView:(CGRect)frame{
	self.backgroundColor = [UIColor clearColor];
	
	self.layer.borderWidth = 1.;
	self.layer.borderColor = [UIColor colorWithWhite:.3 alpha:1.].CGColor;
	self.layer.cornerRadius = 8;
	
	CGSize size = frame.size;
	sign = createLayer(size);
	
	initSign(CGLayerGetContext(sign), size);
	points = [NSMutableArray new];
	paths = [NSMutableArray new];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
	if(self = [super initWithCoder:aDecoder]){
		[self initView:self.frame];
	}
    return self;
}

- (void)drawRect:(CGRect)rect{
	CGContextDrawLayerAtPoint(UIGraphicsGetCurrentContext(), CGPointZero, sign);
}

- (void)releasePaths:(int)index{
	int count = [paths count];
	for(int i = index; i < count; ++i){
		NSValue* item = [paths objectAtIndex:i];
		CGPathRef path = [item pointerValue];
		CGPathRelease(path);
	}
}

-(void)drawLineTo:(CGPoint)point{
	CGContextRef ctx = CGLayerGetContext(sign);
	//CGContextSetShouldAntialias(ctx, false);
	CGContextMoveToPoint(ctx, prev.x, prev.y);
	CGContextAddLineToPoint(ctx, point.x, point.y);
	CGContextStrokePath(ctx);
	
	//CGRect r= {fmin(prev.x, point.x) - 5, fmin(prev.y, point.y) - 5, fabs(prev.x - point.x) + 10, fabs(prev.y - point.y) + 10};
	prev = point;
	[self setNeedsDisplay];
	//[self setNeedsDisplayInRect:r];

	NSData* data = [[NSData alloc] initWithBytes:&prev length:sizeof(prev)];
	[points addObject:data];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	prev = [[touches anyObject] locationInView:self];
	//NSLog(@"touchesBegan:%d,%d", (int)prev.x, (int)prev.y);
	[points addObject:[NSData dataWithBytes:&prev length:sizeof(prev)]];
	[self drawLineTo:prev];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	[self drawLineTo:[[touches anyObject] locationInView: self]];
	//CGPoint p = [[touches anyObject] locationInView:self];
	//NSLog(@"touchesMoved:%d,%d", (int)p.x, (int)p.y);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[self releasePaths:undoIndex];
	[paths removeObjectsInRange:NSMakeRange(undoIndex, [paths count] - undoIndex)];
	
	NSUndoManager* undoManager = self.undoManager;
	[undoManager registerUndoWithTarget:self selector:@selector(undoSign:) object:[NSNumber numberWithInt:undoIndex]];
	[undoManager setActionName:@"sign"];
	
	CGMutablePathRef path = CGPathCreateMutable();
	NSData* item = [points objectAtIndex:0];
	const CGPoint* pPoint = [item bytes];
	CGPathMoveToPoint(path, NULL, pPoint->x, pPoint->y);
	for(int i = 1; i < [points count]; ++i){
		item = [points objectAtIndex:i];
		pPoint = [item bytes];
		CGPathAddLineToPoint(path, NULL, pPoint->x, pPoint->y);
	}
	[paths addObject:[NSValue valueWithPointer:path]];
	++undoIndex;

	[points removeAllObjects];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
	[self touchesEnded:touches withEvent:event];
}

#pragma mark property

- (BOOL)dirty{
	return !CGPointEqualToPoint(prev, CGPointZero);
}

- (UIImage*)image{
	CGRect frame = self.frame;
	UIGraphicsBeginImageContext(frame.size);
	//[self drawRect:frame];
	CGContextDrawLayerAtPoint(UIGraphicsGetCurrentContext(), CGPointZero, sign);
	UIImage* signImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return signImage;
}

- (void)undoSign:(NSNumber*)index{
	undoIndex = [index intValue];
	CGContextRef ctx = CGLayerGetContext(sign);
	CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
	CGRect bounds = self.bounds;
	CGContextFillRect(ctx, bounds);

	int i = 0;
	for(NSValue* item in paths){
		if(i++ >= undoIndex)
			break;
		CGPathRef path = [item pointerValue];
		CGContextAddPath(ctx, path);
	}
	CGContextStrokePath(ctx);

	[self setNeedsDisplay];

	NSUndoManager* undoManager = self.undoManager;
	int intForRegister = undoIndex;
	if([undoManager isUndoing])
		++intForRegister;
	else
		--intForRegister;
	[undoManager registerUndoWithTarget:self selector:@selector(undoSign:) object:[NSNumber numberWithInt:intForRegister]];
}

@end
