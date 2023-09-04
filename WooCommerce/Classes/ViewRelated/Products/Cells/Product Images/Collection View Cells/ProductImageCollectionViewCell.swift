import UIKit
import Combine

final class ProductImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet private weak var editButton: UIButton!

    var cancellableTask: Cancellable?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureImageView()
        configureEditButton()
        configureCellAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Border color is not automatically updated on trait collection changes and thus manually updated here.
        contentView.layer.borderColor = Colors.borderColor.cgColor
    }

    override func prepareForReuse() {
        cancellableTask?.cancel()
        cancellableTask = nil
    }

    /// Set the menu that is shown when tapping on the edit button.
    /// - Parameter menu: When the menu is `nil`, the edit button is not shown.
    func setEditButtonMenu(_ menu: UIMenu?) {
        editButton.isHidden = menu == nil
        guard let menu else {
            return
        }
        editButton.showsMenuAsPrimaryAction = true
        editButton.menu = menu
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

    func configureEditButton() {
        editButton.isHidden = true
        editButton.applyIconButtonStyle(icon: .sparklesImage)
        editButton.setTitle("", for: .normal)
    }

    func configureCellAppearance() {
        contentView.layer.cornerRadius = Constants.cornerRadius
        contentView.layer.borderWidth = Constants.borderWidth
        contentView.layer.borderColor = Colors.borderColor.cgColor
        contentView.layer.masksToBounds = Settings.maskToBounds
    }
}

/// Constants
///
private extension ProductImageCollectionViewCell {
    enum Constants {
        static let cornerRadius = CGFloat(2.0)
        static let borderWidth = CGFloat(0.5)
    }

    enum Colors {
        static let borderColor = UIColor.systemColor(.systemGray4)
    }

    enum Settings {
        static let clipToBounds = true
        static let imageContentMode = ContentMode.center
        static let maskToBounds = true
    }
}
