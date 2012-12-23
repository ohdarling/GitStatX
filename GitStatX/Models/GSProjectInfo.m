//
//  GSProjectInfo.m
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-20.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import "GSProjectInfo.h"

@implementation GSProjectInfo

@synthesize repository;

- (void)dealloc {
    [super dealloc];
}


- (void)setPath:(NSString *)path {
    _path = [path copy];
    
    repository = [[GTRepository alloc] initWithURL:[NSURL fileURLWithPath:path] error:NULL];
}


- (NSString *)name {
    return _name ?: self.path.lastPathComponent;
}


- (NSString *)currentBranch {
    return [[repository currentBranchWithError:NULL] shortName];
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
        _children = [[GSProjectInfo findByCriteria:[NSString stringWithFormat:@"WHERE parent_id = %d", [self pk]]] copy];
    }
    
    return _children;
}


- (void)deleteObject {
    [[NSFileManager defaultManager] removeItemAtPath:[self statsPath] error:NULL];
    
    if (self.isFolder) {
        for (GSProjectInfo *project in self.children) {
            [project deleteObject];
        }
    }
    
    [super deleteObject];
}


@end
