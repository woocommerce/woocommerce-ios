import UIKit

class AddItemTableViewCell: UITableViewCell {

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
