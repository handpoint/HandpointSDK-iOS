//
//  XmlViewController.m
//  headstart
//

#import "XmlViewController.h"

@implementation XmlViewController

@synthesize keysXmlInfo, xmlInfo;

- (void)viewDidLoad
{
    [super viewDidLoad];
    keysXmlInfo = xmlInfo.allKeys;
 }

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return [xmlInfo count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	static NSString* const kCellIdentifier = @"DefaultCell";
	
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	
    cell.textLabel.text = keysXmlInfo[indexPath.row];
    cell.detailTextLabel.text = xmlInfo[keysXmlInfo[indexPath.row]];
    
   	return cell;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Details of the transaction:";
}

#pragma mark -
#pragma mark IBAction

- (IBAction)close:(id)sender {
       [self dismissViewControllerAnimated:YES completion:nil];
}



@end
