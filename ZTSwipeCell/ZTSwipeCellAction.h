//
//  ZTSwipeCellAction.h
//  ZTSwipeCellDemo
//
//  Created by Zdeněk Topič on 01.06.13.
//  Copyright (c) 2013 Zdenek Topic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZTSwipeCellEnums.h"

@interface ZTSwipeCellAction : NSObject

@property (nonatomic, assign, readonly) CGFloat percent;
@property (nonatomic, assign, readonly) enum ZTSwipeCellDirection direction;
@property (nonatomic, copy) UIColor* color;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, assign) enum ZTSwipeCellMode mode;

@property (nonatomic, strong) id tag;

- (id)initWithPercent:(CGFloat)percent direction:(ZTSwipeCellDirection)direction color:(UIColor*)color image:(UIImage*)image mode:(ZTSwipeCellMode)mode tag:(id)tag;

@end
