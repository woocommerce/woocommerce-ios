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

    init(navigationBarTitle: String?,
         noResultsPlaceholderText: String,
         noResultsPlaceholderImage: UIImage?,
         noResultsPlaceholderImageTintColor: UIColor?,
         tableViewStyle: UITableView.Style,
         separatorStyle: UITableViewCell.SeparatorStyle = .singleLine) {
        self.navigationBarTitle = navigationBarTitle
        self.noResultsPlaceholderText = noResultsPlaceholderText
        self.noResultsPlaceholderImage = noResultsPlaceholderImage
        self.noResultsPlaceholderImageTintColor = noResultsPlaceholderImageTintColor
        self.tableViewStyle = tableViewStyle
        self.separatorStyle = separatorStyle
    }
}
