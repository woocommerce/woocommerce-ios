import UIKit

final class LabelAndButtonTableViewCell: UITableViewCell {
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var button: UIButton!

    private var didTapButton: (() -> Void)?

    func configure(labelText: String, buttonTitle: String, didTapButton: @escaping (() -> Void)) {
        label.text = labelText
        button.setTitle(buttonTitle, for: .normal)
        self.didTapButton = didTapButton
        button.on(.touchUpInside, call: onButtonTap)
    }

    @objc private func onButtonTap(_ button: UIButton) {
        self.didTapButton?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureButton()
    }
}

private extension LabelAndButtonTableViewCell {
    func configureButton() {
        button.tintColor = .accent
    }
}
