import UIKit
import Yosemite

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
    }
}

// MARK: - Public Methods
//
extension ProductTableViewCell {
    func configure(_ statsItem: TopEarnerStatsItem?) {
        nameText = statsItem?.productName
        detailText = String(statsItem?.quantity ?? 0)
        priceText = statsItem?.total.friendlyString()
    }
}
