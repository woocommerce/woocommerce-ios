#import <Foundation/Foundation.h>
#import "WPMediaPickerOptions.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation WPMediaPickerOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _allowCaptureOfMedia = YES;
        _preferFrontCamera = NO;
        _showMostRecentFirst = NO;
        _filter = WPMediaTypeVideo | WPMediaTypeImage;
        _allowMultipleSelection = YES;
        _scrollVertically = YES;
        _showSearchBar = NO;
        _showActionBar = YES;
        _badgedUTTypes = [NSSet set];
        _preferredStatusBarStyle = UIStatusBarStyleDefault;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    WPMediaPickerOptions *options = [WPMediaPickerOptions new];
    options.allowCaptureOfMedia = self.allowCaptureOfMedia;
    options.preferFrontCamera = self.preferFrontCamera;
    options.showMostRecentFirst = self.showMostRecentFirst;
    options.filter = self.filter;
    options.allowMultipleSelection = self.allowMultipleSelection;
    options.scrollVertically = self.scrollVertically;
    options.showSearchBar = self.showSearchBar;
    options.showActionBar = self.showActionBar;
    options.badgedUTTypes = [self.badgedUTTypes copy];
    options.preferredStatusBarStyle = self.preferredStatusBarStyle;

    return options;
}

@end
