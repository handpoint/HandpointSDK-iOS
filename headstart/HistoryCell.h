//
//  HistoryCell.h
//  headstart
//

@interface HistoryCell : UITableViewCell
@property(nonatomic, readonly) __weak IBOutlet UILabel *dateLabel;
@property(nonatomic, readonly) __weak IBOutlet UILabel *amountLabel;
@property(nonatomic, readonly) __weak IBOutlet UILabel *typeLabel;
@property(nonatomic, readonly) __weak IBOutlet UILabel *voidLabel;
@end
