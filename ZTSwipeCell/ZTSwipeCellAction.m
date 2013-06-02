//
//  ZTSwipeCellAction.m
//  ZTSwipeCellDemo
//
//  Created by Zdeněk Topič on 01.06.13.
//  Copyright (c) 2013 Zdenek Topic. All rights reserved.
//

#import "ZTSwipeCellAction.h"

@implementation ZTSwipeCellAction

- (id)initWithPercent:(CGFloat)percent direction:(ZTSwipeCellDirection)direction color:(UIColor *)color image:(UIImage *)image mode:(ZTSwipeCellMode)mode tag:(id)tag
{
    if(self = [super init]) {
        _percent = percent;
        if(direction == ZTSwipeCellDirectionCenter || direction == 0)
            [NSException raise:NSInvalidArgumentException format:@"ZTSwipeCellAction direction can be ZTSwipeCellDirectionRight or ZTSwipeCellDirectionLeft only."];
        _direction = direction;
        _color = color;
        _image = image;
        _mode = mode;
        _tag = tag;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%f; %d]", self.percent, self.direction];
}

@end
