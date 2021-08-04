import UIKit

class ImageTableViewCell: UITableViewCell {
    @IBOutlet private weak var detailImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    private func configureCell() {
        applyDefaultBackgroundStyle()
        setNeedsLayout()
    }

    func configure(image: UIImage?) {
        detailImageView.image = image
    }
}
