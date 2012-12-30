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

#define GSPROJECT_PBORAD_TYPE   @"GitStatXProjectPboardType"


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
    
    [projectsOutlineView registerForDraggedTypes:@[GSPROJECT_PBORAD_TYPE, NSFilenamesPboardType]];
    [projectsOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [projectsOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    
    [self reloadData];
}


- (void)reloadData {
    NSMutableArray *selectedItems = [NSMutableArray new];
    [[projectsOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [selectedItems addObject:[projectsOutlineView itemAtRow:idx]];
    }];
    
    NSArray *projects = [GSProjectInfo allObjects];
    NSMutableDictionary *map = [NSMutableDictionary new];
    
    for (GSProjectInfo *project in projects) {
        [map setObject:project forKey:[NSNumber numberWithInt:project.pk]];
        [project clearChildrenCache];
    }
    
    for (GSProjectInfo *project in projects) {
        if (project.parentId > 0) {
            if (project.parentProject != nil) {
                [map removeObjectForKey:[NSNumber numberWithInt:project.pk]];
            } else {
                project.parentId = 0;
                [project save];
            }
        }
    }
    
    self.projects = [GSProjectInfo findByCriteria:@"WHERE parent_id = 0 ORDER BY list_order ASC"];
    int listOrder = 1;
    for (GSProjectInfo *proj in self.projects) {
        proj.listOrder = listOrder;
        [proj save];
        listOrder += 2;
    }
    
    [projectsOutlineView reloadData];
    
    for (GSProjectInfo *project in projects) {
        if (project.expanded) {
            // Confirm parent items are expanded
            GSProjectInfo *proj = project.parentProject;
            while (proj && ![projectsOutlineView isItemExpanded:proj]) {
                [projectsOutlineView expandItem:proj];
            }
            
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
        parentProject = parentProject.parentProject;
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


- (GSProjectInfo *)addProject:(NSString *)pathOrName isFolder:(BOOL)isFolder afterProject:(GSProjectInfo *)proj {
    GSProjectInfo *project = [GSProjectInfo new];
    project.isFolder = isFolder;
    project.path = isFolder ? nil : pathOrName;
    project.name = isFolder ? pathOrName : nil;
    project.pathBookmarkData = !isFolder ? [[NSURL fileURLWithPath:pathOrName] bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:NULL] : nil;
    
    GSProjectInfo *parentProject = proj.isFolder ? proj : proj.parentProject;
    if (parentProject != nil) {
        [parentProject addChild:project];
    } else {
        project.listOrder = [self.projects.lastObject listOrder] + 1;
    }
    
    if (proj != nil && !proj.isFolder) {
        project.listOrder = proj.listOrder + 1;
    }
    
    [project save];
    
    if (!project.isFolder) {
        [project generateStats];
    }
    
    [self reloadData];
    
    return project;
}


#pragma mark - Actions

- (void)addProjectClicked:(id)sender {
    GSProjectInfo *clickedProject = [self clickedProject];
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    panel.allowsMultipleSelection = NO;
    panel.delegate = self;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self addProject:panel.URL.path isFolder:NO afterProject:clickedProject];
        }
    }];
}


- (void)addFolderClicked:(id)sender {
    GSProjectInfo *clickedProject = [self clickedProject];
    GSProjectInfo *newFolder = [self addProject:@"New Folder" isFolder:YES afterProject:clickedProject];
    GSProjectInfoCellView *cellView = [projectsOutlineView viewAtColumn:0
                                                                    row:[projectsOutlineView rowForItem:newFolder]
                                                        makeIfNecessary:YES];
    [cellView setEditing:YES];
}


- (void)exportReport:(id)sender {
    GSProjectInfo *clickedProject = [self clickedProject];
    if (clickedProject != nil) {
        NSSavePanel *panel = [NSSavePanel savePanel];
        panel.title = [NSString stringWithFormat:@"Export statistic of %@", clickedProject.name];
        [panel setNameFieldStringValue:[NSString stringWithFormat:@"GitStatX - %@", clickedProject.name]];
        if ([panel runModal] == NSFileHandlingPanelOKButton) {
            [[NSFileManager defaultManager] removeItemAtURL:panel.URL error:NULL];
            [[NSFileManager defaultManager] copyItemAtPath:[clickedProject statsPath] toPath:[panel.URL path] error:NULL];
        }
    }
}


- (void)showInFinder:(id)sender {
    if ([self clickedProject]) {
        [[NSWorkspace sharedWorkspace] selectFile:[self clickedProject].path
                         inFileViewerRootedAtPath:nil];
    }
}


- (void)renameProject:(id)sender {
    GSProjectInfo *clickedProject = [self clickedProject];
    if (clickedProject) {
        GSProjectInfoCellView *cellView = [projectsOutlineView viewAtColumn:0
                                                                        row:[projectsOutlineView rowForItem:clickedProject]
                                                            makeIfNecessary:YES];
        [cellView setEditing:YES];
    }
}


- (void)deleteProject:(id)sender {
    GSProjectInfo *project = [self clickedProject];
    if (project != nil) {
        NSString *desc = [project descriptionWithIndent:@""];
        NSInteger result = [[NSAlert alertWithMessageText:@"Delete Project"
                                            defaultButton:@"Remove Project Stats"
                                          alternateButton:@"Cancel"
                                              otherButton:nil
                                informativeTextWithFormat:@"These folders or stats of the projects will be removed:\n\n%@\n\nDon't worry, NOTHING in repository will be deleted.", desc] runModal];
        
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
    GSProjectCellView *view = [outlineView makeViewWithIdentifier:item.isFolder ? @"HeaderCell" : @"DataCell" owner:nil];
    view.project = item;
    
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


- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    self.draggedProject = [items lastObject];
    
    [pboard declareTypes:@[GSPROJECT_PBORAD_TYPE] owner:self];
    [pboard setData:[NSData data] forType:GSPROJECT_PBORAD_TYPE];
    
    return YES;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(GSProjectInfo *)item childIndex:(NSInteger)index {
    GSProjectInfo *afterProject = index > 0 ? (item != nil ? item.children[index-1] : self.projects[index-1]) : nil;
    GSProjectInfo *parentProject = item != nil ? item : (afterProject != nil ? (GSProjectInfo *)[GSProjectInfo findByPK:item.pk] : nil);
    
    NSMutableArray *selectedNodes = [NSMutableArray array];
    [[projectsOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [selectedNodes addObject:[projectsOutlineView itemAtRow:idx]];
    }];
    
    if ([info draggingSource] == projectsOutlineView && [[info draggingPasteboard] availableTypeFromArray:@[GSPROJECT_PBORAD_TYPE]] != nil) {
        self.draggedProject.listOrder = afterProject != nil ? afterProject.listOrder + 1 : 0;
        self.draggedProject.parentId = parentProject != nil ? parentProject.pk : 0;
        [parentProject refreshChildrenListOrder];
        
        [self.draggedProject save];
        self.draggedProject = nil;
        
        [self reloadData];
    }
    
    
    // Draggin from Finder
    if ([[info draggingPasteboard] availableTypeFromArray:@[NSFilenamesPboardType]] != nil) {
        NSArray *files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
        GSProjectInfo *afterProj = afterProject;
        for (NSString *file in files) {
            if ([self repositoryURLForURL:[NSURL fileURLWithPath:file]]) {
                afterProj = [self addProject:file isFolder:NO afterProject:afterProj];
            }
        }
    }
    
    if ([selectedNodes count] > 0) {
        NSMutableIndexSet *newNodesIdx = [NSMutableIndexSet indexSet];
        for (id obj in selectedNodes) {
            [newNodesIdx addIndex:[projectsOutlineView rowForItem:obj]];
        }
        [projectsOutlineView selectRowIndexes:newNodesIdx byExtendingSelection:NO];
    }
    
    return YES;
}


- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(GSProjectInfo *)item proposedChildIndex:(NSInteger)index {
    NSDragOperation result = NSDragOperationGeneric;
    
    if (item || index != NSOutlineViewDropOnItemIndex) {
        GSProjectInfo *proj = item ?: [projectsOutlineView itemAtRow:index];
        if (index == NSOutlineViewDropOnItemIndex && !proj.isFolder) {
            result = NSDragOperationNone;
        }
    }
    
    // Dragging from GitStatX
    if ([info draggingSource] == projectsOutlineView && [[info draggingPasteboard] availableTypeFromArray:@[GSPROJECT_PBORAD_TYPE]] != nil) {
        while (item) {
            if (self.draggedProject == item || [self.draggedProject.children indexOfObject:item] != NSNotFound) {
                result = NSDragOperationNone;
                break;
            }
            item = item.parentProject;
        }
    }
    
    return result;
}


- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items {
    return nil;
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


#pragma mark - Menu delegate

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    GSProjectInfo *clickedProject = [self clickedProject];
    BOOL isFolder = clickedProject.isFolder;
    switch (menuItem.tag) {
        case 1:
            return clickedProject != nil;
            break;
            
        case 2:
            return (!isFolder && clickedProject != nil);
            break;
            
        default:
            break;
    }
    
    return YES;
}


- (void)menuNeedsUpdate:(NSMenu *)menu {
    for (NSMenuItem *item in menu.itemArray) {
        [item setEnabled:[self validateMenuItem:item]];
    }
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
