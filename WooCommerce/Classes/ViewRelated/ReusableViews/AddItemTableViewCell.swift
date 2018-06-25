import UIKit

class AddItemTableViewCell: UITableViewCell {

    static let reuseIdentifier = "AddItemTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.tintColor = StyleManager.wooCommerceBrandColor
    }
}

extension AddItemTableViewCell {
    func configure(image: UIImage, text: String) {
        imageView?.image = image
        textLabel?.text = text
    }
}
