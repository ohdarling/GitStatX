//
//  GSAppDelegate.h
//  GitStatX
//
//  Created by Xu Jiwei on 12-12-6.
//  Copyright (c) 2012年 TickPlant.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GSMainWindowController.h"

@interface GSAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet    GSMainWindowController      *mainWindowController;
}

@end
