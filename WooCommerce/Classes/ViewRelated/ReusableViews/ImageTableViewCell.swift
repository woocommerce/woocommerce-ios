import UIKit

@MainActor
class ImageTableViewCell: UITableViewCell {
    @IBOutlet private weak var detailImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated { configureCell() }
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }

    private func configureCell() {
        configureDefaultBackgroundConfiguration()
        setNeedsLayout()
    }

    func configure(image: UIImage?) {
        detailImageView.image = image
    }
}
