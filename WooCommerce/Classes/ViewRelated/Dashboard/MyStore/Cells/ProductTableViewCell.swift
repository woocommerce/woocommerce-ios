import UIKit
import Yosemite
import WordPressUI
import Gridicons

class ProductTableViewCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet private weak var productImage: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!

    /// We use a custom view isntead of the default separator as it's width varies depending on the image size, which varies depending on the screen size.
    @IBOutlet private var bottomBorderView: UIView!

    var nameText: String? {
        get {
            return nameLabel.text
        }
        set {
            nameLabel.text = newValue
        }
    }

    var detailText: String? {
        get {
            return detailLabel.text
        }
        set {
            detailLabel.text = newValue
        }
    }

    var priceText: String? {
        get {
            return priceLabel.text
        }
        set {
            priceLabel.text = newValue
        }
    }

    var hideBottomBorder: Bool = false {
        didSet {
            bottomBorderView.isHidden = hideBottomBorder
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.applyBodyStyle()
        priceLabel.applyBodyStyle()
        detailLabel.applyFootnoteStyle()
        applyProductImageStyle()
        contentView.backgroundColor = .listForeground
        bottomBorderView.backgroundColor = .systemColor(.separator)
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
    func configure(_ statsItem: TopEarnerStatsItem?, imageService: ImageService) {
        nameText = statsItem?.productName
        detailText = String.localizedStringWithFormat(
            NSLocalizedString("Total orders: %ld",
                              comment: "Top performers — label for the total number of products ordered"),
            statsItem?.quantity ?? 0
        )
        priceText = statsItem?.formattedTotalString

        /// Set `center` contentMode to not distort the placeholder aspect ratio.
        /// After a sucessfull image download set the contentMode to `scaleAspectFill`
        productImage.contentMode = .center
        imageService.downloadAndCacheImageForImageView(productImage,
                                                       with: statsItem?.imageUrl,
                                                       placeholder: .productPlaceholderImage,
                                                       progressBlock: nil) { [weak productImage] (image, _) in
                                                        guard image != nil else {
                                                            return
                                                        }
                                                        productImage?.contentMode = .scaleAspectFill
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
