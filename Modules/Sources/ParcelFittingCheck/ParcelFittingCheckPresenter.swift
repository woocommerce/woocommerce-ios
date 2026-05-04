import UIKit
import SwiftUI

public extension UnitLength {
    static func fromStoreUnit(_ unit: String) -> UnitLength {
        unit.lowercased() == "in" ? .inches : .centimeters
    }
}

public final class ParcelFittingCheckPresenter {

    public static func presentSizing(
        from presenter: UIViewController,
        unit: UnitLength,
        initial: ParcelDimensions? = nil,
        onConfirm: @escaping (ParcelDimensions) -> Void
    ) {
        weak var weakHosting: UIHostingController<ARParcelSizingView>?
        let view = ARParcelSizingView(
            unit: unit,
            initial: initial,
            onCancel: { weakHosting?.dismiss(animated: true) },
            onConfirm: { dims in
                weakHosting?.dismiss(animated: true)
                onConfirm(dims)
            }
        )
        let hosting = UIHostingController(rootView: view)
        weakHosting = hosting
        hosting.modalPresentationStyle = .fullScreen
        presenter.present(hosting, animated: true)
    }

    public static func presentFitCheck(
        from presenter: UIViewController,
        unit: UnitLength,
        carriers: [ParcelPresetCarrier],
        initialPackageID: String? = nil,
        onConfirm: @escaping (ParcelPresetPackage) -> Void
    ) {
        weak var weakHosting: UIHostingController<ARParcelFitCheckView>?
        let view = ARParcelFitCheckView(
            unit: unit,
            availableCarriers: carriers,
            initialPackageID: initialPackageID,
            onCancel: { weakHosting?.dismiss(animated: true) },
            onConfirm: { package in
                weakHosting?.dismiss(animated: true)
                onConfirm(package)
            }
        )
        let hosting = UIHostingController(rootView: view)
        weakHosting = hosting
        hosting.modalPresentationStyle = .fullScreen
        presenter.present(hosting, animated: true)
    }
}
