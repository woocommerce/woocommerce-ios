import UIKit
import Yosemite
import CocoaLumberjack

protocol NewOrdersDelegate {
    func didUpdateNewOrdersData(hasNewOrders: Bool)
}

class NewOrdersViewController: UIViewController {

    // MARK: - Private Properties

    @IBOutlet private weak var topBorder: UIView!
    @IBOutlet private weak var bottomBorder: UIView!
    @IBOutlet private weak var titleLabel: PaddedLabel!
    @IBOutlet private weak var descriptionLabel: PaddedLabel!
    @IBOutlet private weak var chevronImageView: UIImageView!
    @IBOutlet private weak var actionButton: UIButton!

    // MARK: - Public Properties

    public var delegate: NewOrdersDelegate?

    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
}


// MARK: - Public Interface
//
extension NewOrdersViewController {

    func syncNewOrders() {
        // TODO: grab actual data here and remove this fake code! 🤡
        titleLabel.text = String.localizedStringWithFormat(NSLocalizedString("You have %@ orders to fulfill",
                                                                             comment: "Title text used on the UI element displayed when a user has multiple pending orders to process."), "50+")
        if let delegate = delegate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                delegate.didUpdateNewOrdersData(hasNewOrders: true)
            }
        }
    }
}


// MARK: - User Interface Configuration
//
private extension NewOrdersViewController {

    func configureView() {
        view.backgroundColor = StyleManager.wooWhite
        topBorder.backgroundColor = StyleManager.wooGreyBorder
        bottomBorder.backgroundColor = StyleManager.wooGreyBorder
        titleLabel.applyHeadlineStyle()
        titleLabel.textInsets = Constants.newOrdersTitleLabelInsets
        descriptionLabel.applyBodyStyle()
        descriptionLabel.textInsets = Constants.newOrdersDescriptionLabelInsets
        descriptionLabel.text = NSLocalizedString("Review, prepare, and ship these pending orders",
                                                  comment: "Description text used on the UI element displayed when a user has pending orders to process.")
        chevronImageView.image = UIImage.chevronImage
    }
}


// MARK: - Actions!
//
private extension NewOrdersViewController {

    @IBAction func buttonTouchUpInside(_ sender: UIButton) {
        DDLogDebug("Hi there!!!!")
        sender.fadeOutSelectedBackground()
    }

    @IBAction func buttonTouchUpOutside(_ sender: UIButton) {
        sender.fadeOutSelectedBackground()
    }

    @IBAction func buttonTouchDown(_ sender: UIButton) {
        sender.fadeInSelectedBackground()
    }
}


// MARK: - Private UIButton extension
//
private extension UIButton {

    /// Animates the button's bg color to a selected state
    ///
    func fadeInSelectedBackground() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.backgroundColor = StyleManager.wooGreyMid.withAlphaComponent(0.4)
        }
    }

    /// Animates the button's bg color to an unselected state
    ///
    func fadeOutSelectedBackground() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.backgroundColor = .clear
        }
    }
}


// MARK: - Constants!
//
private extension NewOrdersViewController {
    enum Constants {
        static let newOrdersTitleLabelInsets = UIEdgeInsets(top: 14, left: 14, bottom: 0, right: 4)
        static let newOrdersDescriptionLabelInsets = UIEdgeInsets(top: 4, left: 14, bottom: 0, right: 4)
    }
}
