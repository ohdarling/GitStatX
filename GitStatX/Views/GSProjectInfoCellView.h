//
//  GSProjectInfoCellView.h
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-22.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GSProjectInfo.h"

@interface GSProjectInfoCellView : NSTableCellView {
    IBOutlet    NSTextField         *pathField;
    IBOutlet    NSTextField         *branchField;
}

@property (nonatomic, strong)   GSProjectInfo   *project;

@end
