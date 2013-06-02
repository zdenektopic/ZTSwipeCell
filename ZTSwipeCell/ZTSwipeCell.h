//
//  ZTSwipeCell.h
//  ZTSwipeCell
//
//  Created by Zdeněk Topič on 21.04.13.
//  Copyright (c) 2013 Zdenek Topic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZTSwipeCellAction.h"

@class ZTSwipeCell;

@protocol ZTSwipeCellDelegate <NSObject>

- (NSArray*)actionsForSwipeCell:(ZTSwipeCell*)cell;

@optional
- (void)swipeCell:(ZTSwipeCell*)cell possibleAction:(ZTSwipeCellAction*)action previous:(ZTSwipeCellAction*)previous;
- (void)swipeCell:(ZTSwipeCell *)cell willTriggerAction:(ZTSwipeCellAction*)action;
- (void)swipeCell:(ZTSwipeCell *)cell didTriggerAction:(ZTSwipeCellAction *)action;
- (void)swipeCellDidBeginSwipe:(ZTSwipeCell *)cell;
- (void)swipeCellDidEndSwipe:(ZTSwipeCell *)cell success:(BOOL)success;
- (void)swipeCell:(ZTSwipeCell *)cell didChangeDirection:(ZTSwipeCellDirection)direction;

@end

@interface ZTSwipeCell : UITableViewCell

@property (nonatomic, strong) UIView* sliderView;
@property (nonatomic, assign) id<ZTSwipeCellDelegate> delegate;
@property (nonatomic, assign) BOOL overrideCancelWithEnd;
@property (nonatomic, assign) enum ZTSwipeCellEdgeBehavior innerEdgeBehavior;
@property (nonatomic, assign) enum ZTSwipeCellEdgeBehavior outerEdgeBehavior;
@property (nonatomic, assign) CGFloat animationDuration;
@property (nonatomic, assign) CGFloat imageMargin;

@property (nonatomic, assign) enum ZTSwipeCellSwitchMode switchMode;

@end
