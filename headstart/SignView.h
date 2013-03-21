//
//  SignView.h
//  iSign
//

@interface SignView : UIView{
	CGPoint prev;
	CGLayerRef sign;
	NSMutableArray* points;
	NSMutableArray* paths;
	NSUInteger undoIndex;
}

@property(nonatomic, readonly) BOOL dirty;
@property(nonatomic, readonly) UIImage* image;

@end