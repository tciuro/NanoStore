//
//  RootViewController.m
//  iPhoneTest

#import "RootViewController.h"
#import "NanoStore.h"
#import "NSFNanoGlobals_Private.h"

@interface RootViewController (Private)
- (NSFNanoObject *)defaultTestData;
@end

@implementation RootViewController

@synthesize values;

#pragma mark -
#pragma mark View lifecycle

- (NSFNanoObject *)defaultTestData
{
    NSArray *dishesInfo = [NSArray arrayWithObject:@"Cassoulet"];
    NSDictionary *citiesInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Bouillabaisse", @"Marseille",
                                dishesInfo, @"Nice",
                                nil, nil];
    NSDictionary *countriesInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"Barcelona", @"Spain",
                                   @"San Francisco", @"USA",
                                   citiesInfo, @"France",
                                   nil, nil];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Tito", @"FirstName",
                          @"Ciuro", @"LastName",
                          countriesInfo, @"Countries",
                          nil, nil];
    
    return [NSFNanoObject nanoObjectWithDictionary:info];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [docs stringByAppendingPathComponent:@"nanostore.sqlite"];
    
    NSError *outError = nil;
    
    // Three ways to open a store: memory based, temporary or persistent. Use the one that suits you best.
    
    //NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:&outError];
    //NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFTemporaryStoreType path:nil error:&outError];
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFPersistentStoreType path:path error:&outError];

    // Uncomment this if you want to start with a clean database on every launch
    //[nanoStore removeAllObjectsFromStoreAndReturnError:&outError];
    
    if (nil == outError) {
        // Start with a clean model
        self.values = nil;
        
        if (YES == [nanoStore addObject:[self defaultTestData] error:&outError]) {
            if ( YES == [nanoStore saveStoreAndReturnError:&outError]) {
                // Make a search element and specify the key we want back
                NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
                //[search setKey:key];
                
                // Retrieve the data and convert the dictionaries into key -> value strings.
                NSDictionary *objects = [search searchObjectsWithReturnType:NSFReturnObjects error:&outError];
                
                // Convert the objects into an array of strings, so we can easily display them in the UI.
                NSMutableArray *cleanValues = [NSMutableArray array];
                for (NSString *key in objects) {
                    NSFNanoObject *object = [objects objectForKey:key];
                    for (NSString *key in object.info) {
                        [cleanValues addObject:[NSString stringWithFormat:@"%@ -> %@", key, [object objectForKey:key]]];
                    }
                }
                
                self.values = cleanValues;
            }
        }
        
        [nanoStore closeWithError:&outError];
    }
    
    if (nil != outError) {
        NSLog(@"Error: %@", [outError localizedDescription]);
    }
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.values.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// Configure the cell.
    cell.textLabel.text = [self.values objectAtIndex:indexPath.row];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    self.values = nil;
    [super dealloc];
}


@end

