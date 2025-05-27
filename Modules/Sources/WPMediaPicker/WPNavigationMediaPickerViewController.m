#import "WPNavigationMediaPickerViewController.h"
#import "WPMediaPickerViewController.h"
#import "WPMediaGroupPickerViewController.h"
#import "WPPHAssetDataSource.h"

@interface WPNavigationMediaPickerViewController () <
UINavigationControllerDelegate,
WPMediaPickerViewControllerDelegate,
WPMediaGroupPickerViewControllerDelegate,
UIPopoverPresentationControllerDelegate
>
@property (nonatomic, strong) UINavigationController *internalNavigationController;
@property (nonatomic, strong) WPMediaPickerViewController *mediaPicker;
@property (nonatomic, strong) WPMediaGroupPickerViewController *groupViewController;
@property (nonatomic, strong) NSObject *changesObserver;
@property (nonatomic, weak) UIViewController *afterSelectionViewController;
@end

@implementation WPNavigationMediaPickerViewController

static NSString *const ArrowDown = @"\u25be";

- (instancetype)initWithOptions:(WPMediaPickerOptions *)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self commonInitWithOptions:options];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInitWithOptions:[WPMediaPickerOptions new]];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInitWithOptions:[WPMediaPickerOptions new]];
    }
    return self;
}

- (void)commonInitWithOptions:(WPMediaPickerOptions *)options {
    _mediaPicker = [[WPMediaPickerViewController alloc] initWithOptions:options];
    _mediaPicker.mediaPickerDelegate = self;
    _groupViewController = [[WPMediaGroupPickerViewController alloc] init];
    _groupViewController.delegate = self;
    _showGroupSelector = YES;
    _startOnGroupSelector = YES;
}

- (void)dealloc {
    [self unregisterDataSourceObservers];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];

    [self setupNavigationController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [self.mediaPicker preferredStatusBarStyle];
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return nil;
}

- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden
{
    return self.internalNavigationController.topViewController;
}

- (void)setupNavigationController
{
    if (!self.dataSource) {
        self.dataSource = [WPPHAssetDataSource sharedInstance];
    }

    UIViewController *rootController = self.groupViewController;
    if (!self.showGroupSelector) {
        rootController = self.mediaPicker;
    }
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController: rootController];
    nav.delegate = self;

    nav.topViewController.navigationItem.leftBarButtonItem = [self cancelButton];

    if (self.showGroupSelector && !self.startOnGroupSelector) {
        [nav pushViewController:self.mediaPicker animated:NO];
    }

    [nav willMoveToParentViewController:self];
    [nav.view setFrame:self.view.bounds];
    [self.view addSubview:nav.view];
    [self addChildViewController:nav];
    [nav didMoveToParentViewController:self];
    self.internalNavigationController = nav;

    if (self.mediaPicker.options.allowMultipleSelection) {
        [self updateSelectionAction];
    }
}

- (void)setDataSource:(id<WPMediaCollectionDataSource>)dataSource {
    [self unregisterDataSourceObservers];
    _dataSource = dataSource;
    _dataSource.mediaTypeFilter = self.mediaPicker.options.filter;
    self.mediaPicker.dataSource = _dataSource;
    self.groupViewController.dataSource = _dataSource;
    [self registerDataSourceObservers];
}

- (void)registerDataSourceObservers {
    __weak __typeof__(self) weakSelf = self;
    self.changesObserver = [self.dataSource registerGroupChangeObserverBlock:^() {
        if (weakSelf.isViewLoaded) {
            weakSelf.mediaPicker.navigationItem.title = weakSelf.dataSource.selectedGroup.name;
        }
    }];
}

- (void)unregisterDataSourceObservers {
    if (_changesObserver) {
        [_dataSource unregisterGroupChangeObserver:_changesObserver];
        _changesObserver = nil;
    }
}

- (UIBarButtonItem *)cancelButton {
    if (self.cancelButtonTitle && self.cancelButtonTitle.length > 0) {
        return [self cancelButtonWithTitle:self.cancelButtonTitle];
    } else {
        return [self defaultCancelButton];
    }
}

- (UIBarButtonItem *)cancelButtonWithTitle:(NSString *)title {
    return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(cancelPicker:)];
}

- (UIBarButtonItem *)defaultCancelButton {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicker:)];
}

- (void)cancelPicker:(UIBarButtonItem *)sender
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
        [self.delegate mediaPickerControllerDidCancel:self.mediaPicker];
    }
}

- (void)finishPicker:(UIBarButtonItem *)sender
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
        [self.delegate mediaPickerController:self.mediaPicker didFinishPickingAssets:self.mediaPicker.selectedAssets];
    }
}

- (void)changeGroup:(UIButton *)sender
{
    WPMediaGroupPickerViewController *groupViewController = [[WPMediaGroupPickerViewController alloc] init];
    groupViewController.delegate = self;
    groupViewController.dataSource = self.dataSource;

    groupViewController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = groupViewController.popoverPresentationController;
    ppc.delegate = self;
    ppc.sourceView = sender;
    ppc.sourceRect = [sender bounds];
    [self presentViewController:groupViewController animated:YES completion:nil];
}

- (void)setSelectionActionTitle:(NSString *)selectionActionTitle
{
    _selectionActionTitle = selectionActionTitle;
    self.mediaPicker.selectionActionTitle = _selectionActionTitle;
}

-(void)setPreviewActionTitle:(NSString *)previewActionTitle
{
    _previewActionTitle = previewActionTitle;
    self.mediaPicker.previewActionTitle = _previewActionTitle;
}

#pragma mark - WPMediaGroupViewControllerDelegate

- (void)mediaGroupPickerViewController:(WPMediaGroupPickerViewController *)picker didPickGroup:(id<WPMediaGroup>)group
{
    [self.mediaPicker setGroup:group];
    self.mediaPicker.title = group.name;
    [self.internalNavigationController pushViewController:self.mediaPicker animated:YES];
}

- (void)mediaGroupPickerViewControllerDidCancel:(WPMediaGroupPickerViewController *)picker
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
        [self.delegate mediaPickerControllerDidCancel:self.mediaPicker];
    }
}

- (BOOL)mediaGroupPickerViewController:(WPMediaGroupPickerViewController *)picker handleError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:handleError:)]) {
        return [self.delegate mediaPickerController:self.mediaPicker handleError:error];
    } else {
        return NO;
    }
}

#pragma mark - WPMediaPickerViewControllerDelegate

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didUpdateSearchWithAssetCount:(NSInteger)assetCount {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:didUpdateSearchWithAssetCount:)]) {
        [self.delegate mediaPickerController:picker didUpdateSearchWithAssetCount:assetCount];
    }
}

- (UIView *)emptyViewForMediaPickerController:(WPMediaPickerViewController *)picker {
    if ([self.delegate respondsToSelector:@selector(emptyViewForMediaPickerController:)]) {
        return [self.delegate emptyViewForMediaPickerController:picker];
    }
    return picker.defaultEmptyView;
}

- (UIViewController *)emptyViewControllerForMediaPickerController:(WPMediaPickerViewController *)picker {
    if ([self.delegate respondsToSelector:@selector(emptyViewControllerForMediaPickerController:)]) {
        return [self.delegate emptyViewControllerForMediaPickerController:picker];
    }
    return picker.defaultEmptyViewController;
}

- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didFinishPickingAssets:(nonnull NSArray<WPMediaAsset> *)assets {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
        [self.delegate mediaPickerController:picker didFinishPickingAssets:assets];
    }
}

- (void)mediaPickerControllerDidCancel:(nonnull WPMediaPickerViewController *)picker {
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
        [self.delegate mediaPickerControllerDidCancel:picker];
    }
}

- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldShowAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:shouldShowAsset:)]) {
        return [self.delegate mediaPickerController:picker shouldShowAsset:asset];
    }
    return YES;
}

- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldEnableAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:shouldEnableAsset:)]) {
        return [self.delegate mediaPickerController:picker shouldEnableAsset:asset];
    }
    return YES;
}

- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldSelectAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        return [self.delegate mediaPickerController:picker shouldSelectAsset:asset];
    }
    return YES;
}

- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didSelectAsset:(nonnull id<WPMediaAsset>)asset {
    [self updateSelectionAction];
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]) {
        [self.delegate mediaPickerController:picker didSelectAsset:asset];
    }
}

- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldDeselectAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:shouldDeselectAsset:)]) {
        return [self.delegate mediaPickerController:picker shouldDeselectAsset:asset];
    }
    return YES;
}

- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didDeselectAsset:(nonnull id<WPMediaAsset>)asset {
    [self updateSelectionAction];
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]) {
        [self.delegate mediaPickerController:picker didDeselectAsset:asset];
    }
}

- (BOOL)mediaPickerController:(WPMediaPickerViewController *)picker shouldShowOverlayViewForCellForAsset:(id<WPMediaAsset>)asset
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:shouldShowOverlayViewForCellForAsset:)]) {
        return [self.delegate mediaPickerController:picker shouldShowOverlayViewForCellForAsset:asset];
    }

    return NO;
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker willShowOverlayView:(UIView *)overlayView forCellForAsset:(id<WPMediaAsset>)asset
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:willShowOverlayView:forCellForAsset:)]) {
        [self.delegate mediaPickerController:picker
                         willShowOverlayView:overlayView
                             forCellForAsset:asset];
    }
}

- (BOOL)mediaPickerControllerShouldShowCustomHeaderView:(WPMediaPickerViewController *)picker
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerShouldShowCustomHeaderView:)]) {
        return [self.delegate mediaPickerControllerShouldShowCustomHeaderView:picker];
    }

    return NO;
}

- (CGSize)mediaPickerControllerReferenceSizeForCustomHeaderView:(WPMediaPickerViewController *)picker
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerReferenceSizeForCustomHeaderView:)]) {
        return [self.delegate mediaPickerControllerReferenceSizeForCustomHeaderView:picker];
    }

    return CGSizeZero;
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker configureCustomHeaderView:(UICollectionReusableView *)headerView
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:configureCustomHeaderView:)]) {
        [self.delegate mediaPickerController:picker configureCustomHeaderView:headerView];
    }
}

- (nullable UIViewController *)mediaPickerController:(WPMediaPickerViewController *)picker previewViewControllerForAssets:(nonnull NSArray<id<WPMediaAsset>> *)assets selectedIndex:(NSInteger)selected {
    UIViewController *previewVC;
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:previewViewControllerForAssets:selectedIndex:)]) {
        previewVC = [self.delegate mediaPickerController:picker previewViewControllerForAssets:assets selectedIndex:selected];
    }

    if (!previewVC) {
        previewVC = [self.mediaPicker defaultPreviewViewControllerForAsset:assets[selected]];
    }

    return previewVC;
}

- (void)mediaPickerControllerWillBeginLoadingData:(nonnull WPMediaPickerViewController *)picker {
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerWillBeginLoadingData:)]) {
        [self.delegate mediaPickerControllerWillBeginLoadingData:picker];
    }
}

- (void)mediaPickerControllerDidEndLoadingData:(nonnull WPMediaPickerViewController *)picker {
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerDidEndLoadingData:)]) {
        [self.delegate mediaPickerControllerDidEndLoadingData:picker];
    }
    self.mediaPicker.title = picker.dataSource.selectedGroup.name;
}

- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker selectionChanged:(nonnull NSArray<WPMediaAsset> *)assets {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:selectionChanged:)]) {
        [self.delegate mediaPickerController:picker selectionChanged:assets];
    }
    [self updateSelectionAction];
}

- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker handleError:(nonnull NSError *)error {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:handleError:)]) {
        return [self.delegate mediaPickerController:picker handleError:error];        
    } else {
        return NO;
    }
}

- (void)updateSelectionAction {
    if (self.internalNavigationController.topViewController == self.afterSelectionViewController) {
        return;
    }
    if (self.mediaPicker.options.showActionBar || self.mediaPicker.selectedAssets.count == 0 || !self.mediaPicker.options.allowMultipleSelection) {
        self.internalNavigationController.topViewController.navigationItem.rightBarButtonItem = nil;
        return;
    }
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.mediaPicker.selectionActionTitle
                                                            style:UIBarButtonItemStyleDone
                                                           target:self
                                                           action:@selector(finishPicker:)];
    rightButtonItem.accessibilityIdentifier = @"SelectedActionButton";
    self.internalNavigationController.topViewController.navigationItem.rightBarButtonItem = rightButtonItem;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController == self.mediaPicker || viewController == self.groupViewController) {
        [self updateSelectionAction];
    }
}

#pragma mark - Public Methods

- (void)showAfterViewController:(UIViewController *)viewController
{
    NSParameterAssert(viewController);
    self.afterSelectionViewController = viewController;
    [self.internalNavigationController pushViewController:viewController animated:YES];
}

@end
