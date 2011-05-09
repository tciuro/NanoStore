#import "NanoStore.h"
#import "NanoStoreTester.h"

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NanoStoreTester *tester = [NanoStoreTester new];
    [tester test];
    [tester release];
    
    [pool drain];
    return 0;
}
