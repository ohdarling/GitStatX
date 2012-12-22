//
//  GSProjectInfoCellView.m
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-22.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import "GSProjectInfoCellView.h"

@implementation GSProjectInfoCellView

- (void)setProject:(GSProjectInfo *)project {
    _project = project;
    
    self.textField.stringValue = project.name ?: @"";
    
    NSString *typeName = project.projectType ?: @"default";
    NSString *imageName = [@"project_" stringByAppendingString:typeName];
    self.imageView.image = [NSImage imageNamed:imageName];
    
    if (project.repository) {
        pathField.stringValue = project.path ?: @"";
        branchField.stringValue = project.currentBranch ?: @"";
    } else {
        pathField.stringValue = @"Invalid Git Repository";
        pathField.textColor = [NSColor redColor];
        branchField.stringValue = @"";
    }
    
    [self.textField sizeToFit];
    [branchField sizeToFit];
}

@end
