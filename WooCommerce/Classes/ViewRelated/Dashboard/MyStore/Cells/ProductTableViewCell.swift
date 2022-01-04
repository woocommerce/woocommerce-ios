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
        backgroundColor = .listForeground
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
    }

    func configure(viewModel: ViewModel, imageService: ImageService) {
        nameText = viewModel.nameText
        detailText = viewModel.detailText
        accessoryText = viewModel.accessoryText

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
    init(statsItem: TopEarnerStatsItem?, isMyStoreTabUpdatesEnabled: Bool) {
        nameText = statsItem?.productName
        imageURL = statsItem?.imageUrl

        if isMyStoreTabUpdatesEnabled {
            detailText = String.localizedStringWithFormat(
                NSLocalizedString("Net sales: %@",
                                  comment: "Top performers — label for the total number of products ordered"),
                statsItem?.formattedTotalString ?? ""
            )
            accessoryText = "\(statsItem?.quantity ?? 0)"
        } else {
            detailText = String.localizedStringWithFormat(
                NSLocalizedString("Total orders: %ld",
                                  comment: "Top performers — label for the total number of products ordered"),
                statsItem?.quantity ?? 0
            )
            accessoryText = statsItem?.formattedTotalString
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
}

private extension TopEarnerStatsItem {
    /// Returns a total string including the currency symbol
    ///
    var totalString: String {
        return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatHumanReadableAmount(String(total), with: currency) ?? String()
    }
}
