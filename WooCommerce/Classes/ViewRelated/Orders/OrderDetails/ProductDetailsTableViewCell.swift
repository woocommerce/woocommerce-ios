import UIKit
import Gridicons
import Yosemite

class ProductDetailsTableViewCell: UITableViewCell {

    @IBOutlet private var productImageView: UIImageView!
    @IBOutlet private var quantityLabel: UILabel!

    @IBOutlet private var verticalStackView: UIStackView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!
    @IBOutlet private var taxLabel: UILabel!
    @IBOutlet private var skuLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        productImageView.image = Gridicon.iconOfType(.product)
        productImageView.tintColor = StyleManager.wooGreyBorder
        titleLabel.applyBodyStyle()
        priceLabel.applyFootnoteStyle()
        taxLabel.applyFootnoteStyle()
        skuLabel.applyFootnoteStyle()
    }
}

extension ProductDetailsTableViewCell {
    func configure(item: OrderItem, with details: OrderDetailsViewModel) {
        titleLabel.text = item.name
        quantityLabel.text = "\(item.quantity)"

        let priceText = item.quantity > 1 ? "\(item.total) (\(details.currencySymbol)\(item.subtotal) × \(item.quantity))" : "\(item.total)"
        priceLabel.text = "\(details.currencySymbol)\(priceText)"

        let taxString = NSLocalizedString("Tax:", comment: "Tax label for total taxes line")
        let taxText = item.totalTax.isEmpty ? nil : "\(taxString) \(details.currencySymbol)\(item.totalTax)"
        taxLabel.text = taxText

        let skuString = NSLocalizedString("SKU:", comment: "SKU label")
        let skuText = item.sku.isEmpty ? nil : "\(skuString) \(item.sku)"
        skuLabel.text = skuText
    }
}
