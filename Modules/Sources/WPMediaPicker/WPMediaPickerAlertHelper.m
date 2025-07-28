#import "WPMediaPickerAlertHelper.h"
#import "WPMediaCollectionDataSource.h"

@implementation WPMediaPickerAlertHelper

+ (nonnull UIAlertController *)buildAlertControllerWithError:(NSError * _Nullable)error
                                             okActionHandler:(void (^ __nullable)(UIAlertAction * _Nullable action))handler {
    NSString *title = NSLocalizedString(@"Media Library", @"Title for alert when a generic error happened when loading media");
    NSString *message = NSLocalizedString(@"There was a problem when trying to access your media. Please try again later.",  @"Explaining to the user there was an generic error accesing media.");
    NSString *cancelText = NSLocalizedString(@"OK", "");
    NSString *otherButtonTitle = nil;
    if (error.domain == WPMediaPickerErrorDomain) {
        title = NSLocalizedString(@"Media Library", @"Title for alert when access to the media library is not granted by the user");
        if (error.code == WPMediaPickerErrorCodePermissionDenied) {
            otherButtonTitle = NSLocalizedString(@"Open Settings", @"Go to the settings app");
            message = NSLocalizedString(@"This app needs permission to access your device media library in order to add photos and/or video to your posts. Please change the privacy settings if you wish to allow this.",
                    @"Explaining to the user why the app needs access to the device media library.");
        } else if (error.code == WPMediaPickerErrorCodeRestricted) {
            message = NSLocalizedString(@"Your app is not authorized to access media library due to active restrictions such as parental controls. Please check your parental control settings in this device.",
                    @"Explaining to the user why the app needs access to the device media library.");
        }
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:cancelText
                                                       style:UIAlertActionStyleCancel
                                                     handler:handler];
    [alertController addAction:okAction];

    if (otherButtonTitle) {
        UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
        }];
        [alertController addAction:otherAction];
    }

    return alertController;
}

@end
