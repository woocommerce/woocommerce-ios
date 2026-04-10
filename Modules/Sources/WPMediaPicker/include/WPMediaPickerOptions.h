#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WPMediaCollectionDataSource.h"

@interface WPMediaPickerOptions: NSObject<NSCopying>

/**
 If YES the picker will show a cell that allows capture of new media, that can be used immediatelly
 */
@property (nonatomic, assign) BOOL allowCaptureOfMedia;

/**
 If YES and the media picker allows media capturing, it will use the front camera by default when possible
 */
@property (nonatomic, assign) BOOL preferFrontCamera;

/**
 If YES the picker will show the most recent items on the top left. If not set it will show on the bottom right. Either way it will always scroll to the most recent item when showing the picker.
 */
@property (nonatomic, assign) BOOL showMostRecentFirst;

/**
 *  Sets what kind of elements the picker show: allAssets, allPhotos, allVideos
 */
@property (nonatomic, assign) WPMediaType filter;

/**
 If YES the picker will allow the selection of multiple items. By default this value is YES.
 */
@property (nonatomic, assign) BOOL allowMultipleSelection;

/**
 If YES the picker will scroll media vertically. Defaults to YES (vertical).
 */
@property (nonatomic, assign) BOOL scrollVertically;

/**
 If YES the picker will show a search bar on top.
 */
@property (nonatomic, assign) BOOL showSearchBar;

/**
 If YES, the picker will use a bottom action bar instead of the top right action button for multiple selection. By default the value is YES.
 */
@property (nonatomic, assign) BOOL showActionBar;

/**
 A list of UTTypes where the picker cell should show a badge showing the file type. (i.e. UTTypeGif)
 */
@property (nonatomic, strong, nonnull) NSSet<NSString *> *badgedUTTypes;

/**
 The status bar style to use for the media picker.
 */
@property (nonatomic, assign) UIStatusBarStyle preferredStatusBarStyle;

@end
