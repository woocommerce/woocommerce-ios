import UIKit
import Gridicons
import Yosemite


/// Pick List: Renders a row that displays a single Product.
///
final class PickListTableViewCell: UITableViewCell {

    /// ImageView
    ///
    @IBOutlet private var productImageView: UIImageView!

    /// Label: Name
    ///
    @IBOutlet private var nameLabel: UILabel!

    /// Label: Quantity
    ///
    @IBOutlet private var quantityLabel: UILabel!

    /// Label: SKU
    ///
    @IBOutlet private var skuLabel: UILabel!

    /// Product Name
    ///
    var name: String? {
        get {
            return nameLabel?.text
        }
        set {
            nameLabel?.text = newValue
        }
    }

    /// Number of Items
    ///
    var quantity: String? {
        get {
            return quantityLabel?.text
        }
        set {
            quantityLabel?.text = newValue
        }
    }

    /// Item's SKU
    ///
    var sku: String? {
        get {
            return skuLabel?.text
        }
        set {
            skuLabel?.text = newValue
        }
    }

    // MARK: - Overridden Methods

    required init?(coder aDecoder: NSCoder) {
        // initializers don't call property observers,
        // so don't set the default for mode here.
        super.init(coder: aDecoder)
    }

    class func makeFromNib() -> PickListTableViewCell {
        return Bundle.main.loadNibNamed("ProductDetailsTableViewCell", owner: self, options: nil)?.first as! PickListTableViewCell
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        configureBackground()
        setupImageView()
        setupNameLabel()
        setupQuantityLabel()
        setupSkuLabel()
    }
}


/// MARK: - Public Methods
///
extension PickListTableViewCell {
    func configure(item: OrderItemViewModel) {
        productImageView.setImage(with: item.imageURL?.absoluteString, placeholder: UIImage.productPlaceholderImage)
        name = item.name
        quantity = item.quantity
        sku = item.sku
    }
}

/// MARK: - Private Methods
///
private extension PickListTableViewCell {

    func configureBackground() {
        applyDefaultBackgroundStyle()

        //Background when selected
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }

    func setupImageView() {
        productImageView.image = .productImage
        productImageView.tintColor = .listSmallIcon
        productImageView.contentMode = .scaleAspectFill
        productImageView.clipsToBounds = true
    }

    func setupNameLabel() {
        nameLabel.applyBodyStyle()
        nameLabel?.text = ""
    }

    func setupQuantityLabel() {
        quantityLabel.applyBodyStyle()
        quantityLabel?.text = ""
    }

    func setupSkuLabel() {
        skuLabel.applySecondaryFootnoteStyle()
        skuLabel?.text = ""
    }
}
