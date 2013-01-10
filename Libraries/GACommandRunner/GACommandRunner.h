//
//  GACommandRunner.h
//  GoAgentX
//
//  Created by Xu Jiwei on 12-2-13.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GAAutoscrollTextView.h"

typedef void (^GACommandRunnerTerminationHandler)(NSTask *task);

@interface GACommandRunner : NSObject {
    NSTask      *task;
    
    id          fileReadCompletionNotificationHandle;
    id          runnerTerminationNotificationHandle;
}

- (BOOL)isTaskRunning;
- (void)terminateTask;
- (int)processId;

- (void)run;

- (void)runCommand:(NSString *)path
  currentDirectory:(NSString *)curDir
         arguments:(NSArray *)arguments
         inputText:(NSString *)text
    outputTextView:(GAAutoscrollTextView *)textView
terminationHandler:(GACommandRunnerTerminationHandler)terminationHandler;

@property (nonatomic, strong)   NSString        *commandPath;
@property (nonatomic, strong)   NSString        *workDirectory;
@property (nonatomic, strong)   NSArray         *arguments;
@property (nonatomic, strong)   NSDictionary    *environment;
@property (nonatomic, strong)   NSString        *inputText;
@property (nonatomic, strong)   GAAutoscrollTextView    *outputTextView;
@property (nonatomic, copy)     GACommandRunnerTerminationHandler   terminationHandler;

@end
