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

@property (nonatomic, assign) CGRect originalFrame;
@property (nonatomic, strong) UIView* sliderBackgroundView;
@property (nonatomic, strong) UIImageView* sliderImageView;
@property (nonatomic, strong) UIPanGestureRecognizer* panGestureRecognizer;

@property (nonatomic, weak) ZTSwipeCellAction* current;

@property (nonatomic, strong) ZTSwipeCellAnimationCallback animCallback;

- (void)initializer;

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)gesture;

- (void)triggerAction:(ZTSwipeCellAction*)action;
- (void)cancelWithAction:(ZTSwipeCellAction*)action;

- (ZTSwipeCellDirection)directionWithTranslation:(CGPoint)translation;

- (ZTSwipeCellAction*)actionWithPercentage:(CGFloat)percent inDirection:(ZTSwipeCellDirection)direction;
- (void)findTopsBottoms;

- (void)updateForAction:(ZTSwipeCellAction*)action translation:(CGPoint)translation;
- (void)prepapreSliderBackground;

- (void)tryNotifyDelagatePossibleAction:(ZTSwipeCellAction*)action previous:(ZTSwipeCellAction*)previous;
- (void)tryNotifyDelagateWillTriggerAction:(ZTSwipeCellAction *)action;
- (void)tryNotifyDelagateDidTriggerAction:(ZTSwipeCellAction *)action;
- (void)tryNotifyDelagateDidBeginSwipe;
- (void)tryNotifyDelagateDidEndSwipeSuccess:(BOOL)success;
- (void)tryNotifyDelagateDidChangeDirection:(ZTSwipeCellDirection)direction;

- (void)animateAction:(ZTSwipeCellAction*)action completion:(ZTSwipeCellAnimationCallback)callback;


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
    self.animationDuration = .5f;
    self.imageMargin = 20;
    self.switchMode = ZTSwipeCellSwitchModeFreezeImage;
    self.overrideCancelWithEnd = NO;
    self.sliderView = self.contentView;
    
    self.leftActions = [NSMutableArray new];
    self.rightActions = [NSMutableArray new];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
    self.panGestureRecognizer.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:self.panGestureRecognizer];
    self.panGestureRecognizer.delegate = self;
}

#pragma mark - Handle Gestures

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)gesture
{
    if(self.sliderView.hidden)
        return;
    CGPoint translation = [gesture translationInView:self];
    ZTSwipeCellDirection direction = [self directionWithTranslation:translation];
    CGFloat percent = fabsf(translation.x) / self.frame.size.width;
    ZTSwipeCellAction* action = [self actionWithPercentage:percent inDirection:direction];

    switch(gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.current = nil;
            [self findTopsBottoms];
            [self tryNotifyDelagateDidBeginSwipe];
            self.originalFrame = self.sliderView.frame;
            [self prepapreSliderBackground];
        case UIGestureRecognizerStateChanged:
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
        NSLog(@"%@", NSStringFromCGRect(rect));
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

- (void)prepapreSliderBackground
{
    if(!self.sliderBackgroundView)
        self.sliderBackgroundView = [UIView new];
    self.sliderBackgroundView.frame = self.originalFrame;
    self.sliderBackgroundView.backgroundColor = [UIColor clearColor];
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
    }];
}

- (void)cancelWithAction:(ZTSwipeCellAction *)action
{
    [self tryNotifyDelagateDidEndSwipeSuccess:NO];
    [self animateAction:action completion:0];
}

#pragma mark - Animations

- (void)animateAction:(ZTSwipeCellAction *)action completion:(ZTSwipeCellAnimationCallback)callback
{
    self.panGestureRecognizer.enabled = NO;
    ZTSwipeCellMode mode = action ? action.mode : ZTSwipeCellModeSwitch;
    UIViewAnimationOptions curve = mode == ZTSwipeCellModeExit ? UIViewAnimationOptionCurveLinear : UIViewAnimationOptionCurveEaseOut;
    if(mode != ZTSwipeCellModeSwitchWithBounce) {
        [UIView
         animateWithDuration:self.animationDuration
         delay:0
         options:curve
         animations:^{
             if(mode == ZTSwipeCellModeSwitch) {
                 self.sliderView.frame = self.originalFrame;
                 if(self.switchMode == ZTSwipeCellSwitchModelNormal && action && action.image) {
                     CGRect rect = self.sliderImageView.frame;
                     rect.origin.x = self.originalFrame.origin.x + self.imageMargin;
                     self.sliderImageView.frame = rect;
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
             self.panGestureRecognizer.enabled = YES;
             self.sliderView.hidden = YES;
             self.sliderView.frame = self.originalFrame;
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

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if(anim == [self.sliderView.layer animationForKey:@"ZTSwipeCellModeSwitchWithBounce"] && flag) {
        self.userInteractionEnabled = YES;
        if(self.animCallback)
            self.animCallback(flag);
        self.animCallback = nil;
    }
}

#pragma mark - Delegate notifications

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
    if (gestureRecognizer == _panGestureRecognizer) {
        UIScrollView *superview = (UIScrollView *) self.superview;
        CGPoint translation = [(UIPanGestureRecognizer *) gestureRecognizer translationInView:superview];
        
        // Make sure it is scrolling horizontally
        return ((fabsf(translation.x) / fabsf(translation.y) > 1) ? YES : NO && (superview.contentOffset.y == 0.0 && superview.contentOffset.x == 0.0));
    }
    return NO;
}

#pragma mark - Managing actions

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

- (void)addAction:(ZTSwipeCellAction*)action
{
    NSPredicate* p = [NSPredicate predicateWithFormat:@"percent = %f", action.percent];
    
    switch(action.direction) {
        case ZTSwipeCellDirectionLeft:
            if([self.leftActions filteredArrayUsingPredicate:p].count > 0)
                NSLog(@"Cell already contains action for left side with %f. Cell was not added!", action.percent);
            else
                [self.leftActions addObject:action];
            break;
        case ZTSwipeCellDirectionRight:
            if([self.rightActions filteredArrayUsingPredicate:p].count > 0)
                NSLog(@"Cell already contains action for right side with %f. Cell was not added!", action.percent);
            else
                [self.rightActions addObject:action];
            break;
        default: return;
    }
}

- (void)addActions:(NSArray*)actions
{
    for (ZTSwipeCellAction* action in actions) {
        [self addAction:action];
    }
}

- (BOOL)removeAction:(ZTSwipeCellAction*)action
{
    switch(action.direction) {
        case ZTSwipeCellDirectionLeft:
            if([self.leftActions containsObject:action]) {
                [self.leftActions removeObject:action];
                return YES;
            }
            break;
        case ZTSwipeCellDirectionRight:
            if([self.rightActions containsObject:action]) {
                [self.rightActions removeObject:action];
                return YES;
            }
            break;
        default:
            return NO;
    }
    return NO;
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

- (NSArray*)actions
{
    NSMutableArray* arr = [NSMutableArray new];
    [arr addObjectsFromArray:self.leftActions];
    [arr addObjectsFromArray:self.rightActions];
    return [NSArray arrayWithArray:arr];
}

@end

