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
        if let delegate = delegate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
        chevronImageView.image = UIImage.chevronImage
    }
}


// MARK: - Constants!
//
private extension NewOrdersViewController {
    enum Constants {
        static let newOrdersTitleLabelInsets = UIEdgeInsets(top: 14, left: 14, bottom: 0, right: 4)
        static let newOrdersDescriptionLabelInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 4)
    }
}
