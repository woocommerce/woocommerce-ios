#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach/mach_time.h>
#import <math.h>
#import <stdlib.h>
#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR
#error This tool must only be built for the iOS simulator.
#endif

@protocol AngleReading <NSObject>
- (BOOL)isAngleValid;
- (float)angleDegrees;
@end
@protocol AngleManager <NSObject>
+ (BOOL)isAvailable;
- (void)startAngleUpdatesToQueue:(NSOperationQueue *)queue handler:(void (^)(id<AngleReading> angle))handler;
- (void)stopAngleUpdates;
@end

static NSNumber *readAngle(Class managerClass, NSNumber *target) {
    id<AngleManager> manager = [managerClass new];
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 1;
    NSCondition *condition = [NSCondition new];
    __block NSNumber *reading;
    [manager startAngleUpdatesToQueue:queue handler:^(id<AngleReading> angle) {
        if (![angle respondsToSelector:@selector(isAngleValid)] || ![angle respondsToSelector:@selector(angleDegrees)]) return;
        if (!angle.isAngleValid || !isfinite(angle.angleDegrees)) return;
        if (target && fabs(angle.angleDegrees - target.doubleValue) > 0.5) return;
        [condition lock];
        reading = @(angle.angleDegrees);
        [condition signal];
        [condition unlock];
    }];
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:8];
    [condition lock];
    while (!reading && [condition waitUntilDate:deadline]) {}
    NSNumber *result = reading;
    [condition unlock];
    [manager stopAngleUpdates];
    return result;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc < 2 || argc > 3) {
            fprintf(stderr, "Usage: duo-pose expected-simulator-udid [angle]\n");
            return 64;
        }
        NSString *expected = [NSString stringWithUTF8String:argv[1]];
        NSString *actual = NSProcessInfo.processInfo.environment[@"SIMULATOR_UDID"];
        if (![actual isEqualToString:expected]) {
            fprintf(stderr, "Refusing to run outside the selected simulator.\n");
            return 65;
        }
        dlopen("/System/Library/Frameworks/CoreMotion.framework/CoreMotion", RTLD_LAZY);
        Class managerClass = NSClassFromString(@"CMAngleManager");
        if (![managerClass respondsToSelector:@selector(isAvailable)] || ![(id<AngleManager>)managerClass isAvailable]
            || ![managerClass instancesRespondToSelector:@selector(startAngleUpdatesToQueue:handler:)]
            || ![managerClass instancesRespondToSelector:@selector(stopAngleUpdates)]) {
            fprintf(stderr, "No available hinge sensor.\n");
            return 66;
        }
        NSNumber *before = readAngle(managerClass, nil);
        printf("before=%s\n", before ? before.stringValue.UTF8String : "unknown");
        fflush(stdout);
        if (argc == 2) return before ? 0 : 67;
        char *end;
        double angle = strtod(argv[2], &end);
        if (end == argv[2] || *end || !isfinite(angle) || angle < 0 || angle > 180) return 64;
        void *library = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY);
        CFDataRef (*serialize)(CFTypeRef, CFOptionFlags) = dlsym(library, "IOCFSerialize");
        CFTypeRef (*createEvent)(CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t, uint8_t *, CFIndex, uint32_t) = dlsym(library, "IOHIDEventCreateVendorDefinedEvent");
        CFTypeRef (*createClient)(CFAllocatorRef) = dlsym(library, "IOHIDEventSystemClientCreate");
        void (*dispatchEvent)(CFTypeRef, CFTypeRef) = dlsym(library, "IOHIDEventSystemClientDispatchEvent");
        if (!library || !serialize || !createEvent || !createClient || !dispatchEvent) {
            fprintf(stderr, "Hinge event functions are unavailable.\n");
            return 68;
        }
        NSDictionary *payload = @{@"provider": @"com.apple.Virtualization.VirtualMachines", @"source": @"hinge-slider-control", @"type": @"range", @"value": @(angle)};
        CFDataRef data = serialize((__bridge CFTypeRef)payload, 1);
        if (!data) return 69;
        CFTypeRef event = createEvent(kCFAllocatorDefault, mach_absolute_time(), 0xff61, 0x5b, 0, (uint8_t *)CFDataGetBytePtr(data), CFDataGetLength(data), 0);
        CFRelease(data);
        CFTypeRef client = createClient(kCFAllocatorDefault);
        if (!client || !event) {
            if (client) CFRelease(client);
            if (event) CFRelease(event);
            return 70;
        }
        dispatchEvent(client, event);
        CFRelease(event);
        CFRelease(client);
        NSNumber *after = readAngle(managerClass, @(angle));
        printf("after=%s\n", after ? after.stringValue.UTF8String : "unknown");
        return after ? 0 : 71;
    }
}
