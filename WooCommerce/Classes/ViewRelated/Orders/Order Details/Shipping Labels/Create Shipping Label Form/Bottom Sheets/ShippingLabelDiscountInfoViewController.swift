import UIKit
import WordPressUI

/// This view controller is embedded in a bottom sheet, and display the information about the Shipping Label Discount
///
final class ShippingLabelDiscountInfoViewController: UIViewController {

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var separator: UIImageView!
    @IBOutlet private weak var descriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureImages()
        configureLabels()
    }

    /// Init
    ///
    init() {
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize = CGSize(width: .zero, height: stackView.frame.height + (BottomSheetViewController.Constants.additionalContentTopMargin * 2))
    }
}

private extension ShippingLabelDiscountInfoViewController {
    func configureImages() {
        icon.image = .infoOutlineImage
        separator.backgroundColor = .systemColor(.separator)
    }

    func configureLabels() {
        titleLabel.applyHeadlineStyle()
        titleLabel.numberOfLines = 0
        titleLabel.text = Localization.title
        descriptionLabel.applyBodyStyle()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = Localization.description
    }

    enum Localization {
        static let title = NSLocalizedString(
            "What is WooCommerce Services discount?",
            comment: "Shipping Labels: info title about WooCommerce Services discount")
        static let description = NSLocalizedString(
            "When purchasing shipping labels with WooCommerce, you get access to discounted commercial prices.",
            comment: "Shipping Labels: info description about WooCommerce Services discount")
    }
}

extension ShippingLabelDiscountInfoViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }

    var expandedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}
