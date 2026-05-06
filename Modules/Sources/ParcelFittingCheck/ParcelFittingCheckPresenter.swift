import UIKit
import SwiftUI

public extension UnitLength {
    static func fromStoreUnit(_ unit: String) -> UnitLength {
        switch unit.lowercased() {
        case "in": return .inches
        case "m": return .meters
        case "mm": return .millimeters
        case "yd": return .yards
        default: return .centimeters
        }
    }
}

public final class ParcelFittingCheckPresenter {

    public static func presentSizing(
        from presenter: UIViewController,
        unit: UnitLength,
        initial: ParcelDimensions? = nil,
        onConfirm: @escaping (ParcelDimensions) -> Void
    ) {
        present(from: presenter) { dismiss in
            ARParcelSizingView(
                unit: unit,
                initial: initial,
                onCancel: dismiss,
                onConfirm: { dims in dismiss(); onConfirm(dims) }
            )
        }
    }

    public static func presentFitCheck(
        from presenter: UIViewController,
        unit: UnitLength,
        carriers: [ParcelPresetCarrier],
        initialPackageID: String? = nil,
        onConfirm: @escaping (ParcelPresetPackage) -> Void
    ) {
        present(from: presenter) { dismiss in
            ARParcelFitCheckView(
                unit: unit,
                availableCarriers: carriers,
                initialPackageID: initialPackageID,
                onCancel: dismiss,
                onConfirm: { package in dismiss(); onConfirm(package) }
            )
        }
    }

    private static func present<V: View>(
        from presenter: UIViewController,
        @ViewBuilder content: @escaping (@escaping () -> Void) -> V
    ) {
        weak var weakHosting: UIHostingController<V>?
        let dismiss: () -> Void = { weakHosting?.dismiss(animated: true) }
        let hosting = UIHostingController(rootView: content(dismiss))
        weakHosting = hosting
        hosting.modalPresentationStyle = .fullScreen
        presenter.present(hosting, animated: true)
    }
}
