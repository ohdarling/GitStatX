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

- (id)init {
    if (self = [super init]) {
        self.children = [NSMutableArray array];
    }
    
    return self;
}


- (void)dealloc {
    [super dealloc];
}


- (void)setPath:(NSString *)path {
    _path = [path copy];
    
    repository = [[GTRepository alloc] initWithURL:[NSURL fileURLWithPath:path] error:NULL];
}


- (NSString *)currentBranch {
    return [[repository currentBranchWithError:NULL] shortName];
}


- (NSString *)name {
    return _name ?: self.path.lastPathComponent;
}


- (void)deleteObject {
    [super deleteObject];
}


@end
