//
//  main.m
//  DriveSimulators
//
//  Created by Arpad Zalan on 18/09/15.
//
//

#import <Foundation/Foundation.h>

#import "RunTests.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSArray* arguments = [[NSProcessInfo processInfo] arguments];
        if (arguments.count > 2) {
            NSURL * url = [NSURL fileURLWithPath:arguments[1]];
            url = [NSURL URLWithString:[url absoluteString]];
            NSString * newPath = [[url URLByResolvingSymlinksInPath] path];
            
            NSInteger terminationMode;
            [[NSScanner scannerWithString:arguments[2]] scanInteger:&terminationMode];
            
            RunTests* runTests = [RunTests new];
            [runTests runWithAppBuildPath:newPath terminationMode:terminationMode];
        } else {
            NSLog(@"Usage: DriveSimulators path_to_SingleViewApp termination_detect_mode\n\n"
                  "termination_detect_mode  1 - via ApplicationProcessDidTerminate notification\n"
                  "                         2 - waiting for being removed from runningApplications\n"
                  "                         3 - via FBDispatchSourceNotifier\n"
                  "                         4 - using the ps command line tool"
                  );
            
        }
    }
    return 0;
}
