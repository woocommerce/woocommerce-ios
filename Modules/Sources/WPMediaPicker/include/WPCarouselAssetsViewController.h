#import <UIKit/UIKit.h>
#import "WPMediaCollectionDataSource.h"
#import "WPAssetViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class WPCarouselAssetsViewController;


/**
 A protocol that has to be implemented when the carousel controller needs to present a custom external view controller
 to show an specific asset.
 */
@protocol WPCarouselAssetsViewControllerDelegate<NSObject>
/**
 Asks the delegate for a view controller to be presented, showing the given asset.

 @return The view controller to show, or nil to use the default internal WPAssetViewController.
 */
- (nullable UIViewController *)carouselController:(WPCarouselAssetsViewController *)controller viewControllerForAsset:(id<WPMediaAsset>)asset;

/**
 Asks the delegate for the asset object related to the given view controller.
 */
- (id<WPMediaAsset>)carouselController:(WPCarouselAssetsViewController *)controller assetForViewController:(UIViewController *)viewController;
@end


@interface WPCarouselAssetsViewController : UIPageViewController

@property (nonatomic, weak, nullable) id<WPAssetViewControllerDelegate> assetViewDelegate;

@property (nonatomic, weak, nullable) id<WPCarouselAssetsViewControllerDelegate> carouselDelegate;

/**
 Init a WPCarouselAssetsViewController with the list of assets to preview.

 @param assets An array of assets to show in the carousel preview.
 @return an initiated WPCarouselAssetsViewController.
 */
- (instancetype)initWithAssets:(NSArray<id<WPMediaAsset>> *)assets;


/**
 Set a new asset as the presenting asset in the carousel preview

 @param index Index of the asset to present
 @param animated Should the change be animated?
 */
- (void)setPreviewingAssetAtIndex:(NSInteger)index animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
