import UIKit

/// Presents a tracking provider, tracking number and shipment date
///
final class AddTrackingViewController: UIViewController {

    @IBOutlet private weak var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
    }
}


private extension AddTrackingViewController {
    func configureNavigation() {
        configureTitle()
        configureDismissButton()
        configureAddButton()
    }

    func configureTitle() {
        title = NSLocalizedString("Add Tracking",
            comment: "Add tracking screen - title.")
    }

    func configureDismissButton() {
        let dismissButtonTitle = NSLocalizedString("Dismiss",
                                                   comment: "Add a note screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        leftBarButton.tintColor = .white
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }

    func configureAddButton() {
        let addButtonTitle = NSLocalizedString("Add",
                                               comment: "Add tracking screen - button title to add a tracking")
        let rightBarButton = UIBarButtonItem(title: addButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(addButtonTapped))
        rightBarButton.tintColor = .white
        navigationItem.setRightBarButton(rightBarButton, animated: false)
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func addButtonTapped() {
        print("=== add===")
    }
}
