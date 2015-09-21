//
//  NotificationWaiter.h
//  DriveSimulators
//
//  Created by Arpad Zalan on 21/09/15.
//
//

#import <Foundation/Foundation.h>

typedef BOOL(^CheckingBlock)();

@interface NotificationWaiter : NSObject

- (void)start;
- (void)wakeUpPeriodicallyForCheckingWithBlock:(CheckingBlock)block;

@end
