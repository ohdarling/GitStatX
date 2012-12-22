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
    
}

- (NSString *)currentBranch;

@property (nonatomic, readonly) GTRepository    *repository;
@property (nonatomic, strong)   NSString        *name;
@property (nonatomic, strong)   NSString        *path;
@property (nonatomic, assign)   int             listOrder;
@property (nonatomic, strong)   NSString        *projectType;
@property (nonatomic, assign)   BOOL            isFolder;
@property (nonatomic, assign)   int             parentId;
@property (nonatomic, strong)   NSMutableArray  *children;
@property (nonatomic, assign)   BOOL            expanded;

@end
