#import "WPMediaGroupPickerViewController.h"
#import "WPMediaGroupTableViewCell.h"
#import "UIViewController+MediaAdditions.h"

static CGFloat const WPMediaGroupCellHeight = 86.0f;

@interface WPMediaGroupPickerViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSObject *changesObserver;

@end

@implementation WPMediaGroupPickerViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = NSLocalizedString(@"Albums", @"Description of albums in the photo libraries");
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

    // configure table view
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if ([self respondsToSelector:@selector(popoverPresentationController)]
        && self.popoverPresentationController) {
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    [self.tableView registerClass:[WPMediaGroupTableViewCell class] forCellReuseIdentifier:NSStringFromClass([WPMediaGroupTableViewCell class])];
    self.tableView.rowHeight = WPMediaGroupCellHeight;
    self.tableView.accessibilityIdentifier = @"AlbumTable";

    //Setup navigation
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicker:)];

    [self loadData];
}

- (void)setDataSource:(id<WPMediaCollectionDataSource>)dataSource {
    [self unregisterDataSourceObservers];
    _dataSource = dataSource;
    [self registerDataSourceObservers];
}

- (void)registerDataSourceObservers {
    __weak __typeof__(self) weakSelf = self;
    self.changesObserver = [self.dataSource registerGroupChangeObserverBlock:^() {
        if (weakSelf.isViewLoaded) {
            [weakSelf loadData];
        }
    }];
}

- (void)unregisterDataSourceObservers {
    if (_changesObserver) {
        [_dataSource unregisterGroupChangeObserver:_changesObserver];
        _changesObserver = nil;
    }
}

- (void)loadData
{
    [self.dataSource loadDataWithOptions:WPMediaLoadOptionsGroups success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showError:error];
        });
    }];
}

- (void)showError:(NSError *)error {
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
    if ([self.delegate respondsToSelector:@selector(mediaGroupPickerViewController:handleError:)]) {
        if ([self.delegate mediaGroupPickerViewController:self handleError:error]) {
            return;
        }
    }
    [self wpm_showAlertWithError:error okActionHandler:^(UIAlertAction * _Nonnull action) {
        if ([self.delegate respondsToSelector:@selector(mediaGroupPickerViewControllerDidCancel:)]) {
            [self.delegate mediaGroupPickerViewControllerDidCancel:self];
        }
    }];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource numberOfGroups];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPMediaGroupTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([WPMediaGroupTableViewCell class]) forIndexPath:indexPath];

    id<WPMediaGroup> group = [self.dataSource groupAtIndex:indexPath.row];
    
    cell.imagePosterView.image = nil;
    NSString *groupID = group.identifier;
    cell.groupIdentifier = groupID;
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize requestSize = CGSizeApplyAffineTransform(CGSizeMake(WPMediaGroupCellHeight, WPMediaGroupCellHeight), CGAffineTransformMakeScale(scale, scale));
    [group imageWithSize:requestSize
       completionHandler:^(UIImage *result, NSError *error)
     {
         if (error) {
             return;
         }
         if ([cell.groupIdentifier isEqualToString:groupID]){
             dispatch_async(dispatch_get_main_queue(), ^{
                 cell.imagePosterView.image = result;
             });
         }
     }];
    cell.titleLabel.text = [group name];
    NSInteger numberOfAssets = [group numberOfAssetsOfType:[self.dataSource mediaTypeFilter] completionHandler:^(NSInteger result, NSError *error) {
        if ([cell.groupIdentifier isEqualToString:groupID]){
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.countLabel.text = [NSString stringWithFormat:@"%ld", (long)result];
            });
        }
    }];
    if (numberOfAssets != NSNotFound) {
        cell.countLabel.text = [NSString stringWithFormat:@"%ld", (long)numberOfAssets];
    } else {
        cell.countLabel.text = NSLocalizedString(@"Counting media items...", @"Message to show while media data source is finding the number of items available.");
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
    if (selectedPath) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:selectedPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self notifySelectionOfGroup];
}

#pragma mark - Callback methods

- (void)cancelPicker:(UIBarButtonItem *)sender
{
    if ([self.delegate respondsToSelector:@selector(mediaGroupPickerViewControllerDidCancel:)]) {
        [self.delegate mediaGroupPickerViewControllerDidCancel:self];
    }
}

- (void)notifySelectionOfGroup
{
    if (!self.tableView.indexPathForSelectedRow) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(mediaGroupPickerViewController:didPickGroup:)]) {
        NSInteger selectedRow = self.tableView.indexPathForSelectedRow.row;
        id<WPMediaGroup> group = [self.dataSource groupAtIndex:selectedRow];
        [self.delegate mediaGroupPickerViewController:self didPickGroup:group];
    }
}

@end
