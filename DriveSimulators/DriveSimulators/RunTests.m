//
//  RunTests.m
//  DriveSimulators
//
//  Created by Arpad Zalan on 18/09/15.
//
//

#import "RunTests.h"

#import <FBSimulatorControl/FBDispatchSourceNotifier.h>
#import <FBSimulatorControl/FBSimulator.h>
#import <FBSimulatorControl/FBSimulatorApplication.h>
#import <FBSimulatorControl/FBSimulatorConfiguration.h>
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBSimulatorControl/FBSimulatorControlConfiguration.h>
#import <FBSimulatorControl/FBProcessLaunchConfiguration.h>
#import <FBSimulatorControl/FBSimulatorSession.h>
#import <FBSimulatorControl/FBSimulatorSessionInteraction.h>
#import <FBSimulatorControl/FBSimulatorSessionInteraction+Diagnostics.h>
#import <FBSimulatorControl/FBSimulatorSessionLifecycle.h>
#import <FBSimulatorControl/FBSimulatorSessionState.h>
#import <FBSimulatorControl/FBSimulatorSessionState+Queries.h>
#import <FBSimulatorControl/FBTaskExecutor.h>

#import "NotificationWaiter.h"

@interface RunTests ()

@property (atomic, assign) BOOL isRunning;
@property (nonatomic, strong) NotificationWaiter* notificationWaiter;

@end

@implementation RunTests


- (instancetype)init {
    self = [super init];
    if (self) {
        _notificationWaiter = [NotificationWaiter new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidStart:) name:FBSimulatorSessionDidStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidEnd:) name:FBSimulatorSessionDidEndNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(simulatorDidLaunch:) name:FBSimulatorSessionSimulatorProcessDidLaunchNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(simulatorDidTerminate:) name:FBSimulatorSessionSimulatorProcessDidTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidLaunch:) name:FBSimulatorSessionApplicationProcessDidLaunchNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidTerminate:) name:FBSimulatorSessionApplicationProcessDidTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(agentDidLaunch:) name:FBSimulatorSessionAgentProcessDidLaunchNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(agentDidTerminate:) name:FBSimulatorSessionAgentProcessDidTerminateNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sessionDidStart:(NSNotification*)notification {
    [self logNotification:notification];
}

- (void)sessionDidEnd:(NSNotification*)notification {
    [self logNotification:notification];
}
- (void)simulatorDidLaunch:(NSNotification*)notification {
    [self logNotification:notification];
}

- (void)simulatorDidTerminate:(NSNotification*)notification {
    [self logNotification:notification];
}
- (void)applicationDidLaunch:(NSNotification*)notification {
    [self logNotification:notification];
}

- (void)applicationDidTerminate:(NSNotification*)notification {
    self.isRunning = NO;
    [self logNotification:notification];
}
- (void)agentDidLaunch:(NSNotification*)notification {
    [self logNotification:notification];
}

- (void)agentDidTerminate:(NSNotification*)notification {
    [self logNotification:notification];
}



- (void)logNotification:(NSNotification*)notification {
    NSLog(@"Received notification: %@", notification.name);
    
}

- (void)runWithAppBuildPath:(NSString *)appBuildPath terminationMode:(NSInteger)terminationMode {
    FBSimulatorManagementOptions options =
    FBSimulatorManagementOptionsDeleteManagedSimulatorsOnFirstStart |
    FBSimulatorManagementOptionsKillUnmanagedSimulatorsOnFirstStart |
    FBSimulatorManagementOptionsDeleteOnFree;
    
    NSInteger bucketID = [[NSProcessInfo processInfo] processIdentifier];
    
    FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
                                                      configurationWithSimulatorApplication:[FBSimulatorApplication simulatorApplicationWithError:nil]
                                                      bucket:bucketID
                                                      options:options];
    
    __block FBSimulatorControl* control = [FBSimulatorControl sharedInstanceWithConfiguration:configuration];
    __block NSError *error = nil;
    FBSimulatorSession *session = [control createSessionForSimulatorConfiguration:FBSimulatorConfiguration.iPhone5 error:&error];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    NSError* appError = nil;
    NSLog(@"Testing with app in '%@'", appBuildPath);
    NSString* appBundlePath =  [appBuildPath stringByAppendingPathComponent:@"SingleViewApp.app"];
    NSString* appBinaryPath = [appBundlePath stringByAppendingPathComponent:@"SingleViewApp"];
    NSString* testPath = [appBuildPath stringByAppendingPathComponent:@"SingleViewAppTests.xctest"];

    NSArray* arguments = @[
        @"-NSTreatUnknownArgumentsAsOpen",
        @"NO",
        @"-ApplePersistenceIgnoreState",
        @"YES",
        @"-XCTest",
        @"All",
        testPath
    ];
    NSDictionary *environment = @{
        @"NSUnbufferedIO" : @"YES",
        @"DYLD_FALLBACK_FRAMEWORK_PATH" : @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
        @"DYLD_FALLBACK_LIBRARY_PATH" : @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib",
        @"DYLD_FRAMEWORK_PATH" : appBuildPath,
        @"DYLD_INSERT_LIBRARIES" : @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/IDEBundleInjection.framework/IDEBundleInjection",
        @"DYLD_LIBRARY_PATH" : appBuildPath,
        @"DYLD_ROOT_PATH" : @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk",
        @"DYLD_SHARED_REGION" : @"avoid",
        @"TestBundleLocation" : testPath,
        @"XCInjectBundle": testPath,
        @"XCInjectBundleInto" : appBinaryPath
    };
    
    FBSimulatorApplication* simulatorApplication = [FBSimulatorApplication applicationWithPath:appBundlePath error:&appError];
    FBApplicationLaunchConfiguration *appLaunch = [FBApplicationLaunchConfiguration
                                                   configurationWithApplication:simulatorApplication
                                                   arguments:arguments
                                                   environment:environment];
    
    __block BOOL launchSuccess = NO;
    dispatch_group_async(group, queue, ^{
        launchSuccess = [[[[[session.interact
                             bootSimulator]
                            installApplication:appLaunch.application]
                           launchApplication: appLaunch]
                          sampleApplication:appLaunch.application withDuration:1 frequency:1]
                         performInteractionWithError:&error];
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    [self.notificationWaiter start];
    if (launchSuccess) {
        switch (terminationMode) {
            case 1:
                NSLog(@"Waiting for FBSimulatorSessionApplicationProcessDidTerminateNotification...");
                [self waitForAppBeingTerminated];
                break;
            case 2:
                NSLog(@"Waiting for app removed from session.state.runningApplications...");
                [self waitForApp:simulatorApplication removedFromRunningApplicationsInSession:session];
                break;
            case 3:
                NSLog(@"Waiting for app removed by listening to [FBDispatchSourceNotifier processTerminationNotifierForProcessIdentifier:]...");
                [self waitForApp:simulatorApplication receivesTerminationNotificationInSession:session];
                break;
            case 4:
                NSLog(@"Waiting for app terminated by periodically invoking ps...");
                [self waitForApp:simulatorApplication removedByCheckingWithPSInSession:session];
                break;
            default:
                break;
        }
        [session terminateWithError:&error];
    }

}

- (void)waitForAppBeingTerminated {
    self.isRunning = YES;
    [self.notificationWaiter wakeUpPeriodicallyForCheckingWithBlock:^BOOL{
        return self.isRunning;
    }];
}

- (NSString*)resultForCheckingAppWithProcessID:(NSInteger)processID {
    id<FBTask> task = [[FBTaskExecutor sharedInstance] taskWithLaunchPath: @"/bin/bash" arguments:@[
        @"-c",
        [NSString stringWithFormat:@"ps %li | wc -l", processID]
    ]];
    [task startSynchronouslyWithTimeout:5];
    return [task stdOut];
}

- (void)waitForApp:(FBSimulatorApplication*)simulatorApplication removedByCheckingWithPSInSession:(FBSimulatorSession*)session {
    NSInteger processID = [session.state processForApplication:simulatorApplication].processIdentifier;
    [self.notificationWaiter wakeUpPeriodicallyForCheckingWithBlock:^BOOL{
        NSString* result = [self resultForCheckingAppWithProcessID:processID];
        int count = (int) NSIntegerMax;
        [[NSScanner scannerWithString:result] scanInt:&count];
        return count == 2;

    }];
}

- (void)waitForApp:(FBSimulatorApplication*)simulatorApplication removedFromRunningApplicationsInSession:(FBSimulatorSession*)session {
    [self.notificationWaiter wakeUpPeriodicallyForCheckingWithBlock:^BOOL{
        return session.state.runningApplications.count != 0;
    }];
}

- (void)waitForApp:(FBSimulatorApplication*)simulatorApplication receivesTerminationNotificationInSession:(FBSimulatorSession*)session {
    self.isRunning = YES;
    [FBDispatchSourceNotifier processTerminationNotifierForProcessIdentifier:[session.state processForApplication:simulatorApplication].processIdentifier handler:^(FBDispatchSourceNotifier* notifier) {
        self.isRunning = NO;

    }];
    [self.notificationWaiter wakeUpPeriodicallyForCheckingWithBlock:^BOOL{
        return self.isRunning;
    }];
}

@end
