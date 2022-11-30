import SwiftUI

/// This `UIHostingController` subclass updates the view constraints after layouting its subviews.
/// That fixes a bug on `UIHostingController` that adds extra padding to its hosting view on iOS 15.
/// https://stackoverflow.com/questions/69265914/on-ios-15-the-uihostingcontroller-is-adding-some-weird-extra-padding-to-its-hos
///
final class ConstraintsUpdatingHostingController<Content: View>: UIHostingController<Content> {
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        heightConstraint = view.heightAnchor.constraint(equalToConstant: view.intrinsicContentSize.height)
        NSLayoutConstraint.activate([
            heightConstraint!,
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heightConstraint?.constant = view.intrinsicContentSize.height
    }
}
