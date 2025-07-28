#import "WPMediaPickerViewController.h"
#import "WPMediaCollectionViewCell.h"
#import "WPMediaCapturePreviewCollectionView.h"
#import "WPMediaPickerViewController.h"
#import "WPMediaGroupPickerViewController.h"
#import "WPPHAssetDataSource.h"
#import "WPMediaCapturePresenter.h"
#import "WPInputMediaPickerViewController.h"
#import "WPCarouselAssetsViewController.h"
#import "UIViewController+MediaAdditions.h"

@import MobileCoreServices;
@import AVFoundation;

static CGFloat const IPhoneSELandscapeWidth = 568.0f;
static CGFloat const IPhone7PortraitWidth = 375.0f;
static CGFloat const IPhone7LandscapeWidth = 667.0f;
static CGFloat const IPadPortraitWidth = 768.0f;
static CGFloat const IPadLandscapeWidth = 1024.0f;
static CGFloat const IPadPro12LandscapeWidth = 1366.0f;
static NSString *const CustomHeaderReuseIdentifier = @"CustomHeaderReuseIdentifier";

@interface WPMediaPickerViewController ()
<
 UICollectionViewDataSource,
 UICollectionViewDelegate,
 UIImagePickerControllerDelegate,
 UINavigationControllerDelegate,
 UICollectionViewDelegateFlowLayout,
 UISearchBarDelegate
>

@property (nonatomic, readonly) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSMutableArray *internalSelectedAssets;
@property (nonatomic, strong) id<WPMediaAsset> capturedAsset;
@property (nonatomic, strong) WPMediaCapturePreviewCollectionView *captureCell;
@property (nonatomic, strong) WPMediaCapturePresenter *capturePresenter;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSObject *changesObserver;
@property (nonatomic, strong) NSIndexPath *firstVisibleCell;
@property (nonatomic, assign) BOOL refreshGroupFirstTime;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) NSIndexPath *assetIndexInPreview;

@property (nonatomic, strong, nullable) Class overlayViewClass;

@property (nonatomic, strong, readwrite) UISearchBar *searchBar;
@property (nonatomic, strong) NSLayoutConstraint *searchBarTopConstraint;
@property (nonatomic, assign) CGFloat currentKeyboardHeight;

@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) UIView *emptyViewContainer;
@property (nonatomic, strong) UILabel *defaultEmptyView;
@property (nonatomic, strong) UIViewController *emptyViewController;
@property (nonatomic, strong) UIViewController *defaultEmptyViewController;
@property (nonatomic, strong) NSLayoutConstraint *emptyViewBottomConstraint;

@property (nonatomic, strong) WPActionBar *accessoryActionBar;
@property (nonatomic, strong) UIButton *selectedActionButton;
@property (nonatomic, strong) UIButton *previewActionButton;

/**
 The size of the camera preview cell
 */
@property (nonatomic, assign) CGSize cameraPreviewSize;

@end

@implementation WPMediaPickerViewController

static CGFloat SelectAnimationTime = 0.2;

- (instancetype)init
{
    return [self initWithOptions:[WPMediaPickerOptions new]];
}

- (instancetype)initWithOptions:(WPMediaPickerOptions *)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:(CGRectZero) collectionViewLayout:layout];
        _internalSelectedAssets = [[NSMutableArray alloc] init];
        _capturedAsset = nil;
        _options = [options copy];
        _refreshGroupFirstTime = YES;
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressOnAsset:)];
        _viewControllerToUseToPresent = self;
    }
    return self;
}

- (void)dealloc
{
    [self unregisterDataSourceObservers];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup subviews
    [self setupPullToRefresh];
    [self addCollectionViewToView];
    [self setupCollectionView];
    [self setupSearchBar];
    [self setupLayout];
    [self addEmptyViewContainer];

    //setup data
    [self.dataSource setMediaTypeFilter:self.options.filter];
    [self.dataSource setAscendingOrdering:!self.options.showMostRecentFirst];

    [self.view addGestureRecognizer:self.longPressGestureRecognizer];

    self.layout.sectionInsetReference = UICollectionViewFlowLayoutSectionInsetFromSafeArea;
    
    [self refreshDataAnimated:NO];
}

- (void)setupPullToRefresh
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
}

- (void)registerDataSourceObservers {
    __weak __typeof__(self) weakSelf = self;
    self.changesObserver = [self.dataSource registerChangeObserverBlock:
                            ^(BOOL incrementalChanges, NSIndexSet *removed, NSIndexSet *inserted, NSIndexSet *changed, NSArray *moves) {
                                // If the view is not loaded or a refresh of data is going on, ignore changes on the data in the meantime.
                                if (!weakSelf.isViewLoaded || weakSelf.refreshGroupFirstTime || weakSelf.refreshControl.isRefreshing) {
                                    return;
                                }
                                if (incrementalChanges) {
                                    /// Avoid NSInternalInconsistencyException crash by wrapping performBatchUpdates in the try catch block.
                                    ///
                                    /// Apple documentation indicates if the collection view’s layout isn’t up to date before you call performBatchUpdates,
                                    /// additional reload may occur that can cause problems. Developers should update the data model inside the updates
                                    /// block or ensure the layout is updated before calling performBatchUpdates.
                                    /// However, MediaLibraryPickerDataSource reloads the data source before view controller gets informed about updates,
                                    /// creating a possibility for a crash.
                                    /// https://developer.apple.com/documentation/uikit/uicollectionview/1618045-performbatchupdates
                                    ///
                                    /// Apple engineers reiterate this fact and point out the best way to avoid this issue is to adopt
                                    /// UICollectionViewDiffableDataSource which requires refactoring of the current solution
                                    /// https://developer.apple.com/forums/thread/728797?answerId=751887022#751887022
                                    
                                    @try {
                                        [weakSelf updateDataWithRemoved:removed inserted:inserted changed:changed moved:moves];
                                    } @catch (NSException *exception) {
                                        [weakSelf.collectionView reloadData];
                                    }
                                } else {
                                    [weakSelf.collectionView reloadData];
                                }
                            }];
}

- (void)unregisterDataSourceObservers {
    if (_changesObserver) {
        [_dataSource unregisterChangeObserver:_changesObserver];
    }
}

- (void)setDataSource:(id<WPMediaCollectionDataSource>)dataSource {
    [self unregisterDataSourceObservers];
    _dataSource = dataSource;
    [self registerDataSourceObservers];
}

- (void)setOptions:(WPMediaPickerOptions *)options {
    WPMediaPickerOptions *originalOptions = _options;
    _options = [options copy];

    if (!self.viewLoaded) {
        return;
    }

    [self.dataSource setMediaTypeFilter:options.filter];
    [self.dataSource setAscendingOrdering:!options.showMostRecentFirst];
    self.collectionView.allowsMultipleSelection = options.allowMultipleSelection;
    self.collectionView.alwaysBounceHorizontal = !options.scrollVertically;
    self.collectionView.alwaysBounceVertical = options.scrollVertically;

    BOOL refreshNeeded = (originalOptions.filter != options.filter) ||
    (originalOptions.showMostRecentFirst != options.showMostRecentFirst) ||
    (originalOptions.allowCaptureOfMedia != options.allowCaptureOfMedia);

    if (refreshNeeded) {
        [self refreshDataAnimated:NO];
    } else {
        // if just the selection mode changed we just need to reload the collection view not all the data.
        if (originalOptions.allowMultipleSelection != options.allowMultipleSelection || options.allowCaptureOfMedia != originalOptions.allowCaptureOfMedia) {
            [self.collectionView reloadData];
        }
    }

    [self setupSearchBar];
}

- (void)registerClassForReusableCellOverlayViews:(Class)overlayClass
{
    NSParameterAssert([overlayClass isSubclassOfClass:[UIView class]]);

    self.overlayViewClass = overlayClass;
}

- (void)registerClassForCustomHeaderView:(Class)overlayClass
{
    NSParameterAssert([overlayClass isSubclassOfClass:[UICollectionReusableView class]]);

    [self.collectionView registerClass:overlayClass
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:CustomHeaderReuseIdentifier];
}

- (UICollectionViewFlowLayout *)layout
{
    return (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}

- (void)setupLayout
{
    CGFloat photoSpacing = 1.0f;
    CGFloat photoSize;
    UICollectionViewFlowLayout *layout = self.layout;
    CGFloat frameWidth = self.view.frame.size.width;
    CGFloat frameHeight = self.view.frame.size.width - self.view.safeAreaInsets.bottom - self.view.safeAreaInsets.top;
    CGFloat dimensionToUse;
    if (self.options.scrollVertically) {
        dimensionToUse = frameWidth;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.sectionInset = UIEdgeInsetsMake(2, 0, 0, 0);
    } else {
        dimensionToUse = frameHeight;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(5, 0, 5, 0);
    }
    NSUInteger numberOfPhotosForLine = [self numberOfPhotosPerRow:dimensionToUse];

    photoSize = [self cellSizeForPhotosPerLineCount:numberOfPhotosForLine
                                       photoSpacing:photoSpacing
                                         frameWidth:dimensionToUse];

    self.cameraPreviewSize = CGSizeMake(photoSize, photoSize);
    layout.itemSize = CGSizeMake(photoSize, photoSize);
    layout.minimumLineSpacing = photoSpacing;
    layout.minimumInteritemSpacing = photoSpacing;

    [self resetContentInset];
    [self.view layoutIfNeeded];
}

- (void)resetContentInset
{
    CGFloat searchBarHeight = self.searchBar.bounds.size.height;
    self.additionalSafeAreaInsets = UIEdgeInsetsMake(searchBarHeight, 0, 0, 0);
    self.searchBarTopConstraint.constant = self.view.safeAreaInsets.top - searchBarHeight;
}

- (CGFloat)cellSizeForPhotosPerLineCount:(NSUInteger)photosPerLine photoSpacing:(CGFloat)photoSpacing frameWidth:(CGFloat)frameWidth
{
    CGFloat totalSpacing = (photosPerLine - 1) * photoSpacing;
    return floorf((frameWidth - totalSpacing) / photosPerLine);
}

/**
 Given the provided frame width, this method returns a progressively increasing number of photos
 to be used in a picker row.

 @param frameWidth Width of the frame containing the picker

 @return The number of photo cells to be used in a row. Defaults to 3.
 */
- (NSUInteger)numberOfPhotosPerRow:(CGFloat)frameWidth {
    NSUInteger numberOfPhotos = 3;

    if (frameWidth >= IPhone7PortraitWidth && frameWidth < IPhoneSELandscapeWidth) {
        numberOfPhotos = 4;
    } else if (frameWidth >= IPhoneSELandscapeWidth && frameWidth < IPhone7LandscapeWidth) {
        numberOfPhotos = 5;
    } else if (frameWidth >= IPhone7LandscapeWidth && frameWidth < IPadPortraitWidth) {
        numberOfPhotos = 6;
    } else if (frameWidth >= IPadPortraitWidth && frameWidth < IPadLandscapeWidth) {
        numberOfPhotos = 7;
    } else if (frameWidth >= IPadLandscapeWidth && frameWidth < IPadPro12LandscapeWidth) {
        numberOfPhotos = 9;
    } else if (frameWidth >= IPadPro12LandscapeWidth) {
        numberOfPhotos = 12;
    }

    return numberOfPhotos;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self setupLayout];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.captureCell stopCaptureOnCompletion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.captureCell startCapture];
    [self registerForKeyboardNotifications];
    [self updateActionbar];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self unregisterForKeyboardNotifications];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    if ([self shouldShowCustomHeaderView]) {
        // If there's a custom header, we'll invalidate it so that it can adapt itself to dynamic type changes.
        UICollectionViewFlowLayoutInvalidationContext *context  = [UICollectionViewFlowLayoutInvalidationContext new];
        [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ]];
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
}

- (UIViewController *)viewControllerToUseToPresent
{
    // viewControllerToUseToPresent defaults to self but could be set to nil. Reset to self if needed.
    if (!_viewControllerToUseToPresent) {
        _viewControllerToUseToPresent = self;
    }

    return _viewControllerToUseToPresent;
}

- (void)setupCollectionView
{
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;

    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = self.options.allowMultipleSelection;
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceHorizontal = !self.options.scrollVertically;
    self.collectionView.alwaysBounceVertical = self.options.scrollVertically;

    self.collectionView.accessibilityIdentifier = @"MediaCollection";
    
    // Register cell classes
    [self.collectionView registerClass:[WPMediaCollectionViewCell class]
            forCellWithReuseIdentifier:NSStringFromClass([WPMediaCollectionViewCell class])];
    [self.collectionView registerClass:[WPMediaCapturePreviewCollectionView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:NSStringFromClass([WPMediaCapturePreviewCollectionView class])];
    [self.collectionView registerClass:[WPMediaCapturePreviewCollectionView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:NSStringFromClass([WPMediaCapturePreviewCollectionView class])];
}

- (void)addCollectionViewToView
{
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:
     @[
       [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
       [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
       [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
       ]
     ];
}

- (void)setupSearchBar
{
    BOOL shouldShowSearchBar = self.options.showSearchBar &&
        ![self.parentViewController isKindOfClass:[WPInputMediaPickerViewController class]] && //Disable search bar on WPInputMediaPicker
        [self.dataSource respondsToSelector:@selector(searchFor:)];

    if (shouldShowSearchBar && self.searchBar == nil) {
        self.searchBar = [[UISearchBar alloc] init];
        self.searchBar.delegate = self;
        self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSearchBarToView];
    } else if (!shouldShowSearchBar && self.searchBar) {
        [self hideSearchBar];
    }
}

- (void)showSearchBar
{
    [self setupSearchBar];
}

- (void)hideSearchBar
{
    [self.searchBar removeFromSuperview];
    self.searchBar = nil;
}

- (void)addSearchBarToView
{
    [self.searchBar sizeToFit];
    [self.view addSubview:self.searchBar];
    self.searchBarTopConstraint = [self.searchBar.topAnchor constraintEqualToAnchor:self.view.topAnchor];

    [NSLayoutConstraint activateConstraints:
     @[
       self.searchBarTopConstraint,
       [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
       ]
     ];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.options.preferredStatusBarStyle;
}

#pragma mark - Action bar

- (UIView *)actionBar
{
    return self.accessoryActionBar;
}

- (WPActionBar *)accessoryActionBar
{
    if (_accessoryActionBar) {
        return _accessoryActionBar;
    }
    _accessoryActionBar = [[WPActionBar alloc] init];

    [_accessoryActionBar addLeftButton:self.previewActionButton];
    [_accessoryActionBar addRightButton:self.selectedActionButton];
    [_accessoryActionBar sizeToFit];

    return _accessoryActionBar;
}

- (UIButton *)previewActionButton
{
    if (_previewActionButton) {
        return _previewActionButton;
    }

    _previewActionButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [_previewActionButton addTarget:self action:@selector(onPreviewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_previewActionButton setTitle:self.previewActionTitle forState:UIControlStateNormal];
    _previewActionButton.accessibilityIdentifier = @"PreviewButton";

    return _previewActionButton;
}

- (UIButton *)selectedActionButton
{
    if (_selectedActionButton) {
        return _selectedActionButton;
    }

    _selectedActionButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    UIFont *font = _selectedActionButton.titleLabel.font;
    _selectedActionButton.titleLabel.font = [UIFont boldSystemFontOfSize:font.pointSize];
    [_selectedActionButton addTarget:self action:@selector(onAddButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_selectedActionButton setTitle:self.selectionActionTitle forState:UIControlStateNormal];
    _selectedActionButton.accessibilityIdentifier = @"SelectedActionButton";

    return _selectedActionButton;
}

- (NSString *)previewActionTitle
{
    NSString *actionString = _previewActionTitle;
    if (actionString == nil) {
        actionString = NSLocalizedString(@"Preview %@", @"Action for Media Picker to preview the selected media items. The argument in the string represents the number of elements (as numeric digits) selected");
    }
    return [self formatButtonTitleWithTitlePlaceholder:actionString];
}

- (NSString *)selectionActionTitle
{
    NSString *actionString = _selectionActionTitle;
    if (actionString == nil) {
        actionString = NSLocalizedString(@"Add %@", @"Action for Media Picker to indicate selection of media. The argument in the string represents the number of elements (as numeric digits) selected");
    }
    return [self formatButtonTitleWithTitlePlaceholder:actionString];
}

- (NSString *)formatButtonTitleWithTitlePlaceholder:(NSString *)placeholder
{
    NSString * countString = @(self.internalSelectedAssets.count).stringValue;
    return [NSString stringWithFormat:placeholder, countString];
}

- (void)updateActionbar
{
    if ([self shouldShowActionBar]) {
        [UIView performWithoutAnimation:^{
            [self.previewActionButton setTitle:self.previewActionTitle forState:UIControlStateNormal];
            [self.selectedActionButton setTitle:self.selectionActionTitle forState:UIControlStateNormal];
            [self.previewActionButton layoutIfNeeded];
            [self.selectedActionButton layoutIfNeeded];
        }];

        if ([self.searchBar isFirstResponder]) {
            [self.searchBar reloadInputViews];
        } else {
            [self becomeFirstResponder];
        }
    } else {
        if ([self isFirstResponder]) {
            [self resignFirstResponder];
        } else {
            [self.searchBar reloadInputViews];
        }
    }
}

- (BOOL)canBecomeFirstResponder
{
    return [self shouldShowActionBar];
}

- (UIView *)inputAccessoryView
{
    if ([self shouldShowActionBar]) {
        return self.accessoryActionBar;
    }
    return nil;
}

- (BOOL)shouldShowActionBar
{
    return self.options.showActionBar && self.options.allowMultipleSelection && self.internalSelectedAssets.count > 0;
}

- (void)onPreviewButtonPressed:(UIBarButtonItem *)sender
{
    UIViewController *previewController = [self previewViewControllerForAsset:[self.selectedAssets firstObject]];
    [self displayPreviewController:previewController];
}

- (void)onAddButtonPressed:(UIBarButtonItem *)sender
{
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
        [self.mediaPickerDelegate mediaPickerController:self didFinishPickingAssets:[self.internalSelectedAssets copy]];
    }
}

#pragma mark - Actions

- (void)pullToRefresh:(id)sender
{
    [self refreshData];
}

- (BOOL)isShowingCaptureCell
{
    return self.options.allowCaptureOfMedia && [WPMediaCapturePresenter isCaptureAvailable] && !self.refreshGroupFirstTime;
}

- (void)clearSelectedAssets:(BOOL)animated
{
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForSelectedItems]) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:animated];
    }

    [self.internalSelectedAssets removeAllObjects];
}

- (void)resetState:(BOOL)animated {
    [self clearSelectedAssets:animated];
    [self scrollToStart:animated];
}

- (void)scrollToStart:(BOOL)animated {
    if ([self.dataSource numberOfAssets] == 0) {
        return;
    }

    NSInteger sectionToScroll = 0;
    NSInteger itemToScroll = self.options.showMostRecentFirst ? 0 : [self.dataSource numberOfAssets] - 1;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemToScroll inSection:sectionToScroll];
    UICollectionViewScrollPosition position = UICollectionViewScrollPositionBottom;
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    if (layout && layout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        position = UICollectionViewScrollPositionCenteredHorizontally;
    }
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:position
                                        animated:animated];
}

- (void)showCapture {
    [self captureMedia];
    return;
}

#pragma mark - Empty View support

/** An empty view container to hold the emptyViewController or emptyView that comes from the delegate
 */
- (void)addEmptyViewContainer
{
    self.emptyViewContainer = [[UIView alloc] initWithFrame:self.collectionView.frame];
    [self.emptyViewContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.collectionView addSubview:self.emptyViewContainer];
    
    self.emptyViewBottomConstraint = [self.emptyViewContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];
    [self.emptyViewBottomConstraint setConstant:-self.currentKeyboardHeight];

    [NSLayoutConstraint activateConstraints:
     @[
       [self.emptyViewContainer.topAnchor constraintEqualToAnchor:self.collectionView.topAnchor],
       self.emptyViewBottomConstraint,
       [self.emptyViewContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [self.emptyViewContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
       ]
     ];
}

- (UIView *)emptyView
{
    if (_emptyView) {
        return _emptyView;
    }

    if ([self.mediaPickerDelegate respondsToSelector:@selector(emptyViewForMediaPickerController:)]) {
        _emptyView = [self.mediaPickerDelegate emptyViewForMediaPickerController:self];
    } else {
        _emptyView = [self defaultEmptyView];
    }

    return _emptyView;
}

/** Checks if the parentViewController is providing a custom empty ViewController to be added, if not, add a provided custom emptyView
 */
- (void)populateEmptyViewContainer
{
    if ([self usingEmptyViewController]) {
        [self addEmptyViewControllerToContainer];
    } else {
        [self addEmptyViewToContainer];
    }
}

- (UILabel *)defaultEmptyView
{
    if (_defaultEmptyView) {
        return _defaultEmptyView;
    }
    _defaultEmptyView = [[UILabel alloc] init];
    _defaultEmptyView.text = NSLocalizedString(@"Nothing to show", @"Default message for empty media picker");
    [_defaultEmptyView sizeToFit];
    return _defaultEmptyView;
}

- (void)addEmptyViewToContainer
{
    if (self.emptyView != nil && self.emptyView.superview != nil) {
        return;
    }

    [self.emptyView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.emptyViewContainer addSubview:self.emptyView];
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.emptyView.centerYAnchor constraintEqualToAnchor:self.emptyViewContainer.centerYAnchor],
       [self.emptyView.centerXAnchor constraintEqualToAnchor:self.emptyViewContainer.centerXAnchor]
       ]
     ];
}

#pragma mark - Empty View Controller support

- (void)addEmptyViewControllerToContainer
{
    if (self.emptyViewController != nil && self.emptyViewController.view.superview != nil) {
        return;
    }

    [self addChildViewController:self.emptyViewController];
    [self.emptyViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.emptyViewContainer addSubview:self.emptyViewController.view];

    [NSLayoutConstraint activateConstraints:
     @[
       [self.emptyViewController.view.topAnchor constraintEqualToAnchor:self.emptyViewContainer.topAnchor],
       [self.emptyViewController.view.bottomAnchor constraintEqualToAnchor:self.emptyViewContainer.bottomAnchor],
       [self.emptyViewController.view.leadingAnchor constraintEqualToAnchor:self.emptyViewContainer.leadingAnchor],
       [self.emptyViewController.view.trailingAnchor constraintEqualToAnchor:self.emptyViewContainer.trailingAnchor]
       ]
     ];

    [self.emptyViewController didMoveToParentViewController:self];
}

- (UIViewController *)emptyViewController
{
    if (_emptyViewController) {
        return _emptyViewController;
    }
    
    if ([self usingEmptyViewController]) {
        _emptyViewController = [self.mediaPickerDelegate emptyViewControllerForMediaPickerController:self];
    }

    if (_emptyViewController == nil) {
        _emptyViewController = self.defaultEmptyViewController;
    }
    
    return _emptyViewController;
}

- (UIViewController *)defaultEmptyViewController
{
    if (_defaultEmptyViewController) {
        return _defaultEmptyViewController;
    }

    _defaultEmptyViewController = [[UIViewController alloc] init];
    UILabel *emptyViewLabel = self.defaultEmptyView;
    [emptyViewLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[_defaultEmptyViewController view] addSubview:emptyViewLabel];

    [NSLayoutConstraint activateConstraints:
     @[
       [emptyViewLabel.centerYAnchor constraintEqualToAnchor:self.defaultEmptyViewController.view.centerYAnchor],
       [emptyViewLabel.centerXAnchor constraintEqualToAnchor:self.defaultEmptyViewController.view.centerXAnchor]
       ]
     ];

    return _defaultEmptyViewController;
}

- (BOOL)usingEmptyViewController
{
    return [self.mediaPickerDelegate respondsToSelector:@selector(emptyViewControllerForMediaPickerController:)];
}

#pragma mark - UICollectionViewDataSource

- (void)updateDataWithRemoved:(NSIndexSet *)removed inserted:(NSIndexSet *)inserted changed:(NSIndexSet *)changed moved:(NSArray<id<WPMediaMove>> *)moves {
    if ([removed containsIndex:self.assetIndexInPreview.item]){
        self.assetIndexInPreview = nil;
    }
    __weak __typeof__(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        if ([removed count] > 0) {
            [self.collectionView deleteItemsAtIndexPaths:[self indexPathsFromIndexSet:removed section:0]];
        }
        if ([inserted count] > 0) {
            [self.collectionView insertItemsAtIndexPaths:[self indexPathsFromIndexSet:inserted section:0]];
        }
        for (id<WPMediaMove> move in moves) {
            [self.collectionView moveItemAtIndexPath:[NSIndexPath indexPathForItem:[move from] inSection:0]
                                         toIndexPath:[NSIndexPath indexPathForItem:[move to] inSection:0]];
            if (self.assetIndexInPreview.row == move.from) {
                self.assetIndexInPreview = [NSIndexPath indexPathForItem:move.to inSection:0];
            }
        }
    } completion:^(BOOL finished) {
        if (weakSelf == nil) {
            return;
        }
        [weakSelf refreshSelection];

        @try {
            // Reloading the changed items here rather than in the batch update block above to fix this issue:
            // https://github.com/wordpress-mobile/WordPress-iOS/issues/19505
            NSMutableSet<NSIndexPath *> *indexPaths = [NSMutableSet setWithArray:[weakSelf indexPathsFromIndexSet:changed section:0]];
            [indexPaths addObjectsFromArray:weakSelf.collectionView.indexPathsForSelectedItems];
            [weakSelf.collectionView reloadItemsAtIndexPaths:[indexPaths allObjects]];
        } @catch (NSException *exception) {
            [weakSelf.collectionView reloadData];
        }
    }];

}

- (NSArray *)indexPathsFromIndexSet:(NSIndexSet *)indexSet section:(NSInteger)section{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:indexSet.count];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return [NSArray arrayWithArray:indexPaths];
}

- (void)refreshData
{
    [self refreshDataAnimated:YES];
}

- (void)refreshDataAnimated:(BOOL)animated
{
    // Don't show the refreshControl if emptyViewController is being displayed.
    if (! _emptyViewController) {
        [self.refreshControl beginRefreshing];
    }

    self.collectionView.allowsSelection = NO;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.scrollEnabled = NO;

    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerWillBeginLoadingData:)]) {
        [self.mediaPickerDelegate mediaPickerControllerWillBeginLoadingData:self];
    }

    __weak __typeof__(self) weakSelf = self;

    [self.dataSource loadDataWithOptions:WPMediaLoadOptionsAssets success:^{
        __typeof__(self) strongSelf = weakSelf;
        BOOL refreshGroupFirstTime = strongSelf.refreshGroupFirstTime;
        strongSelf.refreshGroupFirstTime = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.collectionView.allowsSelection = YES;
            strongSelf.collectionView.allowsMultipleSelection = strongSelf.options.allowMultipleSelection;
            strongSelf.collectionView.scrollEnabled = YES;
            [strongSelf refreshSelection];
            [strongSelf.collectionView reloadData];

            if (animated) {
                [strongSelf.refreshControl endRefreshing];
            } else {
                [UIView performWithoutAnimation:^{
                    [strongSelf.refreshControl endRefreshing];
                }];
            }

            // Scroll to the correct position
            if (refreshGroupFirstTime){
                [strongSelf scrollToStart:NO];
            }

            [strongSelf informDelegateDidEndLoadingData];
        });
    } failure:^(NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        strongSelf.refreshGroupFirstTime = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf informDelegateDidEndLoadingData];
            [strongSelf showError:error];
        });
    }];
}

- (void)informDelegateDidEndLoadingData
{
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerDidEndLoadingData:)]) {
        [self.mediaPickerDelegate mediaPickerControllerDidEndLoadingData:self];
    }
}

- (void)showError:(NSError *)error {
    [self.refreshControl endRefreshing];
    self.collectionView.allowsSelection = YES;
    self.collectionView.scrollEnabled = YES;
    [self.collectionView reloadData];
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:handleError:)]) {
        if ([self.mediaPickerDelegate mediaPickerController:self handleError:error]) {
            return;
        }
    }
    [self wpm_showAlertWithError:error okActionHandler:^(UIAlertAction * _Nonnull action) {
        if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
            [self.mediaPickerDelegate mediaPickerControllerDidCancel:self];
        }
    }];
}

- (void)setSelectedAssets:(NSArray *)selectedAssets {
    self.internalSelectedAssets = [selectedAssets copy];
    if ([self isViewLoaded]) {
        [self refreshDataAnimated: NO];
    }
}

- (NSArray *)selectedAssets {
    return [self.internalSelectedAssets copy];
}

- (void)refreshSelection
{
    NSArray *selectedAssets = [NSArray arrayWithArray:self.internalSelectedAssets];
    NSMutableArray *stillExistingSeletedAssets = [NSMutableArray array];
    for (id<WPMediaAsset> asset in selectedAssets) {
        NSString *assetIdentifier = [asset identifier];
        if ([self.dataSource mediaWithIdentifier:assetIdentifier]) {
            [stillExistingSeletedAssets addObject:asset];
        }
    }
    if (self.capturedAsset != nil) {
        NSString *assetIdentifier = [self.capturedAsset identifier];
        if ([self.dataSource mediaWithIdentifier:assetIdentifier]) {
            [stillExistingSeletedAssets addObject:self.capturedAsset];
        }
        NSInteger positionToUpdate = self.options.showMostRecentFirst ? 0 : self.dataSource.numberOfAssets-1;
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:positionToUpdate inSection:0]
                                          animated:NO
                                    scrollPosition:UICollectionViewScrollPositionNone];
        self.capturedAsset = nil;
    }

    self.internalSelectedAssets = stillExistingSeletedAssets;
    [self updateActionbar];
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:selectionChanged:)]) {
        [self.mediaPickerDelegate mediaPickerController:self selectionChanged:[self.internalSelectedAssets copy]];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.refreshGroupFirstTime ? 0 : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfAssets = [self.dataSource numberOfAssets];

    if (self.searchBar.text && [self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didUpdateSearchWithAssetCount:)]) {
        [self.mediaPickerDelegate mediaPickerController:self didUpdateSearchWithAssetCount:numberOfAssets];
    }

    [self toggleEmptyViewFor:numberOfAssets];

    return numberOfAssets;
}

- (void)toggleEmptyViewFor:(NSInteger)numberOfAssets
{
    if (numberOfAssets > 0) {
        [self.emptyViewContainer setHidden: YES];
    } else {
        [self.emptyViewContainer setHidden: NO];
        [self populateEmptyViewContainer];
    }
}

- (id<WPMediaAsset>)assetForPosition:(NSIndexPath *)indexPath
{
    NSInteger itemPosition = indexPath.item;
    NSInteger count = [self.dataSource numberOfAssets];
    if (itemPosition >= count || itemPosition < 0) {
        return nil;
    }
    id<WPMediaAsset> asset = [self.dataSource mediaAtIndex:itemPosition];
    return asset;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    WPMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WPMediaCollectionViewCell class]) forIndexPath:indexPath];

    [self configureCell:cell forIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(WPMediaCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];

    cell.asset = asset;
    NSUInteger position = [self positionOfAssetInSelection:asset];
    cell.hiddenSelectionIndicator = !self.options.allowMultipleSelection;

    [self configureBadgeViewForCell:cell withAsset:asset];

    if (position != NSNotFound) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        if (self.options.allowMultipleSelection) {
            [cell setPosition:position + 1];
        } else {
            [cell setPosition:NSNotFound];
        }
        cell.selected = YES;
    } else {
        [cell setPosition:NSNotFound];
        cell.selected = NO;
    }
}

- (void)configureBadgeViewForCell:(WPMediaCollectionViewCell *)cell withAsset:(id<WPMediaAsset>)asset
{
    if (![asset respondsToSelector:@selector(UTTypeIdentifier)]) {
        cell.badgeView.hidden = YES;
        return;
    }

    NSString *uttype = [asset UTTypeIdentifier];

    if ([self.options.badgedUTTypes containsObject:uttype]) {
        NSString *tagName = (__bridge_transfer NSString *)(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)uttype, kUTTagClassFilenameExtension));
        cell.badgeView.label.text = [tagName uppercaseString];
        cell.badgeView.hidden = NO;
        return;
    } else {
        cell.badgeView.hidden = YES;
    }
}

- (void)configureOverlayViewForCell:(WPMediaCollectionViewCell *)cell
{
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:shouldShowOverlayViewForCellForAsset:)]) {
        if ([self.mediaPickerDelegate mediaPickerController:self shouldShowOverlayViewForCellForAsset:cell.asset]) {
            if (!cell.overlayView || ![cell.overlayView isKindOfClass:self.overlayViewClass]) {
                NSAssert(self.overlayViewClass != nil, @"Media Picker: Attempted to instantiate a reusable overlay view, but no reuse class has been set.");

                cell.overlayView = [self.overlayViewClass new];
            }

            cell.overlayView.hidden = NO;
        }
    }

    if (cell.overlayView && [self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:willShowOverlayView:forCellForAsset:)]) {
        [self.mediaPickerDelegate mediaPickerController:self
                                    willShowOverlayView:cell.overlayView
                                        forCellForAsset:cell.asset];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    if ([self shouldShowCustomHeaderView]) {
        if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerReferenceSizeForCustomHeaderView:)]) {
            return [self.mediaPickerDelegate mediaPickerControllerReferenceSizeForCustomHeaderView:self];
        }
    }

    if ( [self isShowingCaptureCell] && self.options.showMostRecentFirst)
    {
        return self.cameraPreviewSize;
    }
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section
{
    if ( [self isShowingCaptureCell] && !self.options.showMostRecentFirst)
    {
        return self.cameraPreviewSize;
    }
    return CGSizeZero;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    // Custom header view support
    if (kind == UICollectionElementKindSectionHeader && [self shouldShowCustomHeaderView]) {
        if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:configureCustomHeaderView:)]) {
            UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:CustomHeaderReuseIdentifier forIndexPath:indexPath];
            [self.mediaPickerDelegate mediaPickerController:self configureCustomHeaderView:view];
            return view;
        }
    }

    if ((kind == UICollectionElementKindSectionHeader && self.options.showMostRecentFirst) ||
       (kind == UICollectionElementKindSectionFooter && !self.options.showMostRecentFirst))
    {
        if (!self.captureCell) {
            self.captureCell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([WPMediaCapturePreviewCollectionView class]) forIndexPath:indexPath];
            if (self.captureCell.gestureRecognizers == nil) {
                UIGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captureMedia)];
                [self.captureCell addGestureRecognizer:tapGestureRecognizer];
            }
            self.captureCell.preferFrontCamera = self.options.preferFrontCamera;
            [self.captureCell startCapture];
        }
        CGRect newFrame = self.captureCell.frame;
        CGSize fixedSize = self.cameraPreviewSize;
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        if (layout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            fixedSize.height = self.view.frame.size.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom - self.collectionView.contentInset.bottom;
        } else {
            fixedSize.width = self.view.frame.size.width;
        }
        newFrame.size = fixedSize;
        self.captureCell.frame = newFrame;
        return self.captureCell;
    }

    return [UICollectionReusableView new];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[WPMediaCollectionViewCell class]]) {
        [self configureOverlayViewForCell:(WPMediaCollectionViewCell *)cell];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[WPMediaCollectionViewCell class]]) {
        WPMediaCollectionViewCell *mediaCell = (WPMediaCollectionViewCell *)cell;
        mediaCell.overlayView.hidden = YES;
    }
}

- (BOOL)shouldShowCustomHeaderView
{
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerShouldShowCustomHeaderView:)]) {
        return [self.mediaPickerDelegate mediaPickerControllerShouldShowCustomHeaderView:self];
    }

    return NO;
}

/**
 Returns the position of the asset in the current selection if any

 @param asset to find in selection
 @return the position if the asset is selected or NSNotFound
 */
- (NSUInteger)positionOfAssetInSelection:(id<WPMediaAsset>)asset
{
    NSUInteger position = [self.internalSelectedAssets indexOfObjectPassingTest:^BOOL(id<WPMediaAsset> loopAsset, NSUInteger idx, BOOL *stop) {
        BOOL found =  [[asset identifier]  isEqual:[loopAsset identifier]];
        return found;
    }];
    return position;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        return [self.mediaPickerDelegate mediaPickerController:self shouldSelectAsset:asset];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if (asset == nil) {
        return;
    }
    if (!self.options.allowMultipleSelection) {
        [self.internalSelectedAssets removeAllObjects];
    }
    [self.internalSelectedAssets addObject:asset];

    WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (self.options.allowMultipleSelection) {
        [cell setPosition:self.internalSelectedAssets.count];
    } else {
        [cell setPosition:NSNotFound];
    }
    [self animateCellSelection:cell completion:nil];
    [self updateActionbar];
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]) {
        [self.mediaPickerDelegate mediaPickerController:self didSelectAsset:asset];
    }
    if (!self.options.allowMultipleSelection) {
        if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
            [self.mediaPickerDelegate mediaPickerController:self didFinishPickingAssets:[self.internalSelectedAssets copy]];
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:shouldDeselectAsset:)]) {
        return [self.mediaPickerDelegate mediaPickerController:self shouldDeselectAsset:asset];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{

    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if (asset == nil){
        return;
    }
    NSUInteger deselectPosition = [self positionOfAssetInSelection:asset];
    if (deselectPosition != NSNotFound) {
        [self.internalSelectedAssets removeObjectAtIndex:deselectPosition];
    }

    WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self animateCellSelection:cell completion:^{
        for (NSIndexPath *selectedIndexPath in self.collectionView.indexPathsForSelectedItems){
            WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:selectedIndexPath];
            id<WPMediaAsset> asset = [self assetForPosition:selectedIndexPath];
            NSUInteger position = [self positionOfAssetInSelection:asset];
            if (position != NSNotFound) {
                if (self.options.allowMultipleSelection) {
                    [cell setPosition:position + 1];
                } else {
                    [cell setPosition:NSNotFound];
                }
            }
        }
    }];

    [self updateActionbar];

    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didDeselectAsset:)]) {
        [self.mediaPickerDelegate mediaPickerController:self didDeselectAsset:asset];
    }
}

- (void)animateCellSelection:(UIView *)cell completion:(void (^)(void))completionBlock
{
    [UIView animateKeyframesWithDuration:SelectAnimationTime delay:0 options:UIViewKeyframeAnimationOptionCalculationModePaced animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:SelectAnimationTime/2 animations:^{
            cell.frame = CGRectInset(cell.frame, 1, 1);
        }];
        [UIView addKeyframeWithRelativeStartTime:SelectAnimationTime/2 relativeDuration:SelectAnimationTime/2 animations:^{
            cell.frame = CGRectInset(cell.frame, -1, -1);
        }];
    } completion:^(BOOL finished) {
        if(completionBlock){
            completionBlock();
        }
    }];
}

#pragma mark - Media Capture

- (WPMediaCapturePresenter *)capturePresenter
{
    if (!_capturePresenter) {
        _capturePresenter = [[WPMediaCapturePresenter alloc] initWithPresentingViewController:self.viewControllerToUseToPresent];
        _capturePresenter.mediaType = self.options.filter;
        _capturePresenter.preferFrontCamera = self.options.preferFrontCamera;

        __weak typeof(self) weakSelf = self;
        _capturePresenter.completionBlock = ^(NSDictionary *mediaInfo) {
            if (mediaInfo) {
                [weakSelf processMediaCaptured:mediaInfo];
            }

            weakSelf.capturePresenter = nil;
        };
    }

    return _capturePresenter;
}

- (void)captureMedia
{
    [self.capturePresenter presentCapture];
}

- (void)processMediaCaptured:(NSDictionary *)info
{
    WPMediaAddedBlock completionBlock = ^(id<WPMediaAsset> media, NSError *error) {
        if (error || !media) {
            NSLog(@"Adding media failed: %@", [error localizedDescription]);
            [self showError:error];
            return;
        }
        [self addMedia:media animated:YES];
    };
    if ([info[UIImagePickerControllerMediaType] isEqual:(NSString *)kUTTypeImage]) {
        UIImage *image = (UIImage *)info[UIImagePickerControllerOriginalImage];
        [self.dataSource addImage:image
                         metadata:info[UIImagePickerControllerMediaMetadata]
                  completionBlock:completionBlock];
    } else if ([info[UIImagePickerControllerMediaType] isEqual:(NSString *)kUTTypeMovie]) {
        [self.dataSource addVideoFromURL:info[UIImagePickerControllerMediaURL] completionBlock:completionBlock];
    }
}

- (void)addMedia:(id<WPMediaAsset>)asset animated:(BOOL)animated
{
    BOOL willBeSelected = YES;
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        if ([self.mediaPickerDelegate mediaPickerController:self shouldSelectAsset:asset]) {
            self.capturedAsset = asset;
        } else {
            willBeSelected = NO;
        }
    } else {
        self.capturedAsset = asset;
    }

    if (!willBeSelected) {
        return;
    }
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]) {
        [self.mediaPickerDelegate mediaPickerController:self didSelectAsset:asset];
    }
    if (!self.options.allowMultipleSelection) {
        if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
            if (self.capturedAsset) {
                [self.internalSelectedAssets addObject:self.capturedAsset];
            }
            [self.mediaPickerDelegate mediaPickerController:self didFinishPickingAssets:self.internalSelectedAssets];
        }
    }
}

- (void)setGroup:(id<WPMediaGroup>)group {
    if (group == [self.dataSource selectedGroup]){
        return;
    }
    [self.dataSource setSelectedGroup:group];
    if (self.isViewLoaded) {
        self.refreshGroupFirstTime = YES;
        [self.layout invalidateLayout];
        [self refreshData];
    }
}

#pragma mark - Long Press Handling

- (void)handleLongPressOnAsset:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [gestureRecognizer locationInView:self.collectionView];
        UIViewController *viewController = [self previewControllerForTouchLocation:location];
        [self displayPreviewController:viewController];
    }
}

- (nullable UIViewController *)previewControllerForTouchLocation:(CGPoint)location
{
    self.assetIndexInPreview = [self.collectionView indexPathForItemAtPoint:location];
    if (!self.assetIndexInPreview) {
        return nil;
    }

    id<WPMediaAsset> asset = [self assetForPosition:self.assetIndexInPreview];
    if (!asset) {
        return nil;
    }

    return [self previewViewControllerForAsset:asset];
}

- (UIViewController *)previewViewControllerForAsset:(id <WPMediaAsset>)asset
{
    UIViewController *previewVC;
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:previewViewControllerForAssets:selectedIndex:)]) {

        NSInteger index = [self.internalSelectedAssets indexOfObject:asset];
        NSArray *selectedAssets = self.selectedAssets;
        if (index == NSNotFound) {
            selectedAssets = @[asset];
            index = 0;
        }

        previewVC = [self.mediaPickerDelegate mediaPickerController:self
                                     previewViewControllerForAssets:selectedAssets
                                                      selectedIndex:index];
    }

    if (!previewVC) {
        previewVC = [self defaultPreviewViewControllerForAsset:asset];
    }

    return previewVC;
}

- (nonnull UIViewController *)defaultPreviewViewControllerForAsset:(nonnull id<WPMediaAsset>)asset
{
    if (self.internalSelectedAssets.count <= 1 || [self.internalSelectedAssets indexOfObject:asset] == NSNotFound) {
        return [self singleAssetPreviewViewController:asset];
    } else {
        return [self multipleAssetPreviewViewControllerForSelectedAsset:asset];
    }
}

- (UIViewController *)singleAssetPreviewViewController:(id <WPMediaAsset>)asset
{
    // We can't preview PHAssets that are audio files
    if ([self.dataSource isKindOfClass:[WPPHAssetDataSource class]] && asset.assetType == WPMediaTypeAudio) {
        return nil;
    }

    WPAssetViewController *fullScreenImageVC = [[WPAssetViewController alloc] init];
    fullScreenImageVC.asset = asset;
    fullScreenImageVC.selected = [self positionOfAssetInSelection:asset] != NSNotFound;
    fullScreenImageVC.delegate = self;
    return fullScreenImageVC;
}

- (UIViewController *)multipleAssetPreviewViewControllerForSelectedAsset:(id <WPMediaAsset>)asset
{
    NSArray *selectedAssets = self.selectedAssets;

    // We can't preview PHAssets that are audio files
    if ([self.dataSource isKindOfClass:[WPPHAssetDataSource class]]) {
        if (asset.assetType == WPMediaTypeAudio) {
            return nil;
        }

        selectedAssets = [self selectedAssetsByRemovingAudioAssets];
        if (selectedAssets.count == 0) {
            return nil;
        }
    }

    NSInteger index = [selectedAssets indexOfObject:asset];

    WPCarouselAssetsViewController *carouselVC = [[WPCarouselAssetsViewController alloc] initWithAssets:selectedAssets];
    carouselVC.assetViewDelegate = self;
    [carouselVC setPreviewingAssetAtIndex:index animated:NO];
    return carouselVC;
}

- (NSArray <id <WPMediaAsset>> *)selectedAssetsByRemovingAudioAssets
{
    NSPredicate *removeAudioPredicate = [NSPredicate predicateWithBlock:^BOOL(id <WPMediaAsset> _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return evaluatedObject.assetType != WPMediaTypeAudio;
    }];

    return [self.selectedAssets filteredArrayUsingPredicate:removeAudioPredicate];
}

- (void)displayPreviewController:(UIViewController *)viewController {
    if (viewController) {
        // Attempt to use the viewControllerToUseToPresent's nav controller, otherwise lets create a new nav controller and present it.
        if (self.viewControllerToUseToPresent.navigationController) {
            [self.viewControllerToUseToPresent.navigationController pushViewController:viewController animated:YES];
        } else {
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
            viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                            target:self
                                                                                                            action:@selector(dismissPreviewController)];
            [self.viewControllerToUseToPresent presentViewController:navController animated:YES completion:nil];
        }
    }
}

- (void)dismissPreviewController {
    if (self.viewControllerToUseToPresent.navigationController) {
        [self.viewControllerToUseToPresent.navigationController popViewControllerAnimated:YES];
    } else {
        [self.viewControllerToUseToPresent dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Keyboard Handling

- (BOOL)isPresentedAsPopover
{
    for (UIViewController *controller = self; controller != nil; controller = controller.parentViewController) {
        if (controller.popoverPresentationController) {
            return controller.popoverPresentationController.arrowDirection != UIPopoverArrowDirectionUnknown;
        }
    }

    return NO;
}

- (void)registerForKeyboardNotifications
{
    if (![self.parentViewController isKindOfClass:[WPInputMediaPickerViewController class]]) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)unregisterForKeyboardNotifications
{
    if (![self.parentViewController isKindOfClass:[WPInputMediaPickerViewController class]]) {
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    if([self isPresentedAsPopover]) {
        return;
    }

    CGRect keyboardFrameEnd = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIEdgeInsets contentInset = self.collectionView.contentInset;

    contentInset.bottom = keyboardFrameEnd.size.height - self.view.layoutMargins.bottom; //Remove extra safe area
    if (!self.tabBarController.tabBar.translucent) {
        contentInset.bottom -= self.tabBarController.tabBar.frame.size.height;
    }
    self.collectionView.contentInset = contentInset;
    self.collectionView.scrollIndicatorInsets = contentInset;
    self.currentKeyboardHeight = keyboardFrameEnd.size.height;
    [self.emptyViewBottomConstraint setConstant:-self.currentKeyboardHeight];

    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
        [self.collectionView.collectionViewLayout invalidateLayout];
    }];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    contentInset.bottom = 0.f;
    self.collectionView.contentInset = contentInset;
    self.collectionView.scrollIndicatorInsets = contentInset;
    self.currentKeyboardHeight = 0.f;
    [self.emptyViewBottomConstraint setConstant:-self.currentKeyboardHeight];

    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
        [self.collectionView.collectionViewLayout invalidateLayout];
    }];
}

#pragma mark - WPAssetViewControllerDelegate

- (void)assetViewController:(WPAssetViewController *)assetPreviewVC selectionChanged:(BOOL)selected
{
    [self dismissPreviewController];

    if ( [self.dataSource mediaWithIdentifier:[assetPreviewVC.asset identifier]] == nil ) {

    }
    if (self.assetIndexInPreview == nil) {
        return;
    }
    if (selected) {
        [self.collectionView selectItemAtIndexPath:self.assetIndexInPreview animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        [self collectionView:self.collectionView didSelectItemAtIndexPath:self.assetIndexInPreview];
    } else {
        [self.collectionView deselectItemAtIndexPath:self.assetIndexInPreview animated:YES];
        [self collectionView:self.collectionView didDeselectItemAtIndexPath:self.assetIndexInPreview];
    }
}

- (void)assetViewController:(WPAssetViewController *)assetPreviewVC failedWithError:(NSError *)error
{
    BOOL needToPop = YES;
    if (self.navigationController.topViewController == self) {
        needToPop = NO;
    }
    NSString *errorDetails = error.localizedDescription;
    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    if (underlyingError) {
        errorDetails = underlyingError.localizedDescription;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Media preview failed.", @"Alert title when there is issues loading an asset to preview.")
                                                                             message:errorDetails
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"Action to show on alert when view asset fails.") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (needToPop) {
            [self dismissPreviewController];
        }
    }];
    [alertController addAction:dismissAction];

    if (!needToPop) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:alertController animated:YES completion:nil];
        }];
    } else {
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([self.dataSource respondsToSelector:@selector(searchFor:)]) {
        [self.dataSource searchFor:searchText];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    self.searchBar.text = nil;
    if ([self.dataSource respondsToSelector:@selector(searchCancelled)]) {
        [self.dataSource searchCancelled];
        [self.collectionView reloadData];
    }
}

@end
