import UIKit

/// Contains a title label, a text field and an image.
///
final class TitleAndTextFieldWithImageTableViewCell: UITableViewCell {

    struct ViewModel {
        let title: String?
        let text: String?
        let placeholder: String?
        let image: UIImage?
        let onTextChange: ((_ text: String?) -> Void)?

        enum State {
            case normal
            case error
        }

        init(title: String?,
             text: String?,
             placeholder: String?,
             image: UIImage?,
             onTextChange: ((_ text: String?) -> Void)?) {
            self.title = title
            self.text = text
            self.placeholder = placeholder
            self.image = image
            self.onTextChange = onTextChange
        }
    }

    @IBOutlet weak private var contentStackView: UIStackView!
    @IBOutlet weak private var label: UILabel!
    @IBOutlet weak private var textField: UITextField!
    @IBOutlet weak private var rightImageView: UIImageView!

    var rightImageViewIsHidden = false {
        didSet {
            rightImageView.isHidden = rightImageViewIsHidden
        }
    }

    private var onTextChange: ((_ text: String?) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureSelectionStyle()
        configureTitleLabel()
        configureTextField()
        configureRightImageView()
        configureContentStackView()
        applyDefaultBackgroundStyle()
        configureTapGestureRecognizer()
    }

    func configure(viewModel: ViewModel) {
        label.text = viewModel.title
        textField.text = viewModel.text
        textField.placeholder = viewModel.placeholder
        rightImageView.image = viewModel.image
        rightImageViewIsHidden = viewModel.image == nil
        onTextChange = viewModel.onTextChange
    }

    func textFieldBecomeFirstResponder() {
        textField.becomeFirstResponder()
    }

}

private extension TitleAndTextFieldWithImageTableViewCell {
    func configureSelectionStyle() {
        selectionStyle = .none
    }

    func configureTitleLabel() {
        label.applyBodyStyle()
        label.textColor = .textBrand
    }

    func configureTextField() {
        textField.textAlignment = .right
        textField.applyBodyStyle()
        textField.textColor = .textBrand
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
    }

    func configureRightImageView() {
        imageView?.contentMode = .scaleAspectFit
    }

    func configureContentStackView() {
        contentStackView.spacing = 16
    }

    func configureTapGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }
}

private extension TitleAndTextFieldWithImageTableViewCell {
    /// When the cell is tapped, the text field become the first responder
    ///
    @objc func cellTapped(sender: UIView) {
        textField.becomeFirstResponder()
    }
}


private extension TitleAndTextFieldWithImageTableViewCell {
    @objc func textFieldDidChange(textField: UITextField) {
        onTextChange?(textField.text)
    }
}
