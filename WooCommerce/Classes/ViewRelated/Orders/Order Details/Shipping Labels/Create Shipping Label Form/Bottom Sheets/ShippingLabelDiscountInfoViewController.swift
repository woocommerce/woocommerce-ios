import UIKit
import WordPressUI

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
}

private extension ShippingLabelDiscountInfoViewController {
    func configureImages() {
        icon.image = .infoImage
        separator.backgroundColor = .systemColor(.separator)
    }

    func configureLabels() {
        titleLabel.applyHeadlineStyle()
        titleLabel.numberOfLines = 0
        descriptionLabel.applyBodyStyle()
        descriptionLabel.numberOfLines = 0
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
