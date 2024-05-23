import SwiftUI

/// A pure wrapper UIKit hosting controller of `PaymentMethodsView` to provide `PaymentMethodsView`'s `rootViewController` in order
/// for card reader payment methods to work, as a pure SwiftUI flow doesn't have a `UIViewController` to pass around.
/// To use it in SwiftUI, `PaymentMethodsWrapperHosted` is the wrapper's SwiftUI version.
final class PaymentMethodsWrapperHostingController: UIHostingController<PaymentMethodsView> {
    init(dismiss: @escaping () -> Void,
         viewModel: PaymentMethodsViewModel) {
        super.init(rootView: PaymentMethodsView(dismiss: dismiss, viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Needed to present IPP collect amount alerts, which are displayed in UIKit view controllers.
        rootView.rootViewController = self
    }
}

// MARK: - SwiftUI compatibility
struct PaymentMethodsWrapperHosted: UIViewControllerRepresentable {
    let viewModel: PaymentMethodsViewModel
    let dismiss: () -> Void

    func makeUIViewController(context: Context) -> some UIViewController {
        PaymentMethodsWrapperHostingController(dismiss: dismiss, viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
