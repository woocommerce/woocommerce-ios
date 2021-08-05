import UIKit
import WordPressShared

// MARK: - SearchTableViewCellDelegate
//
public protocol SearchTableViewCellDelegate: AnyObject {
    func startSearch(for: String)
}

// MARK: - SearchTableViewCell
//
open class SearchTableViewCell: UITableViewCell {

    /// UITableView's Reuse Identifier
    ///
    public static let reuseIdentifier = "SearchTableViewCell"

    /// Search 'UITextField's reference!
    ///
    @IBOutlet public var textField: LoginTextField!

    /// UITextField's listener
    ///
    open weak var delegate: SearchTableViewCellDelegate?

    /// Search UITextField's placeholder
    ///
    open var placeholder: String? {
        get {
            return textField.placeholder
        }
        set {
            textField.placeholder = newValue
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
        textField.returnKeyType = .search
        textField.contentInsets = Constants.textInsetsWithIcon
        textField.accessibilityIdentifier = "Search field"
        textField.leftViewImage = textField?.leftViewImage?.imageWithTintColor(WordPressAuthenticator.shared.style.placeholderColor)

        contentView.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
    }
}

// MARK: - Settings
//
private extension SearchTableViewCell {
    enum Constants {
        static let textInsetsWithIcon = WPStyleGuide.edgeInsetForLoginTextFields()
    }
}

// MARK: - UITextFieldDelegate
//
extension SearchTableViewCell: UITextFieldDelegate {
    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        delegate?.startSearch(for: "")
        return true
    }

    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let searchText = textField.text {
            delegate?.startSearch(for: searchText)
        }
        return false
    }
}

// MARK: - Loader
//
public extension SearchTableViewCell {
    func showLoader() {
        guard let leftView = textField.leftView else { return }
        let spinner = UIActivityIndicatorView(frame: leftView.frame)
        addSubview(spinner)
        spinner.startAnimating()

        textField.leftView?.alpha = 0
    }

    func hideLoader() {
        for subview in subviews where subview is UIActivityIndicatorView {
            subview.removeFromSuperview()
            break
        }

        textField.leftView?.alpha = 1
    }
}
