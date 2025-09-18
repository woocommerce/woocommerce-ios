import UIKit
import Combine

final class ProductImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    var cancellable: Cancellable?
    var cancellableTask: Task<Void, Never>?

    private(set) lazy var coverTagView: UIView = {
        let containerView = UIView(frame: .zero)
        containerView.backgroundColor = UIColor.primary
        containerView.clipsToBounds = true
        containerView.isHidden = true
        containerView.layer.cornerRadius = Constants.tagCornerRadius
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(tagLabel)
        containerView.pinSubviewToAllEdges(tagLabel, insets: Constants.tagEdgeInsets)
        return containerView
    }()

    private lazy var tagLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.applyCaption1Style()
        label.textColor = UIColor(light: .white, dark: .black)
        label.text = Localization.tagLabel
        return label
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureImageView()
        configureCellAppearance()
        configureCoverTagView()
        observeInterfaceStyleChange()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellableTask?.cancel()
        cancellableTask = nil

        cancellable?.cancel()
        cancellable = nil

        imageView.image = nil
    }

    deinit {
        cancellableTask?.cancel()
        cancellable?.cancel()
    }
}

/// Private Methods
///
private extension ProductImageCollectionViewCell {
    func configureBackground() {
        applyGrayBackgroundStyle()
    }

    func configureImageView() {
        imageView.contentMode = Settings.imageContentMode
        imageView.clipsToBounds = Settings.clipToBounds
    }

    func configureCellAppearance() {
        contentView.layer.cornerRadius = Constants.cornerRadius
        contentView.layer.borderWidth = Constants.borderWidth
        contentView.layer.borderColor = Colors.borderColor.cgColor
        contentView.layer.masksToBounds = Settings.maskToBounds
    }

    func configureCoverTagView() {
        contentView.addSubview(coverTagView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: coverTagView.leadingAnchor, constant: -Constants.tagPadding),
            contentView.topAnchor.constraint(equalTo: coverTagView.topAnchor, constant: -Constants.tagPadding),
        ])
    }

    func observeInterfaceStyleChange() {
        /// Border color is not automatically updated on trait collection changes and thus manually updated here.
        applyContentBorderColorOnInterfaceStyleChange {
            return Colors.borderColor
        }
    }
}

/// Constants
///
private extension ProductImageCollectionViewCell {
    enum Constants {
        static let cornerRadius = CGFloat(2.0)
        static let borderWidth = CGFloat(0.5)
        static let tagPadding = CGFloat(8)
        static let tagCornerRadius = CGFloat(4)
        static let tagEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
    }

    enum Colors {
        static let borderColor = UIColor.systemColor(.systemGray4)
    }

    enum Settings {
        static let clipToBounds = true
        static let imageContentMode = ContentMode.center
        static let maskToBounds = true
    }

    enum Localization {
        static let tagLabel = NSLocalizedString(
            "productImageCollectionViewCell.tagLabel.text",
            value: "Cover",
            comment: "Label indicating the cover image of a product"
        )
    }
}
