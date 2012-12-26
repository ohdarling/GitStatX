//
//  GSProjectCellView.h
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-26.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GSProjectInfo.h"

@interface GSProjectCellView : NSTableCellView <NSTextFieldDelegate> {
    __strong GSProjectInfo      *_project;
}

@property (nonatomic, strong)   GSProjectInfo   *project;
@property (nonatomic, assign, getter = isEditing)   BOOL    editing;

@end
