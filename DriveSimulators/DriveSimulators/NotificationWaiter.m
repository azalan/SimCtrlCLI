//
//  NotificationWaiter.m
//  DriveSimulators
//
//  Created by Arpad Zalan on 21/09/15.
//
//

#import "NotificationWaiter.h"

static NSInteger kTimeout = 15;

@interface NotificationWaiter ()
@property (nonatomic, strong) NSDate* date;
@end

@implementation NotificationWaiter

- (void)start {
    self.date = [NSDate new];
}

- (void)wakeUpPeriodicallyForCheckingWithBlock:(CheckingBlock)block {
    BOOL isRunning = YES;
    while (isRunning) {
        NSLog(@"Sleeping for a second...");
        
        [NSThread sleepForTimeInterval:1];
        
        isRunning = block();
        
        if (isRunning && [self isTimedOut]) {
            NSLog(@"Timed out after %li seconds!", kTimeout);
            isRunning = NO;
        }
    }
}

- (BOOL)isTimedOut {
    NSTimeInterval elapsedTime = [self.date timeIntervalSinceNow] * -1;
    return elapsedTime > kTimeout;
}

@end
