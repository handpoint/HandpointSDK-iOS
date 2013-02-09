//
//  main.m
//  headstart
//

#import "AppDelegate.h"

int main(int argc, char *argv[])
{
	@autoreleasepool {
		/*NSString* file = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"log.txt"];
		freopen([file cStringUsingEncoding:NSASCIIStringEncoding], "w+", stderr);*/
	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
	}
}
