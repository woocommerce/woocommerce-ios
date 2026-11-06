#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach/mach_time.h>
#import <math.h>
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

static BOOL waitUntilOpen(Class managerClass) {
    id<AngleManager> manager = [managerClass new];
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 1;
    NSCondition *condition = [NSCondition new];
    __block BOOL opened = NO;
    [manager startAngleUpdatesToQueue:queue handler:^(id<AngleReading> angle) {
        if (![angle respondsToSelector:@selector(isAngleValid)] || ![angle respondsToSelector:@selector(angleDegrees)]) return;
        if (!angle.isAngleValid || !isfinite(angle.angleDegrees)) return;
        if (fabs(angle.angleDegrees - 180) > 0.5) return;
        [condition lock];
        opened = YES;
        [condition signal];
        [condition unlock];
    }];
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:8];
    [condition lock];
    while (!opened && [condition waitUntilDate:deadline]) {}
    BOOL result = opened;
    [condition unlock];
    [manager stopAngleUpdates];
    return result;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc != 2) {
            fprintf(stderr, "Usage: duo-pose expected-simulator-udid\n");
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
        void *library = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY);
        CFDataRef (*serialize)(CFTypeRef, CFOptionFlags) = dlsym(library, "IOCFSerialize");
        CFTypeRef (*createEvent)(CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t, uint8_t *, CFIndex, uint32_t) = dlsym(library, "IOHIDEventCreateVendorDefinedEvent");
        CFTypeRef (*createClient)(CFAllocatorRef) = dlsym(library, "IOHIDEventSystemClientCreate");
        void (*dispatchEvent)(CFTypeRef, CFTypeRef) = dlsym(library, "IOHIDEventSystemClientDispatchEvent");
        if (!library || !serialize || !createEvent || !createClient || !dispatchEvent) {
            fprintf(stderr, "Hinge event functions are unavailable.\n");
            return 68;
        }
        NSDictionary *payload = @{@"provider": @"com.apple.Virtualization.VirtualMachines", @"source": @"hinge-slider-control", @"type": @"range", @"value": @180};
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
        BOOL opened = waitUntilOpen(managerClass);
        fprintf(opened ? stdout : stderr, opened ? "Duo opened to 180 degrees.\n" : "Duo did not open.\n");
        return opened ? 0 : 71;
    }
}
