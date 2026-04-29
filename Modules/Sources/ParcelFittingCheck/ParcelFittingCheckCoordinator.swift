import UIKit
import SwiftUI

public extension UnitLength {
    static func fromStoreUnit(_ unit: String) -> UnitLength {
        unit.lowercased() == "in" ? .inches : .centimeters
    }
}

public final class ParcelFittingCheckCoordinator {

    public static func presentSizing(
        from presenter: UIViewController,
        unit: UnitLength,
        initial: ParcelDimensions = .unset,
        onConfirm: @escaping (ParcelDimensions) -> Void
    ) {
        let view = ARParcelSizingView(
            unit: unit,
            initial: initial,
            onCancel: { presenter.dismiss(animated: true) },
            onConfirm: { dims in
                presenter.dismiss(animated: true)
                onConfirm(dims)
            }
        )
        present(view, from: presenter)
    }

    public static func presentFitCheck(
        from presenter: UIViewController,
        unit: UnitLength,
        carriers: [ParcelPresetCarrier],
        initialPackageID: String? = nil,
        onConfirm: @escaping (ParcelPresetPackage) -> Void
    ) {
        let view = ARParcelFitCheckView(
            unit: unit,
            availableCarriers: carriers,
            initialPackageID: initialPackageID,
            onCancel: { presenter.dismiss(animated: true) },
            onConfirm: { package in
                presenter.dismiss(animated: true)
                onConfirm(package)
            }
        )
        present(view, from: presenter)
    }

    private static func present<V: View>(_ view: V, from presenter: UIViewController) {
        let hosting = UIHostingController(rootView: view)
        hosting.modalPresentationStyle = .fullScreen
        presenter.present(hosting, animated: true)
    }
}
