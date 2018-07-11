import UIKit

class BillingDetailsTableViewCell: UITableViewCell {
    private var button = UIButton(type: .custom)
    @objc var didTapButton: (() -> Void)?


    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel?.applyBodyStyle()
        textLabel?.adjustsFontSizeToFitWidth = true

        button.frame = Constants.buttonFrame
        button.tintColor = StyleManager.wooCommerceBrandColor
        button.addTarget(self, action: #selector(getter: didTapButton), for: .touchUpInside)

        let iconView = UIView(frame: Constants.viewFrame)
        iconView.addSubview(button)
        accessoryView = iconView
    }

    func configure(text: String?, image: UIImage) {
        button.setImage(image, for: .normal)
        textLabel?.text = text
    }
}

private extension BillingDetailsTableViewCell {
    struct Constants {
        static let buttonFrame = CGRect(x: 8, y: 0, width: 44, height: 44)
        static let viewFrame = CGRect(x: 0, y: 0, width: 44, height: 44)
    }
}
