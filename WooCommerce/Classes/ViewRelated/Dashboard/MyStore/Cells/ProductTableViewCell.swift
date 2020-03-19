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

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.applyBodyStyle()
        priceLabel.applyBodyStyle()
        detailLabel.applyFootnoteStyle()
        applyProductImageStyle()
        contentView.backgroundColor = .listForeground
    }

    private func applyProductImageStyle() {
        productImage.backgroundColor = Colors.imageBackgroundColor
        productImage.layer.cornerRadius = Constants.cornerRadius
        productImage.layer.borderWidth = Constants.borderWidth
        productImage.layer.borderColor = Colors.imageBorderColor.cgColor
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
                                                       progressBlock: nil) { [productImage] (image, error) in
                                                        guard image != nil, error == nil else { return }
                                                        productImage?.contentMode = .scaleAspectFill
        }
    }
}

/// Constants
///
private extension ProductTableViewCell {
    enum Constants {
        static let cornerRadius = CGFloat(2.0)
        static let borderWidth = CGFloat(0.5)
    }

    enum Colors {
        static let imageBorderColor = UIColor.border
        static let imageBackgroundColor = UIColor.systemColor(.systemGray6)
    }
}
