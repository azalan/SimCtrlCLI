# SimCtrlCLI

This is a sample project to test out the [FBSimulatorControl](https://github.com/facebook/FBSimulatorControl) library. It contains an iOS app with a single unit test (see: [SingleViewApp](https://github.com/azalan/SimCtrlCLI/tree/master/SingleViewApp)) and a Mac app (see: [DriveSimulators](https://github.com/azalan/SimCtrlCLI/tree/master/DriveSimulators)) which uses the FBSimulatorControl library to create an iOS simulator for the test run, execute the test and after the test execution has been finished, tear down the simulator.

The unit test is not a real test, it just keeps occupied the simulator for 5 seconds.

# Installation

After cloning the repository run [run.sh](https://github.com/azalan/SimCtrlCLI/blob/master/run.sh). This should compile everything, and after it should run all of the termination notification tests which I can think of.

These are the following:

1. Listening to the `FBSimulatorSessionApplicationProcessDidTerminateNotification` notification.
1. Periodically checking the `session.state.runningApplications` list to see whether the app is still there
1. Getting the process ID with `[session.state processForApplication:simulatorApplication].processIdentifier`  and setting up a termination listener with `[FBDispatchSourceNotifier processTerminationNotifierForProcessIdentifier:]`
1. Periodically launching `ps` with the process ID to see whether the process is there (this works).
