// Temporary host-only probe for simctl's failed-launch wait; remove after one CI run.
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <signal.h>
#import <stdio.h>
#import <string.h>
#import <unistd.h>

static void expired(int signalNumber) {
    (void)signalNumber;
    _exit(124);
}

static int runTask(const char **argv) {
    @autoreleasepool {
        NSString *outputPath = [NSString stringWithUTF8String:argv[5]];
        [[NSFileManager defaultManager] createFileAtPath:outputPath contents:[NSData data] attributes:nil];
        NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:outputPath];
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = [NSString stringWithUTF8String:argv[1]];
        task.arguments = @[@"-p", @"/nonexistent-runtime-root", @"list"];
        task.standardOutput = output;
        task.standardError = output;
        NSError *error = nil;
        BOOL launched;
        if (strcmp(argv[4], "null") == 0) {
            launched = [task launchAndReturnError:NULL];
        } else {
            launched = [task launchAndReturnError:&error];
        }
        printf("launch_success=%d error_pointer=%s background=%d error_code=%ld\n",
               launched, argv[4], ![NSThread isMainThread], (long)error.code);
        fflush(stdout);
        if (!launched && strcmp(argv[2], "checked") == 0) {
            puts("skipped_wait_after_failed_launch");
            return 0;
        }
        puts("before_wait");
        fflush(stdout);
        @try {
            [task waitUntilExit];
        } @catch (NSException *exception) {
            printf("exception=%s\n", exception.name.UTF8String);
            return 70;
        }
        puts("after_wait");
        fflush(stdout);
        [output synchronizeFile];
        [output closeFile];
        return 0;
    }
}

int main(int argc, const char **argv) {
    @autoreleasepool {
        if (argc != 6) return 64;
        signal(SIGALRM, expired);
        alarm(3);
        if (strcmp(argv[3], "background") == 0) {
            [NSTimer scheduledTimerWithTimeInterval:60 repeats:YES block:^(NSTimer *timer) { (void)timer; }];
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{ exit(runTask(argv)); });
            [[NSRunLoop currentRunLoop] run];
            return 71;
        }
        return runTask(argv);
    }
}
