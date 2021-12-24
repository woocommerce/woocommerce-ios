import UIKit
import Gridicons
import Yosemite
import WordPressUI


/// Pick List: a simplified ProductDetails cell, that focuses on order fulfillment.
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

    /// The stack view grouping add on information.
    ///
    @IBOutlet private var viewAddOnsStackView: UIStackView!

    /// The label indicating that there are add-ons available.
    ///
    @IBOutlet private var viewAddOnsLabel: UILabel!

    /// The chevron indicator next to the viewAddOns label.
    ///
    @IBOutlet private var viewAddOnsIndicator: UIImageView!

    /// Assign this closure to be notified when the "View Add-ons" button is tapped.
    ///
    var onViewAddOnsTouchUp: (() -> Void)?

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
        // Initializers don't call property observers,
        // so don't set the default for mode here.
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        configureBackground()
        setupImageView()
        setupNameLabel()
        setupQuantityLabel()
        setupSkuLabel()
        setupAddOnViews()
    }

    override func prepareForReuse() {
        setupSkuLabel()
    }
}


/// MARK: - Public Methods
///
extension PickListTableViewCell {
    /// Configure a pick list cell
    ///
    func configure(item: ProductDetailsCellViewModel, imageService: ImageService) {
        imageService.downloadAndCacheImageForImageView(productImageView,
                                                       with: item.imageURL?.absoluteString,
                                                       placeholder: UIImage.productPlaceholderImage.imageWithTintColor(UIColor.listIcon),
                                                       progressBlock: nil,
                                                       completion: nil)
        name = item.name
        quantity = item.quantity
        viewAddOnsStackView.isHidden = !item.hasAddOns

        guard let skuText = item.sku else {
            skuLabel.isHidden = true
            return
        }

        sku = skuText
    }
}

/// MARK: - Private Methods
///
private extension PickListTableViewCell {

    func configureBackground() {
        applyDefaultBackgroundStyle()

        // Background when selected
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
        skuLabel?.isHidden = false
        skuLabel?.text = ""
    }

    func setupAddOnViews() {
        viewAddOnsStackView.layoutMargins = .init(top: 4, left: 0, bottom: 4, right: 0) // Increase touch area
        viewAddOnsStackView.isLayoutMarginsRelativeArrangement = true
        viewAddOnsStackView.spacing = 2

        viewAddOnsLabel.applySubheadlineStyle()
        viewAddOnsLabel.text = Localization.viewAddOns

        viewAddOnsIndicator.image = .chevronImage
        viewAddOnsIndicator.tintColor = .systemGray

        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.on { [weak self] _ in
            self?.onViewAddOnsTouchUp?()
        }
        viewAddOnsStackView.addGestureRecognizer(tapRecognizer)
    }
}

// MARK: Localization
private extension PickListTableViewCell {
    enum Localization {
        static let viewAddOns = NSLocalizedString("View Add-Ons", comment: "Title of the button on the order details product list item to navigate to add-ons")
    }
}
