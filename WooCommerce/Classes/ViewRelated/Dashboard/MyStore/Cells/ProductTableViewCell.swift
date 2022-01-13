import UIKit
import Yosemite
import WordPressUI
import Gridicons

final class ProductTableViewCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet private weak var productImage: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!
    @IBOutlet private var accessoryLabel: UILabel!

    /// We use a custom view instead of the default separator as it's width varies depending on the image size, which varies depending on the screen size.
    @IBOutlet private var bottomBorderView: UIView!

    /// Shows the name of the product.
    var nameText: String? {
        get {
            return nameLabel.text
        }
        set {
            nameLabel.text = newValue
        }
    }

    /// Text displayed under the product name.
    var detailText: String? {
        get {
            return detailLabel.text
        }
        set {
            detailLabel.text = newValue
        }
    }

    /// Text displayed at the trailing edge of the cell.
    var accessoryText: String? {
        get {
            return accessoryLabel.text
        }
        set {
            accessoryLabel.text = newValue
        }
    }

    /// Whether to hide the bottom border.
    var hidesBottomBorder: Bool = false {
        didSet {
            bottomBorderView.isHidden = hidesBottomBorder
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.applyBodyStyle()
        accessoryLabel.applyBodyStyle()
        detailLabel.applyFootnoteStyle()
        applyProductImageStyle()
        backgroundColor = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.myStoreTabUpdates) ?
        Constants.backgroundColor: Constants.legacyBackgroundColor
        bottomBorderView.backgroundColor = .systemColor(.separator)
        selectionStyle = .default
    }

    private func applyProductImageStyle() {
        productImage.backgroundColor = ProductImage.backgroundColor
        productImage.layer.cornerRadius = ProductImage.cornerRadius
        productImage.layer.borderWidth = ProductImage.borderWidth
        productImage.layer.borderColor = ProductImage.borderColor.cgColor
        productImage.clipsToBounds = true
    }
}

// MARK: - Public Methods
//
extension ProductTableViewCell {
    struct ViewModel {
        let nameText: String?
        let detailText: String?
        let accessoryText: String?
        let imageURL: String?
        let backgroundColor: UIColor
    }

    func configure(viewModel: ViewModel, imageService: ImageService) {
        nameText = viewModel.nameText
        detailText = viewModel.detailText
        accessoryText = viewModel.accessoryText
        backgroundColor = viewModel.backgroundColor

        /// Set `center` contentMode to not distort the placeholder aspect ratio.
        /// After a successful image download set the contentMode to `scaleAspectFill`
        productImage.contentMode = .center
        imageService.downloadAndCacheImageForImageView(productImage,
                                                       with: viewModel.imageURL,
                                                       placeholder: UIImage.productPlaceholderImage.imageWithTintColor(UIColor.listIcon),
                                                       progressBlock: nil) { [weak productImage] (image, _) in
                                                        guard image != nil else {
                                                            return
                                                        }
                                                        productImage?.contentMode = .scaleAspectFill
        }
    }
}

extension ProductTableViewCell.ViewModel {
    init(statsItem: TopEarnerStatsItem?,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         isMyStoreTabUpdatesEnabled: Bool) {
        nameText = statsItem?.productName
        imageURL = statsItem?.imageUrl

        if isMyStoreTabUpdatesEnabled {
            detailText = String.localizedStringWithFormat(
                NSLocalizedString("Net sales: %@",
                                  comment: "Top performers — label for the total sales of a product"),
                statsItem?.totalString(currencyFormatter: currencyFormatter) ?? ""
            )
            accessoryText = "\(statsItem?.quantity ?? 0)"
            backgroundColor = ProductTableViewCell.Constants.backgroundColor
        } else {
            detailText = String.localizedStringWithFormat(
                NSLocalizedString("Total orders: %ld",
                                  comment: "Top performers — label for the total number of products ordered"),
                statsItem?.quantity ?? 0
            )
            accessoryText = statsItem?.formattedTotalString
            backgroundColor = ProductTableViewCell.Constants.legacyBackgroundColor
        }
    }
}

/// Style Constants
///
private extension ProductTableViewCell {
    enum ProductImage {
        static let cornerRadius = CGFloat(2.0)
        static let borderWidth = CGFloat(0.5)
        static let borderColor = UIColor.border
        static let backgroundColor = UIColor.listForeground
    }

    enum Constants {
        static let backgroundColor: UIColor = .systemBackground
        static let legacyBackgroundColor: UIColor = .listForeground
    }
}

private extension TopEarnerStatsItem {
    /// Returns a total string without rounding up including the currency symbol.
    func totalString(currencyFormatter: CurrencyFormatter) -> String? {
        return currencyFormatter.formatAmount(Decimal(total), with: currency)
    }
}
