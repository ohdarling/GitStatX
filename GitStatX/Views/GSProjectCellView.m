//
//  GSProjectCellView.m
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-26.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import "GSProjectCellView.h"

@implementation GSProjectCellView

- (void)awakeFromNib {
    self.textField.delegate = self;
}


- (void)setProject:(GSProjectInfo *)project {
    _project = project;
    self.textField.stringValue = project.name ?: @"";
}


- (void)setEditing:(BOOL)editing {
    _editing = editing;
    
    if (editing) {
        [self.textField setEditable:YES];
        [self.window makeFirstResponder:self.textField];
    } else {
        [self.textField setEditable:NO];
        if (!self.project.isFolder) {
            [self.textField sizeToFit];
        }
        [self.window resignFirstResponder];
    }
}


- (void)controlTextDidEndEditing:(NSNotification *)obj {
    if (obj.object == self.textField) {
        self.project.name = self.textField.stringValue.length > 0 ? self.textField.stringValue : nil;
        self.textField.stringValue = self.project.name;
        [self.project save];
        [self setEditing:NO];
    }
}


@end
