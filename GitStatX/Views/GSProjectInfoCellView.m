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
    [_project removeObserver:self forKeyPath:@"isGeneratingStats"];
    _project = project;
    [_project addObserver:self forKeyPath:@"isGeneratingStats" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.textField.stringValue = project.name ?: @"";
    
    NSString *typeName = project.projectType ?: @"default";
    NSString *imageName = [@"project_" stringByAppendingString:typeName];
    self.imageView.image = [NSImage imageNamed:imageName];
    
    if (project.repository) {
        pathField.stringValue = project.path ?: @"";
        branchField.stringValue = project.currentBranch ?: @"";
        pathField.textColor = branchField.textColor;
    } else {
        pathField.stringValue = @"Invalid Git Repository";
        pathField.textColor = [NSColor redColor];
        branchField.stringValue = @"";
    }
    
    [self.textField sizeToFit];
    [branchField sizeToFit];
    
    [self observeValueForKeyPath:@"isGeneratingStats" ofObject:nil change:nil context:NULL];
}


- (void)generateButtonClicked:(id)sender {
    [self.project generateStats];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isGeneratingStats"]) {
        if (self.project.isGeneratingStats) {
            [progressIndicator startAnimation:nil];
            [generateButton setHidden:YES];
        } else {
            [progressIndicator stopAnimation:nil];
            [generateButton setHidden:NO];
        }
    }
}


- (void)dealloc {
    [_project removeObserver:self forKeyPath:@"isGeneratingStats"];
    [super dealloc];
}

@end
