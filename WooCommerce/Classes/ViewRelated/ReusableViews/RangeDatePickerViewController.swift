import UIKit

/// View Controller containing two cells for displaying a Start and End Date.
/// Useful for selecting a range of date.
///
final class RangeDatePickerViewController: UIViewController {

    init() {
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}
