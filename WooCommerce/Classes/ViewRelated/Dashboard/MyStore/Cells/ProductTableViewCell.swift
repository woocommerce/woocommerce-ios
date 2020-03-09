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
        productImage.contentMode = .scaleAspectFit
        contentView.backgroundColor = .listForeground
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

        imageService.downloadAndCacheImageForImageView(productImage,
                                                       with: statsItem?.imageUrl,
                                                       placeholder: .productPlaceholderImage,
                                                       progressBlock: nil,
                                                       completion: nil)
    }
}
