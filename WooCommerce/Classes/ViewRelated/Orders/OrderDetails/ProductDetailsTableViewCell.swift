import UIKit
import Gridicons
import Yosemite

class ProductDetailsTableViewCell: UITableViewCell {

    @IBOutlet private var productImageView: UIImageView!
    @IBOutlet private var quantityLabel: UILabel!

    @IBOutlet private var verticalStackView: UIStackView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var detailsLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!
    @IBOutlet private var taxLabel: UILabel!
    @IBOutlet private var skuLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        productImageView.image = Gridicon.iconOfType(.product)
        productImageView.tintColor = StyleManager.wooGreyBorder
        titleLabel.applyBodyStyle()
        detailsLabel.applyFootnoteStyle()
        priceLabel.applyFootnoteStyle()
        taxLabel.applyFootnoteStyle()
        skuLabel.applyFootnoteStyle()
    }
}

extension ProductDetailsTableViewCell {
    func configure(item: OrderItem) {
        titleLabel.text = item.name
        quantityLabel.text = "\(item.quantity)"
        detailsLabel.isHidden = true
        let priceText = item.quantity > 1 ? "\(item.total) \(item.subtotal) x \(item.quantity)" : "\(item.total)"
        priceLabel.text = "$\(priceText)"
        taxLabel.text = "Tax: $\(item.totalTax)"
        skuLabel.text = "SKU: \(item.sku)"
    }
}
