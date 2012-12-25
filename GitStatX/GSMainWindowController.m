//
//  GSMainWindowController.m
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-14.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import "GSMainWindowController.h"

#import "GSProjectInfo.h"

#import "GSProjectInfoCellView.h"

@interface GSMainWindowController ()

@end

@implementation GSMainWindowController

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    
    runnersMap = [NSMutableDictionary new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statsGeneratedNotification:) name:GSStatsGeneratedNotification object:nil];
    
    [self reloadData];
}


- (void)reloadData {
    NSMutableArray *selectedItems = [NSMutableArray new];
    [[projectsOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [selectedItems addObject:[projectsOutlineView itemAtRow:idx]];
    }];
    
    NSArray *projects = [GSProjectInfo findByCriteria:@"ORDER BY list_order ASC"];
    NSMutableDictionary *map = [NSMutableDictionary new];
    
    for (GSProjectInfo *project in projects) {
        [map setObject:project forKey:[NSNumber numberWithInt:project.pk]];
    }
    
    for (GSProjectInfo *project in projects) {
        if (project.parentId > 0) {
            if ([GSProjectInfo findByPK:project.parentId] != nil) {
                [map removeObjectForKey:[NSNumber numberWithInt:project.pk]];
            } else {
                project.parentId = 0;
                [project save];
            }
        }
    }
    
    self.projects = [[map allValues] sortedArrayUsingComparator:^NSComparisonResult(GSProjectInfo *obj1, GSProjectInfo *obj2) {
        return obj1.listOrder - obj2.listOrder;
    }];
    
    [projectsOutlineView reloadData];
    
    for (GSProjectInfo *project in projects) {
        if (project.expanded) {
            [projectsOutlineView expandItem:project];
        }
    }
    
    if (selectedItems.count > 0) {
        NSMutableIndexSet *idxset = [NSMutableIndexSet new];
        for (id obj in selectedItems) {
            [idxset addIndex:[projectsOutlineView rowForItem:obj]];
        }
        [projectsOutlineView selectRowIndexes:idxset byExtendingSelection:NO];
    }
}


#pragma mark - Notifications

- (void)statsGeneratedNotification:(NSNotification *)note {
    [_webView reload:nil];
}


#pragma mark - Helper methods

- (GSProjectInfo *)clickedProject {
    NSInteger clickedRow = [projectsOutlineView clickedRow];
    GSProjectInfo *project = nil;
    if (clickedRow != -1) {
        project = [projectsOutlineView itemAtRow:clickedRow];
    }
    
    return project;
}


- (GSProjectInfo *)nearestFolderOfClickedProject {
    GSProjectInfo *parentProject = [self clickedProject];
    if (!parentProject.isFolder) {
        if (parentProject.parentId > 0) {
            parentProject = (GSProjectInfo *)[GSProjectInfo findByPK:parentProject.parentId];
        } else {
            parentProject = nil;
        }
    }
    
    return parentProject;
}


- (GSProjectInfo *)selectedProject {
    NSInteger selectedRow = [projectsOutlineView selectedRow];
    GSProjectInfo *project = nil;
    if (selectedRow != -1) {
        project = [projectsOutlineView itemAtRow:selectedRow];
    }
    
    return project;
}


#pragma mark - Actions

- (void)addProjectClicked:(id)sender {
    GSProjectInfo *parentProject = [self nearestFolderOfClickedProject];
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    panel.allowsMultipleSelection = NO;
    panel.delegate = self;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            GSProjectInfo *project = [GSProjectInfo new];
            project.path = [panel.URL path];
            
            if (parentProject != nil) {
                [parentProject addChild:project];
            } else {
                project.listOrder = [self.projects.lastObject listOrder]+1;
            }
            
            [project save];
            [project generateStats];
            
            [self reloadData];
        }
    }];
}


- (void)removeProjectClicked:(id)sender {
    
}


- (void)addFolderClicked:(id)sender {
    GSProjectInfo *parentProject = [self nearestFolderOfClickedProject];
    
    GSProjectInfo *project = [GSProjectInfo new];
    project.isFolder = YES;
    project.path = @"Hello";
    
    if (parentProject != nil) {
        [parentProject addChild:project];
    } else {
        project.listOrder = [self.projects.lastObject listOrder]+1;
    }
    
    [project save];
    [self reloadData];
}


- (void)showInFinder:(id)sender {
    if ([self clickedProject]) {
        [[NSWorkspace sharedWorkspace] selectFile:[self clickedProject].path
                         inFileViewerRootedAtPath:nil];
    }
}


- (void)renameProject:(id)sender {
    
}


- (void)deleteProject:(id)sender {
    GSProjectInfo *project = [self clickedProject];
    if (project != nil) {
        NSInteger result = [[NSAlert alertWithMessageText:@"Delete Project"
                                            defaultButton:@"Remove Project Stats"
                                          alternateButton:@"Cancel"
                                              otherButton:nil
                                informativeTextWithFormat:@"It will remove stats of the project %@, NOTHING in repository will be deleted.", project.name] runModal];
        
        if (result == NSAlertDefaultReturn) {
            [project deleteObject];
            [self reloadData];
        }
    }
}


- (void)setProjectType:(id)sender {
    GSProjectInfo *project = [self clickedProject];
    if (project) {
        NSString *type = [[[sender title] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
        project.projectType = type;
        [project save];
        [self reloadData];
    }
}


#pragma mark - SplitView delegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return 200.0;
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return self.window.frame.size.width-200;
}


#pragma mark - Projects OutlineView delegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(GSProjectInfo *)item {
    return item == nil ? self.projects.count : [[item children] count];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(GSProjectInfo *)item {
    return item.isFolder;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return item == nil ? self.projects[index] : [[item children] objectAtIndex:index];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(GSProjectInfo *)item {
    return item.isFolder;
}


- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(GSProjectInfo *)item {
    NSTableCellView *view = nil;
    
    if (item.isFolder) {
        view = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:nil];
        view.textField.stringValue = item.name;
        
    } else {
        view = [outlineView makeViewWithIdentifier:@"DataCell" owner:nil];
        [(GSProjectInfoCellView *)view setProject:item];
    }
    
    return view;
}


- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(GSProjectInfo *)item {
    return item.isFolder ? 25.0 : 40.0;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(GSProjectInfo *)item {
    item.expanded = NO;
    [item save];
    return YES;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(GSProjectInfo *)item {
    item.expanded = YES;
    [item save];
    return YES;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(GSProjectInfo *)item {
    if (!item.isFolder) {
        if ([item statsExists]) {
            [_webView setMainFrameURL:[item statsIndexURL]];
            
        } else if ([item needsGenerateStats]) {
            [item generateStats];
        }
    }
    
    return YES;
}


#pragma mark - NSOpenSavePanelDelegate

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url {
    // Should do more here to enable and disable items - but I'm lazy.
    return YES;
}


- (BOOL)panel:(NSOpenPanel *)sender validateURL:(NSURL *)url error:(NSError **)outError {
    if (!([self repositoryURLForURL:url])) {
        return NO;
    }
    
    return YES;
}


#pragma mark - class extension

- (NSURL *)repositoryURLForURL:(NSURL *)url {
    // returns the repository URL or nil if it can't be made.
    // If the URL is a file, it should have the extension '.git' - bare repository
    // If the URL is a folder it should have the name '.git'
    // If the URL is a folder, then it should contain a subfolder called '.git
    NSString *kGit = @".git";
    NSString *endPoint = [url lastPathComponent];
    
    if ([[endPoint lowercaseString] hasSuffix:kGit]) {
        return url;
    }
    
    if ([endPoint isEqualToString:kGit]) {
        return url;
    }
    
    NSURL *possibleGitDir = [url URLByAppendingPathComponent:kGit isDirectory:YES];
    if ([possibleGitDir checkResourceIsReachableAndReturnError:NULL]) {
        return possibleGitDir;
    }
    
    NSLog(@"Not a valid path");
    return nil;
}


#pragma mark - Window delegate

- (BOOL)windowShouldClose:(id)sender {
    [self.window orderOut:nil];
    return NO;
}


- (void)windowDidBecomeMain:(NSNotification *)notification {
    [projectsOutlineView setNeedsDisplay:YES];
}


- (void)windowDidResignMain:(NSNotification *)notification {
    [projectsOutlineView setNeedsDisplay:YES];
}



@end
