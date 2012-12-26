//
//  GSProjectInfoCellView.h
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-22.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GSProjectInfo.h"

#import "GSProjectCellView.h"

@interface GSProjectInfoCellView : GSProjectCellView {
    IBOutlet    NSTextField         *pathField;
    IBOutlet    NSTextField         *branchField;
    IBOutlet    NSProgressIndicator *progressIndicator;
    IBOutlet    NSButton            *generateButton;
}

- (IBAction)generateButtonClicked:(id)sender;

@end
