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
    }
}

// MARK: - Public Methods
//
extension ProductTableViewCell {
    func configure(_ statsItem: TopEarnerStatsItem?) {
        nameText = statsItem?.productName
        detailText = String.localizedStringWithFormat( NSLocalizedString("Total Product Order: %ld", comment: "Top performers — label for the total number of products ordered"), statsItem?.quantity ?? 0)
        priceText = statsItem?.formattedTotalString

        if let productURLString = statsItem?.imageUrl {
            productImage.downloadImage(from: URL(string: productURLString), placeholderImage: UIImage.productPlaceholderImage)
        } else {
            productImage.image = .productPlaceholderImage
        }
    }
}
