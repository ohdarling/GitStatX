//
//  GSMainWindowController.h
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-14.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GSProjectInfo;

@interface GSMainWindowController : NSWindowController <NSSplitViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSOpenSavePanelDelegate, NSWindowDelegate, NSDraggingDestination, NSMenuDelegate> {
    IBOutlet    WebView             *_webView;
    IBOutlet    NSOutlineView       *projectsOutlineView;
    
    NSMutableDictionary             *runnersMap;
    NSMenu                          *projectsContextMenu;
}

- (IBAction)addProjectClicked:(id)sender;

- (IBAction)addFolderClicked:(id)sender;

- (IBAction)exportReport:(id)sender;
- (IBAction)showInFinder:(id)sender;
- (IBAction)renameProject:(id)sender;
- (IBAction)deleteProject:(id)sender;
- (IBAction)setProjectType:(id)sender;

- (IBAction)regenerateAllReports:(id)sender;
- (IBAction)regenerateReport:(id)sender;
- (IBAction)gotoReportTab:(id)sender;

- (IBAction)forkOnGitHub:(id)sender;

@property (nonatomic, strong)   NSArray     *projects;
@property (nonatomic, strong)   GSProjectInfo   *draggedProject;

@end
