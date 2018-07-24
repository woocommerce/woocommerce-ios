import UIKit
import Yosemite

class AddaNoteViewController: UIViewController {

    var order: Order!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
    }

    func configureNavigation() {
        title = NSLocalizedString("Order #\(order.number)", comment: "Add a note screen - title. Example: Order #15")

        let dismissButtonTitle = NSLocalizedString("Dismiss", comment: "Add a note screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        leftBarButton.tintColor = .white
        navigationItem.setLeftBarButton(leftBarButton, animated: false)

        let addButtonTitle = NSLocalizedString("Add", comment: "Add a note screen - button title to send the note")
        let rightBarButton = UIBarButtonItem(title: addButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(addButtonTapped))
        rightBarButton.tintColor = .white
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func addButtonTapped() {
        NSLog("Add button tapped!")
    }

}
