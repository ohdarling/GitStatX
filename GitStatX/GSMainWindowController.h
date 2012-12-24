//
//  GSMainWindowController.h
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-14.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GSMainWindowController : NSWindowController <NSSplitViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSOpenSavePanelDelegate, NSWindowDelegate> {
    IBOutlet    WebView             *_webView;
    IBOutlet    NSOutlineView       *projectsOutlineView;
    
    NSMutableDictionary             *runnersMap;
}

- (IBAction)addProjectClicked:(id)sender;

- (IBAction)addFolderClicked:(id)sender;

- (IBAction)showInFinder:(id)sender;
- (IBAction)renameProject:(id)sender;
- (IBAction)deleteProject:(id)sender;
- (IBAction)setProjectType:(id)sender;

@property (nonatomic, strong)   NSArray     *projects;

@end
