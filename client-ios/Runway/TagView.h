//
//  TagView.h
//  Runway
//
//  Created by Roberto Cordon on 5/26/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tag.h"

@class TagView;
@class DownvoteReason;

@protocol TagDelegate <NSObject>
- (void)displayDownvoteReasonDialogForTag:(Tag *)tag withView:(TagView *)tagView;
- (void)displayDownvoteReasonStatsDialogForTag:(Tag *)tag withView:(TagView *)tagView;
- (void)selectedTagView:(TagView *)tagView;
- (void)editPropertiesForTag:(Tag *)tag;
- (void)deleteTag:(Tag *)tag andRemoveTagView:(TagView *)tagView;
- (void)changedVoteState;
@end

@interface TagView : UIView

@property (nonatomic) BOOL editing;
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL reveal;
@property (nonatomic, readonly) t_Vote voteState;

- (TagView *)initWithTag:(Tag *)tag
        usingScaleFactor:(CGPoint)scaleFactor
                 toFitIn:(CGSize)size
               allowEdit:(BOOL)allowEdit
             allowVoting:(BOOL)allowVoting
                delegate:(id<TagDelegate>)delegate;

- (void)setDownvoteReasonForTag:(DownvoteReason *)downvoteReason;   //nil means cancelled
- (BOOL)isTagViewForTag:(Tag *)tag;
@end
