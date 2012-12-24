//
//  GSProjectInfo.h
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-20.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import "SQLitePersistentObject.h"

@interface GSProjectInfo : SQLitePersistentObject {
    GTRepository            *repository;
    
    __strong NSArray        *_children;
}

- (NSString *)currentBranch;
- (NSString *)statsIndexURL;
- (NSString *)statsPath;
- (BOOL)statsExists;

- (NSArray *)children;
- (void)addChild:(GSProjectInfo *)child;
- (void)clearChildrenCache;

- (void)generateStats;
- (BOOL)needsGenerateStats;

@property (nonatomic, readonly) GTRepository    *repository;
@property (nonatomic, strong)   NSString        *name;
@property (nonatomic, strong)   NSString        *path;
@property (nonatomic, assign)   int             listOrder;
@property (nonatomic, strong)   NSString        *projectType;
@property (nonatomic, assign)   BOOL            isFolder;
@property (nonatomic, assign)   int             parentId;
@property (nonatomic, assign)   BOOL            expanded;
@property (nonatomic, assign)   BOOL            isGeneratingStats;
@property (nonatomic, strong)   NSString        *lastGeneratedCommit;

@end
