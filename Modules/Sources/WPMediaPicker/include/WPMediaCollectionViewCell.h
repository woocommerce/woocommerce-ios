@import UIKit;
#import "WPMediaCollectionDataSource.h"
#import "WPBadgeView.h"

@interface WPMediaCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) id<WPMediaAsset> asset;

@property (nonatomic, assign) NSInteger position;

@property (nonatomic, strong) UIColor *placeholderTintColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *loadingBackgroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *placeholderBackgroundColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *positionLabelUnselectedTintColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) BOOL hiddenSelectionIndicator;

@property (nonatomic, strong) UIView *overlayView;

@property (nonatomic, strong) WPBadgeView* badgeView;

@end

@protocol ReusableOverlayView <NSObject>

@optional

- (void)prepareForReuse;

@end

