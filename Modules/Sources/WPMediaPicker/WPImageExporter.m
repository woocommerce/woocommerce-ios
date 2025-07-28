#import "WPImageExporter.h"

@import MobileCoreServices;
@import ImageIO;

@implementation WPImageExporter

+ (NSURL *)temporaryFileURLWithExtension:(NSString *)fileExtension
{
    NSAssert(fileExtension.length > 0, @"file Extension cannot be empty");
    NSString *fileName = [NSString stringWithFormat:@"%@_file.%@", NSProcessInfo.processInfo.globallyUniqueString, fileExtension];
    NSURL * fileURL = [[NSURL fileURLWithPath: NSTemporaryDirectory()] URLByAppendingPathComponent:fileName];
    return fileURL;
}

+ (BOOL)writeImage:(UIImage *)image withMetadata:(NSDictionary *)metadata toURL:(NSURL *)fileURL;
{
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:@{ (NSString *)kCGImageDestinationLossyCompressionQuality: @(0.9) }];

    NSMutableDictionary *adjustedMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];
    NSNumber *adjustedOrientation = @([self CGImagePropertyOrientationForUIImageOrientation: image.imageOrientation]);
    adjustedMetadata[(NSString *)kCGImagePropertyOrientation] = adjustedOrientation;

    if (adjustedMetadata[(NSString *)kCGImagePropertyTIFFDictionary] != nil) {
        NSMutableDictionary *adjustedTIFF = [[NSMutableDictionary alloc] initWithDictionary:adjustedMetadata[(NSString *)kCGImagePropertyTIFFDictionary]];
        adjustedTIFF[(NSString *)kCGImagePropertyTIFFOrientation] = adjustedOrientation;
        adjustedMetadata[(NSString *)kCGImagePropertyTIFFDictionary] = adjustedTIFF;
    }

    if (adjustedMetadata[(NSString *)kCGImagePropertyIPTCDictionary] != nil) {
        NSMutableDictionary *adjustedIPTC = [[NSMutableDictionary alloc] initWithDictionary:adjustedMetadata[(NSString *)kCGImagePropertyIPTCDictionary]];
        adjustedIPTC[(NSString *)kCGImagePropertyIPTCImageOrientation] = adjustedOrientation;
        adjustedMetadata[(NSString *)kCGImagePropertyIPTCDictionary] = adjustedIPTC;
    }

    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef)fileURL, kUTTypeJPEG, 1, nil);
    if (destination == NULL) {
        return NO;
    }
    CGImageRef imageRef = image.CGImage;

    CGImageDestinationSetProperties(destination, (CFDictionaryRef)properties);
    CGImageDestinationAddImage(destination, imageRef, (CFDictionaryRef)adjustedMetadata);

    BOOL result = CGImageDestinationFinalize(destination);

    CFRelease(destination);
    return result;
}

+ (CGImagePropertyOrientation) CGImagePropertyOrientationForUIImageOrientation:(UIImageOrientation) uiOrientation {
    switch (uiOrientation) {
        case UIImageOrientationUp: return kCGImagePropertyOrientationUp;
        case UIImageOrientationDown: return kCGImagePropertyOrientationDown;
        case UIImageOrientationLeft: return kCGImagePropertyOrientationLeft;
        case UIImageOrientationRight: return kCGImagePropertyOrientationRight;
        case UIImageOrientationUpMirrored: return kCGImagePropertyOrientationUpMirrored;
        case UIImageOrientationDownMirrored: return kCGImagePropertyOrientationDownMirrored;
        case UIImageOrientationLeftMirrored: return kCGImagePropertyOrientationLeftMirrored;
        case UIImageOrientationRightMirrored: return kCGImagePropertyOrientationRightMirrored;
    }
}

@end
