import Foundation
import UIKit
import WordPressAuthenticator


/// Displays the WooCommerce Prologue UI.
///
final class LoginPrologueViewController: UIViewController {

    /// Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet var backgroundView: UIView!

    /// Container View: Holds up the Button + bottom legend.
    ///
    @IBOutlet var containerView: UIView!

    /// Curved Rectangle: Background shape with curved top edge
    ///
    @IBOutlet weak var curvedRectangle: UIImageView!


    // MARK: - Overridden Properties

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }


    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMainView()
        setupBackgroundView()
        setupContainerView()
        setupCurvedRectangle()
        setupCarousel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}


// MARK: - Initialization Methods
//
private extension LoginPrologueViewController {

    func setupMainView() {
        view.backgroundColor = .basicBackground
    }

    func setupBackgroundView() {
        backgroundView.backgroundColor = .authPrologueBottomBackgroundColor
    }

    func setupContainerView() {
        containerView.backgroundColor = .authPrologueBottomBackgroundColor
    }

    func setupCurvedRectangle() {
        curvedRectangle.image = UIImage.curvedRectangle.withRenderingMode(.alwaysTemplate)
        curvedRectangle.tintColor = .authPrologueBottomBackgroundColor
    }

    /// Adds a carousel (slider) of screens to promote the main features of the app.
    /// This is contained in a child view so that this view's background doesn't scroll.
    ///
    func setupCarousel() {
        let carousel = LoginProloguePageViewController()
        carousel.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(carousel)
        view.addSubview(carousel.view)
        view.pinSubviewToAllEdges(carousel.view)
    }
}
