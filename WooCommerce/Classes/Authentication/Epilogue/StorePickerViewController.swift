import Foundation
import UIKit


///
///
class StorePickerViewController: UIViewController {

    /// White-Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet var backgroundView: UIView!

    /// Default Action Button.
    ///
    @IBOutlet var continueButton: UIButton!


    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMainView()
        setupBackgroundView()
        setupContinueButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}


// MARK: - Initialization Methods
//
private extension StorePickerViewController {

    func setupMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func setupBackgroundView() {
        backgroundView.layer.masksToBounds = false
        backgroundView.layer.shadowOpacity = 0.2
    }

    func setupContinueButton() {
        continueButton.backgroundColor = .clear
    }
}


// MARK: - Action Handlers
//
extension StorePickerViewController {

    /// Proceeds with the Login Flow.
    ///
    @IBAction func continueWasPressed() {
        dismiss(animated: true, completion: nil)
    }
}
