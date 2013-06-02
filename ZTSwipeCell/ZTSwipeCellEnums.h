//
//  ZTSwipeCellEnums.h
//  ZTSwipeCellDemo
//
//  Created by Zdeněk Topič on 01.06.13.
//  Copyright (c) 2013 Zdenek Topic. All rights reserved.
//

typedef NS_ENUM(NSInteger, ZTSwipeCellMode) {
    ZTSwipeCellModeSwitch = 1,
    ZTSwipeCellModeSwitchWithBounce = 2,
    ZTSwipeCellModeExit = 4,
};

typedef NS_ENUM(NSInteger, ZTSwipeCellSwitchMode) {
    ZTSwipeCellSwitchModeFreezeImage = 1,
    ZTSwipeCellSwitchModeNormal = 2,
    ZTSwipeCellSwitchModeOrigin = 3
};

typedef NS_ENUM(NSInteger, ZTSwipeCellDirection) {
    ZTSwipeCellDirectionCenter = 0,
    ZTSwipeCellDirectionLeft,
    ZTSwipeCellDirectionRight = 2
};

typedef NS_ENUM(NSInteger, ZTSwipeCellEdgeBehavior) {
    ZTSwipeCellEdgeBehaviorNormal = 0,
    ZTSwipeCellEdgeBehaviorElastic,
    ZTSwipeCellEdgeBehaviorNone
};