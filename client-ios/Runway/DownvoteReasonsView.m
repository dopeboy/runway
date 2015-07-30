//
//  DownvoteReasonsView.m
//  Runway
//
//  Created by Roberto Cordon on 5/28/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "DownvoteReasonsView.h"
#import "Tag.h"
#import "TagView.h"
#import "DownvoteReason.h"
#import "RunwayServices.h"

#import "StringConstants.h"
#import "CommonConstants.h"

#define CURTAIN_ALPHA           0.4

#define HEADER_HEIGHT           60
#define ROW_HEIGHT              55
#define ROWS_TO_SHOW            6.5

#define DIALOG_WIDTH            330
#define DIALOG_HEIGHT           (HEADER_HEIGHT + (ROW_HEIGHT * ROWS_TO_SHOW))

#define BG_TAG                          455
#define CHOICE_CELL_IDENTIFIER          @"choiceCell"
#define STATS_CELL_IDENTIFIER           @"statsCell"


@interface DownvoteReasonsView() <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) Tag *tagObject;
@property (nonatomic, weak) TagView *tagView;

@property (nonatomic) BOOL showingStats;
@property (nonatomic, strong) NSArray *reasons;
@property (nonatomic, strong) UIColor *themeColor;

@property (nonatomic) NSInteger upvoteCount;
@property (nonatomic) NSInteger downvoteCount;
@property (nonatomic) double reasonsCount;          //double to avoid having to cast when calculating percentagee
@property (nonatomic, strong) NSDictionary *reasonStats;
@property (nonatomic, strong) NSArray *reasonStatsKeysSorted;

@property (nonatomic, weak) UITableView *table;
@end

@implementation DownvoteReasonsView

////////////////////////////////////////////////////////////////////////
//
// Getters/Setters
//
////////////////////////////////////////////////////////////////////////
#pragma mark - Getters/Setters
- (void)setReasonStats:(NSDictionary *)reasonStats
{
    _reasonStats = reasonStats;
    
    self.reasonsCount = 0;
    for(NSNumber *n in reasonStats.allValues){
        self.reasonsCount+= [n integerValue];
    }

    self.reasonStatsKeysSorted = [reasonStats.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        NSNumber *val1 = reasonStats[obj1];
        NSNumber *val2 = reasonStats[obj2];
        
        NSComparisonResult result = [val2 compare:val1];
        if(result == NSOrderedSame) result = [obj1 compare:obj2];
        return result;
    }];
}

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
+ (void)createInstanceInSuperview:(UIView *)superview
                           forTag:(Tag *)tag
                          andView:(TagView *)tagView
                        withTable:(UITableView *)table
                         andTitle:(NSString *)title
                 showingStatsOnly:(BOOL)showStats
{
    CGRect frame = CGRectZero;
    frame.size = superview.frame.size;
    
    DownvoteReasonsView *view = [[DownvoteReasonsView alloc] initWithFrame:frame
                                                                    forTag:tag
                                                                   andView:tagView
                                                                 withTable:table
                                                                  andTitle:title
                                                          showingStatsOnly:showStats];
    view.alpha = 0;
    [superview addSubview:view];
    
    [UIView animateWithDuration:ANIMATION_DURATION
                     animations:^{
                         view.alpha = 1;
                     }];
}

- (DownvoteReasonsView *)initWithFrame:(CGRect)frame
                                forTag:(Tag *)tag
                               andView:(TagView *)tagView
                             withTable:(UITableView *)table
                              andTitle:(NSString *)title
                      showingStatsOnly:(BOOL)showStats
{
    if(self = [super initWithFrame:frame]){
        self.tagObject = tag;
        self.tagView = tagView;
        self.showingStats = showStats;
        self.table = table;
        
        self.backgroundColor = [UIColor clearColor];
        
        frame.origin = CGPointZero;
        UIView *curtain = [[UIView alloc] initWithFrame:frame];
        curtain.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:CURTAIN_ALPHA];
        [curtain addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDialogGesture:)]];
        [self addSubview:curtain];

        UIView *tableContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DIALOG_WIDTH, DIALOG_HEIGHT)];
        tableContainerView.backgroundColor = [UIColor whiteColor];
        [self addSubview:tableContainerView];
        tableContainerView.center = self.center;
        
        UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, DIALOG_WIDTH, HEADER_HEIGHT - 0.5)];  //-0.5 to leave a border below
        labelTitle.font = FONT(18);
        labelTitle.text = [NSString stringWithFormat:@"    %@", title];
        labelTitle.textColor = [UIColor whiteColor];
        labelTitle.backgroundColor = [UIColor blackColor];
        [tableContainerView addSubview:labelTitle];
        
        [tableContainerView addSubview:table];
        table.frame = CGRectMake(0, HEADER_HEIGHT, DIALOG_WIDTH, DIALOG_HEIGHT - HEADER_HEIGHT);
        table.dataSource = self;
        table.delegate = self;
        table.hidden = NO;
        table.backgroundColor = [UIColor blackColor];
        table.separatorInset = self.table.layoutMargins = UIEdgeInsetsZero;
        
        dispatch_async(dispatch_queue_create("get downvote reasons", NULL), ^{
            if(self.showingStats){
                if(tag.downvoteReasons){
                    self.upvoteCount = tag.upvotes;
                    self.downvoteCount = tag.downvotes;
                    self.reasonStats = tag.downvoteReasons;
                }else{
                    //if we don't have it available, fetch it.
                    NSInteger upvoteCount;
                    NSInteger downvoteCount;
                    NSDictionary *reasonStats;
                    
                    [RunwayServices getVoteInformationForTagWithGUID:tag.GUID
                                               andStoreUpvoteCountIn:&upvoteCount
                                                     downvoteCountIn:&downvoteCount
                                                  andReasonsCountsIn:&reasonStats];
                    
                    self.upvoteCount = upvoteCount;
                    self.downvoteCount = downvoteCount;
                    self.reasonStats = reasonStats;
                }
                
                self.themeColor = ((self.upvoteCount - self.downvoteCount) >= 0) ? GREEN_COLOR : PINK_COLOR;
            }else{
                self.reasons = [DownvoteReason getTypesAndNames];
                self.themeColor = PINK_COLOR;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                tableContainerView.layer.borderWidth = 3;
                tableContainerView.layer.borderColor = self.themeColor.CGColor;
                labelTitle.backgroundColor = self.themeColor;
                table.separatorColor = self.themeColor;
                [table reloadData];
            });
        });
    }
    return self;
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
- (void)dismissDialog
{
    [UIView animateWithDuration:ANIMATION_DURATION
                     animations:^{
                         self.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         [self.table removeFromSuperview];
                         [self removeFromSuperview];
                     }];
}
#pragma mark - IBAction Handlers

////////////////////////////////////////////////////////////////////////
//
// Gesture Handlers
//
////////////////////////////////////////////////////////////////////////
#pragma mark Gesture Handlers
- (void)dismissDialogGesture:(UITapGestureRecognizer *)gesture
{
    if(!self.showingStats){
        [self.tagView setDownvoteReasonForTag:nil];
    }
    [self dismissDialog];
}

////////////////////////////////////////////////////////////////////////
//
// UITableViewDataSource Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource Implementation
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionCount = 1;
    if((self.showingStats) && (self.reasonStats.count)){
        sectionCount++;
    }
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount;
    if(self.showingStats){
        if(section == 0) {
            rowCount = 2;
        }else{
            rowCount = self.reasonStats.count;
        }
    }else{
        rowCount = self.reasons.count;
    }
    return rowCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self tableView:tableView titleForHeaderInSection:section] ? UITableViewAutomaticDimension : 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    if(self.showingStats){
        if(section == 0){
            title = [NSString stringWithFormat:STR_VOTE_COUNT_HEADER_FORMAT, (int)(self.upvoteCount + self.downvoteCount)];
        }else{
            title = STR_DOWNVOTE_REASONS_HEADER;
        }
    }
    return title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    
    UILabel *labelTitle;
    if(title){
        labelTitle = [[UILabel alloc] init];
        labelTitle.font = FONT(18);
        labelTitle.text = [NSString stringWithFormat:@"  %@", title];
        labelTitle.textColor = [UIColor whiteColor];
        labelTitle.backgroundColor = self.themeColor;
    }
    
    return labelTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *choiceCellIdentifier = CHOICE_CELL_IDENTIFIER;
    static NSString *statsCellIdentifier = STATS_CELL_IDENTIFIER;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(self.showingStats ? statsCellIdentifier : choiceCellIdentifier)
                                                            forIndexPath:indexPath];
    
    if(self.showingStats){
        if(indexPath.section == 0){
            double totalVotes = self.upvoteCount + self.downvoteCount;
            if(indexPath.row == 0){
                cell.textLabel.text = STR_UPVOTE_COUNT;
                if(totalVotes){
                    int percent = ((double)self.upvoteCount / totalVotes) * 100.0;
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%i%%", percent];
                }else{
                    cell.detailTextLabel.text = STR_NO_VOTES_CASTED;
                }
            }else{
                cell.textLabel.text = STR_DOWNVOTE_COUNT;
                if(totalVotes){
                    int percent = ((double)self.downvoteCount / totalVotes) * 100.0;
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%i%%", percent];
                }else{
                    cell.detailTextLabel.text = STR_NO_VOTES_CASTED;
                }
            }
        }else{
            //if we're here, we're guaranteed a non-zero self.reasonsCount
            NSString *reasonGUID = self.reasonStatsKeysSorted[indexPath.row];
            NSString *reasonName = [DownvoteReason getNameForDownvoteReasonWithGUID:reasonGUID];
            double reasonCount = [self.reasonStats[reasonGUID] doubleValue];
            int percent = ((100.0 * reasonCount) / self.reasonsCount);

            cell.textLabel.text = reasonName;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%i%%", percent];
        }
    }else{
        cell.textLabel.text = ((DownvoteReason *)self.reasons[indexPath.row]).name;
    }

    if(cell.selectedBackgroundView.tag != BG_TAG){
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.tag = BG_TAG;

        cell.textLabel.font = FONT(16);
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.font = FONT(16);
        cell.backgroundColor = cell.contentView.backgroundColor = tableView.backgroundColor;

        cell.separatorInset = cell.layoutMargins = UIEdgeInsetsZero;
        cell.preservesSuperviewLayoutMargins = NO;
    }
    cell.selectedBackgroundView.backgroundColor = self.themeColor;
    cell.detailTextLabel.textColor = self.themeColor;   //we do this outside, because table gets re-used and we need to re-init this value

    return cell;
}

////////////////////////////////////////////////////////////////////////
//
// UITableViewDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark UITableViewDelegate Implementation
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tagView setDownvoteReasonForTag:self.reasons[indexPath.row]];
    [self dismissDialog];
}

#pragma mark - UIView Overrides

@end
