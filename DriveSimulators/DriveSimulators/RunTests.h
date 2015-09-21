//
//  RunTests.h
//  DriveSimulators
//
//  Created by Arpad Zalan on 18/09/15.
//
//

#import <Foundation/Foundation.h>

@interface RunTests : NSObject

- (void)runWithAppBuildPath:(NSString*)appBuildPath terminationMode:(NSInteger)terminationMode;

@end
