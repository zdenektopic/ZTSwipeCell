//
//  ZTSwipeCell.m
//  ZTSwipeCell
//
//  Created by Zdeněk Topič on 21.04.13.
//  Copyright (c) 2013 Zdenek Topic. All rights reserved.
//

#import "ZTSwipeCell.h"
#import <QuartzCore/QuartzCore.h>

typedef void (^ZTSwipeCellAnimationCallback)(BOOL finished);

@interface ZTSwipeCell () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray* leftActions;
@property (nonatomic, strong) ZTSwipeCellAction* leftTopAction;
@property (nonatomic, strong) ZTSwipeCellAction* leftBottomAction;
@property (nonatomic, strong) NSMutableArray* rightActions;
@property (nonatomic, strong) ZTSwipeCellAction* rightTopAction;
@property (nonatomic, strong) ZTSwipeCellAction* rightBottomAction;

@property (nonatomic, assign) CGRect sliderOriginalFrame;
@property (nonatomic, strong) UIView* sliderBackgroundView;
@property (nonatomic, strong) UIImageView* sliderImageView;
@property (nonatomic, strong) UIPanGestureRecognizer* swipeCellPanGestureRecognizer;

@property (nonatomic, weak) ZTSwipeCellAction* current;
@property (nonatomic, assign) ZTSwipeCellDirection lastDirection;

//@property (nonatomic, strong) ZTSwipeCellAnimationCallback animationCallback;

- (void)initializer;

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)gesture;

- (void)triggerAction:(ZTSwipeCellAction*)action;
- (void)cancelWithAction:(ZTSwipeCellAction*)action;

- (ZTSwipeCellDirection)directionWithTranslation:(CGPoint)translation;

- (void)_addAction:(ZTSwipeCellAction*)action;
- (void)_addActions:(NSArray*)actions;
- (ZTSwipeCellAction*)actionWithPercentage:(CGFloat)percent inDirection:(ZTSwipeCellDirection)direction;
- (NSArray*)delegateGetActions;
- (void)setupActions;
- (void)findTopsBottoms; // Thats not a sex thing. I swear!

- (void)updateForAction:(ZTSwipeCellAction*)action translation:(CGPoint)translation;
- (void)prepareSliderBackground;

- (void)tryNotifyDelagatePossibleAction:(ZTSwipeCellAction*)action previous:(ZTSwipeCellAction*)previous;
- (void)tryNotifyDelagateWillTriggerAction:(ZTSwipeCellAction *)action;
- (void)tryNotifyDelagateDidTriggerAction:(ZTSwipeCellAction *)action;
- (void)tryNotifyDelagateDidBeginSwipe;
- (void)tryNotifyDelagateDidEndSwipeSuccess:(BOOL)success;
- (void)tryNotifyDelagateDidChangeDirection:(ZTSwipeCellDirection)direction;

- (void)animateAction:(ZTSwipeCellAction*)action completion:(ZTSwipeCellAnimationCallback)callback;

- (void)resetSwipeCell;


@end

@implementation ZTSwipeCell

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self initializer];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder]) {
        [self initializer];
    }
    return self;
}

- (id)init
{
    if(self = [super init]) {
        [self initializer];
    }
    
    return self;
}

#pragma mark Custom Initializer

- (void)initializer
{
    // Default values
    self.current = nil;
    self.innerEdgeBehavior = ZTSwipeCellEdgeBehaviorElastic;
    self.outerEdgeBehavior = ZTSwipeCellEdgeBehaviorNone;
    self.animationDuration = .2f;
    self.imageMargin = 20;
    self.switchMode = ZTSwipeCellSwitchModeFreezeImage;
    self.overrideCancelWithEnd = NO;
    self.sliderView = self.contentView;
    
    self.leftActions = [NSMutableArray new];
    self.rightActions = [NSMutableArray new];
    
    self.swipeCellPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
    self.swipeCellPanGestureRecognizer.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:self.swipeCellPanGestureRecognizer];
    self.swipeCellPanGestureRecognizer.delegate = self;
}

#pragma mark - Handle Gestures

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)gesture
{
    CGPoint translation = [gesture translationInView:self];
    ZTSwipeCellDirection direction = [self directionWithTranslation:translation];
    CGFloat percent = fabsf(translation.x) / self.frame.size.width;
    ZTSwipeCellAction* action = [self actionWithPercentage:percent inDirection:direction];

    switch(gesture.state) {
        case UIGestureRecognizerStateBegan:
            [self setupActions];
            [self findTopsBottoms];
            [self tryNotifyDelagateDidBeginSwipe];
            self.sliderOriginalFrame = self.sliderView.frame;
            [self prepareSliderBackground];
        case UIGestureRecognizerStateChanged:
            if(direction != self.lastDirection)
                [self tryNotifyDelagateDidChangeDirection:direction];
            self.lastDirection = direction;
            [self updateForAction:action translation:translation];
            if(action != self.current) {
                [self tryNotifyDelagatePossibleAction:action previous:self.current];
                self.current = action;
            } break;
        case UIGestureRecognizerStateCancelled:
            if(action && self.overrideCancelWithEnd)
                [self triggerAction:action];
            else
                [self cancelWithAction:action];
            break;
        case UIGestureRecognizerStateEnded:
            if(action)
                [self triggerAction:action];
            else
                [self cancelWithAction:nil];
            break;
        default:
            break;
    }
}

- (void)updateForAction:(ZTSwipeCellAction *)action translation:(CGPoint)translation
{
    // Slider view position
    CGRect rect = self.sliderView.frame;
    
    ZTSwipeCellDirection dir = action ? action.direction : [self directionWithTranslation:translation];
    
    ZTSwipeCellAction* top = dir == ZTSwipeCellDirectionLeft ? self.leftTopAction : self.rightTopAction;
    ZTSwipeCellAction* bottom = dir == ZTSwipeCellDirectionLeft ? self.leftBottomAction : self.rightBottomAction;
    
    NSArray* arr = dir == ZTSwipeCellDirectionLeft ? self.leftActions : self.rightActions;
    if(dir == ZTSwipeCellDirectionCenter) {
        rect.origin.x = 0;
    }
    
    if(!action && arr.count == 0 && self.outerEdgeBehavior == ZTSwipeCellEdgeBehaviorNone) {
        rect.origin.x = 0;
    }
    else if(!action && arr.count == 0  && self.outerEdgeBehavior == ZTSwipeCellEdgeBehaviorNormal) {
        rect.origin.x = translation.x;
    }
    else if((!action && arr.count == 0  && self.outerEdgeBehavior == ZTSwipeCellEdgeBehaviorElastic) || (action && action == top && self.innerEdgeBehavior == ZTSwipeCellEdgeBehaviorElastic)) {
        CGFloat topX = 25;
        if(action && action == top) {
            topX = top.percent * self.sliderView.frame.size.width + 25;
        }
        
        if(translation.x > topX && dir == ZTSwipeCellDirectionLeft) {
            rect.origin.x = topX + (translation.x - topX) * 0.15f;
        }
        else if(translation.x < -topX && dir == ZTSwipeCellDirectionRight) {
            rect.origin.x = -topX + (translation.x + topX) * 0.15f;
        }
        else
            rect.origin.x = translation.x;
    }
    else if(action && action == top && self.innerEdgeBehavior == ZTSwipeCellEdgeBehaviorNormal) {
        rect.origin.x = translation.x;
    }
    else if(action && action == top && self.innerEdgeBehavior == ZTSwipeCellEdgeBehaviorNone) {
        rect.origin.x = top.percent * self.sliderView.frame.size.width;
    }
    else {
        rect.origin.x = translation.x;
    }
    
    self.sliderView.frame = rect;
    
    // Lets setup image
    if((action && action.image) || (!action && bottom && bottom.image && dir != ZTSwipeCellDirectionCenter)) {
        UIImage* img = action ? action.image : (dir == ZTSwipeCellDirectionLeft ? self.leftBottomAction.image : self.rightBottomAction.image);
        
        self.sliderImageView.image = img;
        self.sliderImageView.hidden = NO;
        
        CGRect tmp = CGRectZero;
        tmp.size.width = img.size.width;
        tmp.size.height = img.size.height;
        tmp.origin.y = self.sliderBackgroundView.frame.size.height / 2 - img.size.height / 2;
        
        if(dir == ZTSwipeCellDirectionLeft && (action || (!action && translation.x >= (img.size.width + 2 * self.imageMargin)))) {
            tmp.origin.x = rect.origin.x - self.imageMargin - img.size.width;
            self.sliderImageView.alpha = 1;
        }
        else if(dir == ZTSwipeCellDirectionRight && (action || (!action && translation.x <= -(img.size.width + 2 * self.imageMargin)))) {
            tmp.origin.x = rect.origin.x + rect.size.width + self.imageMargin;
            self.sliderImageView.alpha = 1;
        }
        else if(dir == ZTSwipeCellDirectionLeft && !action && translation.x < (img.size.width + 2 * self.imageMargin)) {
            tmp.origin.x = self.imageMargin;
            self.sliderImageView.alpha = MIN(translation.x / (2 * self.imageMargin + img.size.width), 1);
        }
        else if(dir == ZTSwipeCellDirectionRight && !action && translation.x > -(img.size.width + 2 * self.imageMargin)) {
            tmp.origin.x = rect.size.width - (self.imageMargin + img.size.width);
            self.sliderImageView.alpha = MIN(-translation.x / (2 * self.imageMargin + img.size.width), 1);
        }
        
        self.sliderImageView.frame = tmp;
    }
    else {
        self.sliderImageView.image = nil;
        self.sliderImageView.hidden = YES;
    }
    
    // Background color please!
    if(action)
        self.sliderBackgroundView.backgroundColor = action.color;
    else
        self.sliderBackgroundView.backgroundColor = nil;
}

- (void)prepareSliderBackground
{
    if(!self.sliderBackgroundView)
        self.sliderBackgroundView = [UIView new];
    self.sliderBackgroundView.frame = self.sliderOriginalFrame;
    self.sliderBackgroundView.backgroundColor = nil;
    if(self.sliderBackgroundView.superview)
        [self.sliderBackgroundView removeFromSuperview];
    [self.sliderView.superview insertSubview:self.sliderBackgroundView belowSubview:self.sliderView];
    
    if(!self.sliderImageView)
        self.sliderImageView = [UIImageView new];
    if(self.sliderImageView.superview)
        [self.sliderImageView removeFromSuperview];
    [self.sliderBackgroundView addSubview:self.sliderImageView];
}

- (void)triggerAction:(ZTSwipeCellAction *)action
{
    [self tryNotifyDelagateDidEndSwipeSuccess:YES];
        [self tryNotifyDelagateWillTriggerAction:action];
    [self animateAction:action completion:^(BOOL finished) {
        [self tryNotifyDelagateDidTriggerAction:action];
        [self resetSwipeCell];
    }];
}

- (void)cancelWithAction:(ZTSwipeCellAction *)action
{
    [self tryNotifyDelagateDidEndSwipeSuccess:NO];
    [self animateAction:action completion:^(BOOL finished) {
        [self resetSwipeCell];
    }];
}

- (void)resetSwipeCell
{
    [self.rightActions removeAllObjects];
    [self.leftActions removeAllObjects];
    self.leftBottomAction = nil;
    self.leftTopAction = nil;
    self.rightBottomAction = nil;
    self.rightTopAction = nil;
    self.current = nil;
    self.lastDirection = 0;
}

#pragma mark - Animations

- (void)animateAction:(ZTSwipeCellAction *)action completion:(ZTSwipeCellAnimationCallback)callback
{
    self.swipeCellPanGestureRecognizer.enabled = NO;
    ZTSwipeCellMode mode = action ? action.mode : ZTSwipeCellModeSwitch;
    UIViewAnimationOptions curve = mode == ZTSwipeCellModeExit ? UIViewAnimationOptionCurveLinear : UIViewAnimationOptionCurveEaseOut;
    if(mode != ZTSwipeCellModeSwitchWithBounce) {
        [UIView
         animateWithDuration:self.animationDuration
         delay:0
         options:curve
         animations:^{
             if(mode == ZTSwipeCellModeSwitch) {
                 self.sliderView.frame = self.sliderOriginalFrame;
                 CGRect imgRect = self.sliderImageView.frame;
                 if(action && action.image) {
                     if(action.direction == ZTSwipeCellDirectionLeft) {
                         switch (self.switchMode) {
                             case ZTSwipeCellSwitchModeFreezeImage:
                                 break;
                             case ZTSwipeCellSwitchModeOrigin:
                                 imgRect.origin.x = self.sliderOriginalFrame.origin.x + self.imageMargin;
                                 break;
                             case ZTSwipeCellSwitchModeNormal:
                                 imgRect.origin.x = self.sliderOriginalFrame.origin.x - self.imageMargin - action.image.size.width;
                                 break;
                         }
                     }
                     else {
                         switch (self.switchMode) {
                             case ZTSwipeCellSwitchModeFreezeImage:
                                 break;
                             case ZTSwipeCellSwitchModeOrigin:
                                 imgRect.origin.x = self.sliderOriginalFrame.size.width - self.imageMargin - action.image.size.width;
                                 break;
                             case ZTSwipeCellSwitchModeNormal:
                                 imgRect.origin.x = self.sliderOriginalFrame.size.width + self.imageMargin;
                                 break;
                         }
                     }
                     self.sliderImageView.frame = imgRect;
                 }
             }
             else {
                 CGRect imgRect = self.sliderImageView.frame;
                 CGRect rect = self.sliderView.frame;
                 if(action.direction == ZTSwipeCellDirectionLeft) {
                     rect.origin.x = rect.size.width + (action.image ? action.image.size.width + self.imageMargin : 0);
                     imgRect.origin.x = rect.size.width;
                 }
                 else {
                     rect.origin.x = -rect.size.width - (action.image ? action.image.size.width + self.imageMargin : 0);
                     imgRect.origin.x = action.image ? -action.image.size.width : 0;
                 }
                 self.sliderView.frame = rect;
                 self.sliderImageView.frame = imgRect;
             }
         }
         completion:^(BOOL finished) {
             self.swipeCellPanGestureRecognizer.enabled = YES;
             self.sliderImageView.hidden = YES;
             if(mode == ZTSwipeCellModeExit) {
                 self.sliderView.hidden = YES;
                 self.sliderView.frame = self.sliderOriginalFrame;
             }
             if(callback)
                 callback(finished);
         }];
    }
    else {
        NSLog(@"Bounce animation disabled.");
        /*
        NSValue* from = [NSNumber numberWithFloat:self.sliderView.frame.origin.x];
        NSValue* to = [NSNumber numberWithFloat:self.originalFrame.origin.x];
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
        animation.fromValue = from;
        animation.toValue = to;
        animation.duration = self.animationDuration;
        animation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.5 :1.8 :.8 :0.8];
        
        animation.delegate = self;
        self.animCallback = callback;
        
        [self.sliderView.layer addAnimation:animation forKey:@"ZTSwipeCellModeSwitchWithBounce"];
        [self.sliderView.layer setValue:to forKey:@"position.x"];
         */
    }
}

/*
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if(anim == [self.sliderView.layer animationForKey:@"ZTSwipeCellModeSwitchWithBounce"] && flag) {
        self.userInteractionEnabled = YES;
        if(self.animationCallback)
            self.animationCallback(flag);
        self.animationCallback = nil;
    }
}
*/
#pragma mark - Delegate notifications

- (NSArray*)delegateGetActions
{
    if(!self.delegate)
        return [NSArray new];
    //[self.delegate ac
    return [self.delegate actionsForSwipeCell:self];
}

- (void)tryNotifyDelagatePossibleAction:(ZTSwipeCellAction *)action previous:(ZTSwipeCellAction *)previous
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(swipeCell:possibleAction:previous:)])
        [self.delegate swipeCell:self possibleAction:action previous:previous];
}

- (void)tryNotifyDelagateWillTriggerAction:(ZTSwipeCellAction *)action
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(swipeCell:willTriggerAction:)])
        [self.delegate swipeCell:self willTriggerAction:action];
}

- (void)tryNotifyDelagateDidTriggerAction:(ZTSwipeCellAction *)action
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(swipeCell:didTriggerAction:)])
        [self.delegate swipeCell:self didTriggerAction:action];
}

- (void)tryNotifyDelagateDidBeginSwipe
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(swipeCellDidBeginSwipe:)])
        [self.delegate swipeCellDidBeginSwipe:self];
}

- (void)tryNotifyDelagateDidEndSwipeSuccess:(BOOL)success
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(swipeCellDidEndSwipe:success:)])
        [self.delegate swipeCellDidEndSwipe:self success:success];
}

- (void)tryNotifyDelagateDidChangeDirection:(ZTSwipeCellDirection)direction
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(swipeCell:didChangeDirection:)])
        [self.delegate swipeCell:self didChangeDirection:direction];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.swipeCellPanGestureRecognizer) {
        if(!self.sliderView || self.sliderView.hidden) {
            return NO;
        }
        CGPoint point = [self.swipeCellPanGestureRecognizer velocityInView:self];
        return fabsf(point.x) > fabsf(point.y);
    }
    return YES;
}

#pragma mark - Managing actions

- (void)setupActions
{
    NSArray* arr = [self delegateGetActions];
    [self _addActions:arr];
}

- (ZTSwipeCellDirection)directionWithTranslation:(CGPoint)translation
{
    ZTSwipeCellDirection direction = ZTSwipeCellDirectionCenter;
    if(translation.x > 0)
        direction = ZTSwipeCellDirectionLeft;
    else if(translation.x < 0)
        direction = ZTSwipeCellDirectionRight;
    return direction;
}

- (ZTSwipeCellAction*)actionWithPercentage:(CGFloat)percent inDirection:(ZTSwipeCellDirection)direction
{
    ZTSwipeCellAction* act = nil;
    for (ZTSwipeCellAction* action in (direction == ZTSwipeCellDirectionLeft ? self.leftActions : self.rightActions)) {
        if(percent > action.percent && percent >= act.percent) {
            act = action;
        }
    }
    return act;
}

- (void)_addAction:(ZTSwipeCellAction*)action
{
    NSPredicate* p = [NSPredicate predicateWithFormat:@"percent = %f", action.percent];
    
    switch(action.direction) {
        case ZTSwipeCellDirectionLeft:
            if([self.leftActions filteredArrayUsingPredicate:p].count > 0)
                NSLog(@"Cell already contains action for left side with %f percent. Cell was not added!", action.percent);
            else
                [self.leftActions addObject:action];
            break;
        case ZTSwipeCellDirectionRight:
            if([self.rightActions filteredArrayUsingPredicate:p].count > 0)
                NSLog(@"Cell already contains action for right side with %f percent. Cell was not added!", action.percent);\
            else
                [self.rightActions addObject:action];
            break;
        default: return;
    }
}

- (void)_addActions:(NSArray*)actions
{
    for (ZTSwipeCellAction* action in actions) {
        [self _addAction:action];
    }
}

- (void)findTopsBottoms
{
    NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"percent" ascending:NO];
    NSArray* tmp = [self.leftActions sortedArrayUsingDescriptors:@[sort]];
    self.leftTopAction = tmp.count > 0 ? tmp[0] : nil;
    self.leftBottomAction = tmp.count > 0 ? [tmp lastObject] : nil;
    tmp = [self.rightActions sortedArrayUsingDescriptors:@[sort]];
    self.rightTopAction = tmp.count > 0 ? tmp[0] : nil;
    self.rightBottomAction = tmp.count > 0 ? [tmp lastObject] : nil;
}

@end

