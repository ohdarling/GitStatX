//
//  GSProjectInfo.m
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-20.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import "GSProjectInfo.h"

#import "GACommandRunner.h"

@implementation GSProjectInfo

@synthesize repository;

static NSMutableDictionary *commandRunners = nil;

+ (void)initialize {
    if (self == [GSProjectInfo class]) {
        commandRunners = [NSMutableDictionary new];
    }
}


- (void)dealloc {
    repository = nil;
    self.pathBookmarkData = nil;
    
    [super dealloc];
}


- (NSString *)description {
    NSMutableArray *arr = [NSMutableArray new];
    for (id obj in self.children) {
        [arr addObject:[NSString stringWithFormat:@"\t%@", obj]];
    }
    return [NSString stringWithFormat:@"%@(Name: %@%@)",
            [super description],
            self.name,
            self.isFolder ? [NSString stringWithFormat:@", Children: (\n%@\n)", [arr componentsJoinedByString:@"\n"]] : @""];
}


- (NSString *)descriptionWithIndent:(NSString *)indent {
    NSMutableArray *lines = [NSMutableArray new];
    [lines addObject:[NSString stringWithFormat:@"%@%@", self.isFolder ? @"📂 " : @"", self.name]];
    if (self.isFolder) {
        indent = [(indent ?: @"") stringByAppendingString:@"\t"];
        for (GSProjectInfo *proj in self.children) {
            [lines addObject:[NSString stringWithFormat:@"%@%@",
                              indent,
                              [proj descriptionWithIndent:indent]]];
        }
    }
    
    return [lines componentsJoinedByString:@"\n"];
}


#pragma mark - Generate Stats

- (GACommandRunner *)commandRunner {
    return [commandRunners objectForKey:[NSNumber numberWithInt:self.pk]];
}


- (void)generateStats {
    if ([self isGeneratingStats]) {
        return;
    }
    
    NSString *commit = [[repository headReferenceWithError:NULL] target];
    
    if ([self commandRunner] == nil) {
        GACommandRunner *runner = [[GACommandRunner alloc] init];
        [[NSFileManager defaultManager] createDirectoryAtPath:[self statsPath] withIntermediateDirectories:YES attributes:nil error:NULL];
        runner.workDirectory = [self statsPath];
        runner.commandPath = @"python";
        runner.environment = @{
        @"GNUPLOT": [[NSBundle mainBundle] pathForResource:@"gnuplot" ofType:@"" inDirectory:@"gnuplot"]
        };
        runner.arguments = [NSArray arrayWithObjects:
                            [[NSBundle mainBundle] pathForResource:@"gitstats" ofType:@"" inDirectory:@"gitstats"],
                            @"-c",
                            @"style=bootstrap.css",
                            self.path,
                            self.statsPath,
                            nil];
        [commandRunners setObject:runner forKey:[NSNumber numberWithInt:self.pk]];
        
        runner.terminationHandler = ^(NSTask *task) {
            self.lastGeneratedCommit = commit;
            self.isGeneratingStats = NO;
            [self save];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:GSStatsGeneratedNotification object:self];
        };
    }
    
    [[self commandRunner] run];
    self.isGeneratingStats = YES;
}


- (BOOL)needsGenerateStats {
    return ![[[repository headReferenceWithError:NULL] target] isEqualToString:self.lastGeneratedCommit];
}


- (BOOL)isGeneratingStats {
    return [[self commandRunner] isTaskRunning];
}


#pragma mark - Properties

- (void)setPath:(NSString *)path {
    _path = [path copy];
}


- (void)setPathBookmarkData:(NSData *)pathBookmarkData {
    if (_pathBookmarkData != pathBookmarkData) {
        _pathBookmarkData = [pathBookmarkData copy];
        
        [bookmarkURL stopAccessingSecurityScopedResource];
        BOOL isStale = NO;
        if (pathBookmarkData != nil) {
            bookmarkURL = [[NSURL URLByResolvingBookmarkData:pathBookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&isStale error:NULL] copy];
            [bookmarkURL startAccessingSecurityScopedResource];
            
            if (bookmarkURL && !self.isFolder) {
                repository = [[GTRepository alloc] initWithURL:bookmarkURL error:NULL];
            } else {
                repository = nil;
            }
        }
    }
}


- (NSString *)name {
    return _name ?: self.path.lastPathComponent ?: @"";
}


- (NSString *)currentBranch {
    return [[repository currentBranchWithError:NULL] shortName];
}


- (NSString *)statsIndexURL {
    return [[NSURL fileURLWithPath:[[self statsPath] stringByAppendingPathComponent:@"index.html"]] absoluteString];
}


- (NSString *)statsPath {
    NSString *path = [AppSupportPath(@"Reports") stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [self pk]]];
    return path;
}


- (BOOL)statsExists {
    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[self statsPath] isDirectory:&isDirectory];
    return exists && isDirectory;
}


- (NSArray *)children {
    if (_children == nil) {
        _children = [[GSProjectInfo findByCriteria:[NSString stringWithFormat:@"WHERE parent_id = %d ORDER BY list_order ASC", [self pk]]] copy];
    }
    
    return _children;
}


- (void)clearChildrenCache {
    _children = nil;
}


- (void)refreshChildrenListOrder {
    int order = 1;
    for (GSProjectInfo *proj in self.children) {
        proj.listOrder = order;
        [proj save];
        order += 2;
    }
}


- (void)addChild:(GSProjectInfo *)project {
    project.parentId = self.pk;
    project.listOrder = [self.children.lastObject listOrder] + 1;
    self.expanded = YES;
    [self save];
    _children = nil;
}


- (GSProjectInfo *)parentProject {
    return self.parentId > 0 ? (GSProjectInfo *)[GSProjectInfo findByPK:self.parentId] : nil;
}


#pragma mark - Override

- (void)deleteObject {
    [[NSFileManager defaultManager] removeItemAtPath:[self statsPath] error:NULL];
    
    if (self.isFolder) {
        for (GSProjectInfo *project in self.children) {
            [project deleteObject];
        }
    }

    if (self.parentId > 0) {
        [(GSProjectInfo *)[GSProjectInfo findByPK:self.parentId] clearChildrenCache];
    }
    _children = nil;
    
    [super deleteObject];
}


- (void)save {
    if (self.parentId > 0) {
        [(GSProjectInfo *)[GSProjectInfo findByPK:self.parentId] clearChildrenCache];
    }
    
    [super save];
}


@end
