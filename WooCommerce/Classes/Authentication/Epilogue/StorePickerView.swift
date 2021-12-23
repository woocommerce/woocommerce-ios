import SwiftUI

/// SwiftUI conformance for `StorePickerViewController`, that wraps the logic of `StorePickerCoordinator`
///
struct StorePickerView: UIViewControllerRepresentable {

    /// Configuration of the store picker
    ///
    let config: StorePickerConfiguration

    /// Closure to be executed upon dismissal of the store picker
    ///
    var onDismiss: (() -> Void)?

    /// The RoleEligibilityUseCase object initialized with the ServiceLocator stores
    ///
    private let roleEligibilityUseCase = RoleEligibilityUseCase(stores: ServiceLocator.stores)

    typealias UIViewControllerType = StorePickerContainer

    class Coordinator {
        var parentObserver: NSKeyValueObservation?
    }

    /// This is a UIKit solution for fixing Navigation Title and Bar Button Items ignored in NavigationView.
    /// This solution doesn't require making internal changes to the destination `UIViewController`
    /// and should be called once, when wrapped.
    /// Solution proposed here: https://stackoverflow.com/a/68567095/7241994
    ///
    func makeUIViewController(context: Self.Context) -> StorePickerContainer {
        let storePicker = StorePickerContainer(config: config, onDismiss: onDismiss)

        context.coordinator.parentObserver = storePicker.observe(\.parent, changeHandler: { vc, _ in
            vc.parent?.navigationItem.title = vc.title
            vc.parent?.navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
        })

        return storePicker
    }

    func updateUIViewController(_ uiViewController: StorePickerContainer, context: Context) {
        // nothing to do here
    }

    func makeCoordinator() -> Self.Coordinator { Coordinator() }
}

final class StorePickerContainer: UIViewController {

    /// Configuration of the store picker
    ///
    let config: StorePickerConfiguration

    /// Closure to be executed upon dismissal of the store picker
    ///
    var onDismiss: (() -> Void)?

    init(config: StorePickerConfiguration, onDismiss: (() -> Void)?) {
        self.config = config
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let storePickerCoordinator = StorePickerCoordinator(self.navigationController!, config: config)
        storePickerCoordinator.start()
        storePickerCoordinator.onDismiss = onDismiss

        // Embed the store picker VC
        self.addChild(storePickerCoordinator.storePicker)
        self.view.addSubview(storePickerCoordinator.storePicker.view)
        storePickerCoordinator.storePicker.didMove(toParent: self)
    }
}
