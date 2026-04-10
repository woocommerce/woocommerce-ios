@import UIKit;
#import "WPMediaCollectionDataSource.h"
#import "WPAssetViewController.h"
#import "WPMediaPickerOptions.h"
#import "WPActionBar.h"

@class WPMediaPickerViewController;
/**
 *  The `WPMediaPickerViewControllerDelegate` protocol defines methods that allow you to to interact with the assets picker interface
 *  and manage the selection and highlighting of assets in the picker.
 *
 *  The methods of this protocol notify your delegate when the user selects, finish picking assets, or cancels the picker operation.
 *
 *  The delegate methods are responsible for dismissing the picker when the operation completes.
 *  To dismiss the picker, call the `dismissViewControllerAnimated:completion:` method of the presenting controller
 *  responsible for displaying `WPMediaPickerController` object.
 *
 */
@protocol WPMediaPickerViewControllerDelegate <NSObject>

/**
 *  @name Closing the Picker
 */

/**
 *  Tells the delegate that the user finish picking photos or videos.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets An array containing picked `WPMediaAsset` objects.
 *
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didFinishPickingAssets:(nonnull NSArray<id<WPMediaAsset>> *)assets;

@optional

/**
 *  Tells the delegate that the user cancelled the pick operation.
 *
 *  @param picker The controller object managing the assets picker interface.
 *
 */
- (void)mediaPickerControllerDidCancel:(nonnull WPMediaPickerViewController *)picker;

/**
 *  @name Enabling Assets
 */

/**
 *  Ask the delegate if the specified asset shoule be shown.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be shown.
 *
 *  @return `YES` if the asset should be shown or `NO` if it should not.
 *
 */
- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldShowAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Ask the delegate if the specified asset should be enabled for selection.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be enabled.
 *
 *  @return `YES` if the asset should be enabled or `NO` if it should not.
 *
 */
- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldEnableAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  @name Managing the Selected Assets
 */

/**
 *  Asks the delegate if the specified asset should be selected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be selected.
 *
 *  @return `YES` if the asset should be selected or `NO` if it should not.
 *
 */
- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldSelectAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Tells the delegate that the asset was selected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset that was selected.
 *
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didSelectAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Asks the delegate if the specified asset should be deselected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be deselected.
 *
 *  @return `YES` if the asset should be deselected or `NO` if it should not.
 *
 *  @see assetsPickerController:shouldSelectAsset:
 */
- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldDeselectAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Tells the delegate that the item at the specified path was deselected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset that was deselected.
 *
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didDeselectAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Tells the delegate that the selection changed because of external events ( assets being deleted )
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets  The updated selected assets.
 *
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker selectionChanged:(nonnull NSArray<id<WPMediaAsset>> *)assets;

/**
 *  DEPRECATED: Use `mediaPickerController:previewViewControllerForAssets:selectedIndex`
 *  Asks the delegate for a view controller to push when previewing the specified asset.
 *  If this method isn't implemented, the default view controller will be used.
 *  If it returns nil, no preview will be displayed.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be previewed.
 */
- (nullable UIViewController *)mediaPickerController:(nonnull WPMediaPickerViewController *)picker previewViewControllerForAsset:(nonnull id<WPMediaAsset>)asset DEPRECATED_ATTRIBUTE;

/**
 *  Asks the delegate for a view controller to push when previewing the selected assets.
 *  If this method isn't implemented, the default preview view controller will be used.
 *  If it returns nil, the default preview view controller will be displayed.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets The selected assets.
 *  @param selected Index of asset tapped by the user to begin the preview
 */
- (nullable UIViewController *)mediaPickerController:(nonnull WPMediaPickerViewController *)picker previewViewControllerForAssets:(nonnull NSArray<id<WPMediaAsset>> *)assets selectedIndex:(NSInteger)selected;

/**
 *  Tells the delegate that the picker will begin requesting
 *  new data from its data source.
 */
- (void)mediaPickerControllerWillBeginLoadingData:(nonnull WPMediaPickerViewController *)picker;

/**
 *  Tells the delegate that the picker finished loading
 *  new data from its data source.
 */
- (void)mediaPickerControllerDidEndLoadingData:(nonnull WPMediaPickerViewController *)picker;

/**
 *  Asks the delegate whether an overlay view should be shown for the cell for
 *  the specified media asset. If you return `YES` from this method, you must
 *  have registered a reuse class through `-[WPMediaPickerViewController registerClassForReusableCellOverlayViews:]`.
 *
 *  @param asset The asset to display an overlay view for.
 *  @return `YES` if an overlay view should be displayed, `NO`, if not.
 *
 *  If this method is not implemented, no overlay view will be displayed.
 */
- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldShowOverlayViewForCellForAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Gives the delegate an opportunity to configure the overlay view for the
 *  specified media asset's cell. You can implement this method to update the
 *  overlay view as required for the asset (for example, to show a loading
 *  indicator if the asset is currently being loaded).
 *
 *  @param overlayView The overlay view to configure.
 *  @param asset       The asset to configure the overlay for.
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker willShowOverlayView:(nonnull UIView *)overlayView forCellForAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Asks the delegate to configure a custom header view. You must have registered a reuse class
 *  through `-[WPMediaPickerViewController registerClassForCustomHeaderView:]` and returned `YES`
 *  from `mediaPickerControllerShouldShowCustomHeaderView` otherwise this method will not be called.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param headerView An instance of the custom header view type to configure.
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker configureCustomHeaderView:(nonnull UICollectionReusableView *)headerView;

/**
 *  Asks the delegate whether a custom header view should be displayed.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @return `YES` if a custom header view should be shown, otherwise `NO`.
 */
- (BOOL)mediaPickerControllerShouldShowCustomHeaderView:(nonnull WPMediaPickerViewController *)picker;

/**
 *  Asks the delegate for a reference size for the registered custom header view, if one has been registered. This will only be called
 *  if `mediaPickerControllerShouldShowCustomHeaderView` has been implemented and returns `YES`.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @return A size for the header view to be displayed at.
 */
- (CGSize)mediaPickerControllerReferenceSizeForCustomHeaderView:(nonnull WPMediaPickerViewController *)picker;

/**
 *  Gives the delegate an oportunity to react to a change in the number
 *  of assets displayed as a consequence of a search filter.
 *
 *  @param assetCount The new asset count after a search filter is performed.
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didUpdateSearchWithAssetCount:(NSInteger)assetCount;

/**
 *  Asks the delegate for an empty view to show when there are no assets
 *  to be displayed. If no empty view is required, you have to implement this
 *  method and return `nil`.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @return An empty view to display or `nil` to not display any.
 *
 *  If this method is not implemented, a default UILabel will be displayed.
 *
 * `emptyViewControllerForMediaPickerController` takes precedence over this method.
 */
- (nullable UIView *)emptyViewForMediaPickerController:(nonnull WPMediaPickerViewController *)picker;

/**
 *  Asks the delegate for an empty view controller to show when there are no assets
 *  to be displayed. If no empty view is required, you have to implement this
 *  method and return `nil`.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @return An empty view controller to display or `nil` to not display any.
 *
 *  If this method is not implemented, a default ViewController with a default
 *  UILabel will be displayed.
 *
 *  This method takes precedence over `emptyViewForMediaPickerController`.
 */
- (nullable UIViewController *)emptyViewControllerForMediaPickerController:(nonnull WPMediaPickerViewController *)picker;

/** Asks the delegate to handle an error found by the picker
 *  If the method is not implemented or it returns NO the media picker will default to showing an alert with the an generic error message
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param error The error to show
 *  @return YES if the error was handled by the delegate
 */
- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker handleError:(nonnull NSError *)error;

@end


@interface WPMediaPickerViewController : UIViewController<WPAssetViewControllerDelegate>

- (instancetype _Nonnull )initWithOptions:(WPMediaPickerOptions *_Nonnull)options;

@property (nonatomic, copy, nonnull) WPMediaPickerOptions *options;

/**
 The collection view object managed by this view controller.
 */
@property (nonatomic, strong, nullable) UICollectionView *collectionView;

/**
 An array with the the assets that are currently selected.
 */
@property (nonatomic, copy, nonnull) NSArray<id<WPMediaAsset>> *selectedAssets;

/**
  The object that acts as the data source of the media picker.
 */
@property (nonatomic, weak, nullable) id<WPMediaCollectionDataSource> dataSource;

/**
 The delegate for the WPMediaPickerViewController events
 */
@property (nonatomic, weak, nullable) id<WPMediaPickerViewControllerDelegate> mediaPickerDelegate;

/**
 The search bar or nil if there is no search bar visible.
 @note Use options to make the search bar visible.
 */
@property (nonatomic, strong, readonly, nullable) UISearchBar *searchBar;

/**
 The default empty view. When `emptyViewForMediaPickerController:` is not implemented,
 use this property to style the message.
 */
@property (nonatomic, strong, readonly, nonnull) UILabel *defaultEmptyView;

/**
 A localized string that reflect the action that will be done when the user finishes picking assets.
 This string can contain a a placeholder for a numeric value that will indicate the number of media items selected.
 If this is nil the default value will be used. The default the value is 'Add %@'
 */
@property (nonatomic, copy, nullable) NSString *selectionActionTitle;

/**
 A localized string that reflect the action that will be done when the user chooses to preview the selected assets.
 This string can contain a a placeholder for a numeric value that will indicate the number of media items selected.
 If this is nil the default value will be used. The default the value is 'Preview %@'
 */
@property (nonatomic, copy, nullable) NSString *previewActionTitle;


/**
 The bottom bar used to show the action buttons.
 Use this instance to style the bar as required, or to add extra buttons.
 */
@property (nonatomic, strong, readonly, nullable) WPActionBar *actionBar;

/**
 Allows to set a group as the current display group on the data source. 
 */
- (void)setGroup:(nonnull id<WPMediaGroup>)group;

/**
 * Clears the current asset selection in the picker.
 */
- (void)clearSelectedAssets:(BOOL)animated;

/**
 * Presents the system image / video capture view controller, presented from `viewControllerToUseToPresent`.
 */
- (void)showCapture;

/**
 View controller to use when picker needs to present another controller. By default this is set to self.
 @note If the picker is being used within an input view, it's important to set this value to something besides the picker itself.
 */
@property (nonatomic, weak, nullable) UIViewController *viewControllerToUseToPresent;

/**
 Clears all selection and scroll the picker to the starting position
 */
- (void)resetState:(BOOL)animated;

/**
 Return the default preview view controller to use to preview assets

 @param asset the asset to preview
 @return a view controller to preview the asset
 */
- (nonnull UIViewController *)defaultPreviewViewControllerForAsset:(nonnull id<WPMediaAsset>)asset;

/**
 Return a View Controller to present `defaultEmptyView`.
 
 @return a view controller to present the empty view.
 */
- (nonnull UIViewController *)defaultEmptyViewController;

/**
 Calculates the appropriate cell height/width given the desired number of cells per line, desired space
 between cells, and total width of the frame containing the cells.

 @param photosPerLine The number of desired photos per line
 @param photoSpacing The amount of space in between photos
 @param frameWidth The width of the frame which contains the photo cells
 @return A CGFloat representing the height/width of the suggested cell size
 */
- (CGFloat)cellSizeForPhotosPerLineCount:(NSUInteger)photosPerLine photoSpacing:(CGFloat)photoSpacing frameWidth:(CGFloat)frameWidth;

/**
 Register a `UIView` subclass to use for overlay views applied to cells. For
 overlays to be displayed, you must register a class using this method, and then
 return `YES` from `mediaPickerController:shouldShowOverlayViewForCellForAsset:`
 */
- (void)registerClassForReusableCellOverlayViews:(nonnull Class)overlayClass;

/**
 Register a `UICollectionReusableView` subclass to be displayed as an optional header at the top of the picker view.
 For the header to be displayed, you must register a class using this method, and then
 return a configured instance from `customHeaderViewForMediaPickerController:`
 */
- (void)registerClassForCustomHeaderView:(nonnull Class)overlayClass;

/**
 Shows the search bar that was hidden by `hideSearchBar`. If the
 `showSearchBar` option is set to `NO`, and the data source does not implement
 `searchFor:`, this method will do nothing.
 
 @see hideSearchBar
 */
- (void)showSearchBar;


/**
 Hides the presented search bar.
 */
- (void)hideSearchBar;

@end
