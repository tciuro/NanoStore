#import <Foundation/Foundation.h>
#import "NanoStore.h"

void importDataUsingNanoStore(NSDictionary *iTunesInfo);

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    NSString *iTunesXMLPath = @"~/Music/iTunes/iTunes Music Library.xml";
    NSUInteger executionResult = 0;
    
    if (argc > 1) {
        iTunesXMLPath = [NSString stringWithUTF8String:argv[1]];
    }
    
    // Expand the tilde
    iTunesXMLPath = [iTunesXMLPath stringByExpandingTildeInPath];
    
    // Read the iTunes XML plist
    NSFileManager *fm = [NSFileManager defaultManager];
    if (YES == [fm fileExistsAtPath:iTunesXMLPath]) {
        NSDictionary *iTunesInfo = [NSDictionary dictionaryWithContentsOfFile:iTunesXMLPath];
        NSUInteger numOfTracks = [[iTunesInfo objectForKey:@"Tracks"]count];
        
        NSLog(@"There are %ld items in the iTunes XML file", numOfTracks);
        
        importDataUsingNanoStore(iTunesInfo);

    } else {
        executionResult = 1;
        NSLog(@"The file iTunes XML file doesn't exist at path: %@", iTunesXMLPath);
    }
    
    [pool drain];
    return executionResult;
}

void importDataUsingNanoStore(NSDictionary *iTunesInfo)
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    // Configure NanoStore
    NSFSetIsDebugOn(YES);
    NSUInteger saveInterval = 1000;
    [nanoStore setSaveInterval:saveInterval];

    NSDictionary *tracks = [iTunesInfo objectForKey:@"Tracks"];
    NSDate *startStoringDate = [NSDate date];
    NSMutableArray *keys = [NSMutableArray arrayWithCapacity:[tracks count]];
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSUInteger iterations = 0;
    
    for (NSString *trackID in tracks) {
        // Generate an empty NanoObject
        NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:[tracks objectForKey:trackID]];
        
        [keys addObject:object.key];
        
        // Collect the object
        [nanoStore addObject:object error:nil];
        iterations++;
        
        // Drain the memory every 'saveInterval' iterations
        if (0 == iterations%saveInterval) {
            [pool drain];
            pool = [NSAutoreleasePool new];
        }
    }
    
    // Don't forget that some objects could be lingering in memory. Force a save.
    [nanoStore saveStoreAndReturnError:nil];
    
    NSTimeInterval secondsStoring = [[NSDate date]timeIntervalSinceDate:startStoringDate];
    NSLog(@"Done importing. Storing the objects took %.3f seconds.", secondsStoring);
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    NSUInteger numImportedItems = [[search aggregateOperation:NSFCount onAttribute:@"Track ID"]longValue];
    NSLog(@"Number of items imported: %ld", numImportedItems);
    
    startStoringDate = [NSDate date];
    [nanoStore removeObjectsWithKeysInArray:keys error:nil];
    secondsStoring = [[NSDate date]timeIntervalSinceDate:startStoringDate];
    NSLog(@"Done removing. Removing the objects took %.3f seconds.", secondsStoring);
    
    [pool drain];
    
    // Close the document store
    [nanoStore closeWithError:nil];
}