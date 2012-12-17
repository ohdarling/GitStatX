//
//  GACommandRunner.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-2-13.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GACommandRunner.h"

#define GACommandRunnerTaskTerminatedNotification @"GACommandRunnerTaskTerminatedNotification"

@implementation GACommandRunner

@synthesize workDirectory = _workDirectory;
@synthesize commandPath = _commandPath;
@synthesize environment = _environment;
@synthesize arguments = _arguments;
@synthesize inputText = _inputText;
@synthesize outputTextView = _outputTextView;
@synthesize terminationHandler = _terminationHandler;

- (id)init {
    if (self = [super init]) {
    }
    
    return self;
}


- (BOOL)isTaskRunning {
    return [task isRunning];
}


- (void)terminateTask {
    if (task && [task isRunning]) {
        [task terminate];
        [task waitUntilExit];
    }
}


- (int)processId {
    return [task processIdentifier];
}


- (void)waitTaskUntilDone:(id)sender {
    @autoreleasepool {
        [task waitUntilExit];
        [[NSNotificationCenter defaultCenter] postNotificationName:GACommandRunnerTaskTerminatedNotification object:sender];   
    }
}


- (void)run {
    [self terminateTask];
    
    task = [NSTask new];
    if ([self.commandPath hasPrefix:@"/"]) {
        [task setLaunchPath:self.commandPath];
        [task setArguments:self.arguments ?: [NSArray array]];
    } else {
        [task setLaunchPath:@"/usr/bin/env"];
        NSMutableArray *args = [NSMutableArray arrayWithArray:self.arguments];
        [args insertObject:self.commandPath atIndex:0];
        [task setArguments:args];
    }
    
    if (self.workDirectory) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.workDirectory]) {
            [task setCurrentDirectoryPath:self.workDirectory];
        } else {
            NSLog(@"Work directory %@ does not exists", self.workDirectory);
        }
    }
    
    if (self.environment) {
        [task setEnvironment:self.environment];
    }
    
    if (self.inputText) {
        NSPipe *pipe = [NSPipe new];
        [[pipe fileHandleForWriting] writeData:[self.inputText dataUsingEncoding:NSUTF8StringEncoding]];
        NSFileHandle *inputHandle = [pipe fileHandleForReading];
        [task setStandardInput:inputHandle];
    }
    
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe];
    
    NSFileHandle *outputReadHandle = [outputPipe fileHandleForReading];
    
    __block GACommandRunner *_self = self;
    
    [[NSNotificationCenter defaultCenter] removeObserver:fileReadCompletionNotificationHandle];
    [[NSNotificationCenter defaultCenter] removeObserver:runnerTerminationNotificationHandle];
    
    fileReadCompletionNotificationHandle = [[NSNotificationCenter defaultCenter]
                                            addObserverForName:NSFileHandleReadCompletionNotification
                                            object:outputReadHandle
                                            queue:[NSOperationQueue mainQueue]
                                            usingBlock:^(NSNotification *note) {
                                                
                                                NSData *data = [note.userInfo objectForKey:NSFileHandleNotificationDataItem];
                                                if ([data length] > 0) {
                                                    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                    [self.outputTextView appendString:str];
                                                    [outputReadHandle readInBackgroundAndNotify];
                                                } 
                                            }];
    
    [outputReadHandle readInBackgroundAndNotify];
    
    __block id _task = task;
    
    runnerTerminationNotificationHandle = [[NSNotificationCenter defaultCenter]
                                           addObserverForName:GACommandRunnerTaskTerminatedNotification
                                           object:self
                                           queue:[NSOperationQueue mainQueue]
                                           usingBlock:^(NSNotification *note) {
                                               [outputReadHandle closeFile];
                                               [_self.outputTextView appendString:@"\n"];
                                               
                                               if (_self.terminationHandler) {
                                                   _self.terminationHandler(_task);
                                               }
                                           }];
    
    [task launch];
    
    // 新启线程来等待进程结束
    [NSThread detachNewThreadSelector:@selector(waitTaskUntilDone:) toTarget:self withObject:self];
}


- (void)runCommand:(NSString *)path
  currentDirectory:(NSString *)curDir
         arguments:(NSArray *)arguments
         inputText:(NSString *)inputText
    outputTextView:(GAAutoscrollTextView *)textView
terminationHandler:(GACommandRunnerTerminationHandler)terminationHandler {
    
    self.commandPath = path;
    self.workDirectory = curDir;
    self.arguments = arguments;
    self.inputText = inputText;
    self.outputTextView = textView;
    self.terminationHandler = terminationHandler;
    
    [self run];
}


@end
