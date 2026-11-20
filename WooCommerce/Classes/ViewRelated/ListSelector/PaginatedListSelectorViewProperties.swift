import UIKit

/// Properties for the list selector view.
///
struct PaginatedListSelectorViewProperties {
    let navigationBarTitle: String?
    let noResultsPlaceholderText: String
    let noResultsPlaceholderImage: UIImage?
    let noResultsPlaceholderImageTintColor: UIColor?
    let tableViewStyle: UITableView.Style
    let separatorStyle: UITableViewCell.SeparatorStyle
    let loadingSectionHeaderVerticalSpace: GhostTableViewSectionHeaderVerticalSpace

    init(navigationBarTitle: String?,
         noResultsPlaceholderText: String,
         noResultsPlaceholderImage: UIImage?,
         noResultsPlaceholderImageTintColor: UIColor?,
         tableViewStyle: UITableView.Style,
         separatorStyle: UITableViewCell.SeparatorStyle = .singleLine,
         loadingSectionHeaderVerticalSpace: GhostTableViewSectionHeaderVerticalSpace = .large) {
        self.navigationBarTitle = navigationBarTitle
        self.noResultsPlaceholderText = noResultsPlaceholderText
        self.noResultsPlaceholderImage = noResultsPlaceholderImage
        self.noResultsPlaceholderImageTintColor = noResultsPlaceholderImageTintColor
        self.tableViewStyle = tableViewStyle
        self.separatorStyle = separatorStyle
        self.loadingSectionHeaderVerticalSpace = loadingSectionHeaderVerticalSpace
    }
}
