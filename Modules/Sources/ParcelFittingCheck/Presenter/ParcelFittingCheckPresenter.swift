import UIKit
import SwiftUI
import EventHorizonSDK

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
        tintColor: UIColor? = nil,
        initial: ParcelDimensions? = nil,
        analytics: ParcelFittingAnalyticsTracking,
        onConfirm: @escaping (ParcelDimensions) -> Void
    ) {
        present(from: presenter, tintColor: tintColor) { dismiss in
            ARParcelSizingView(
                unit: unit,
                initial: initial,
                analytics: analytics,
                onCancel: dismiss,
                onConfirm: { dims in dismiss(); onConfirm(dims) }
            )
        }
    }

    public static func presentUnifiedFlow(
        from presenter: UIViewController,
        unit: UnitLength,
        carriers: [ParcelPresetCarrier],
        starredPackageIDs: Set<String> = [],
        tintColor: UIColor? = nil,
        analytics: ParcelFittingAnalyticsTracking,
        delegate: ParcelFittingDelegate
    ) {
        analytics.track(Event.arfittingFlowStarted)
        present(from: presenter, tintColor: tintColor) { dismiss in
            ARUnifiedParcelFlowView(
                unit: unit,
                carriers: carriers,
                starredPackageIDs: starredPackageIDs,
                analytics: analytics,
                delegate: delegate,
                dismiss: dismiss
            )
        }
    }

    private static func present<V: View>(
        from presenter: UIViewController,
        tintColor: UIColor? = nil,
        @ViewBuilder content: @escaping (@escaping () -> Void) -> V
    ) {
        weak var weakHosting: UIHostingController<AnyView>?
        let dismiss: () -> Void = { weakHosting?.dismiss(animated: true) }
        let rootView = AnyView(
            content(dismiss).tint(tintColor.map { Color($0) })
        )
        let hosting = UIHostingController(rootView: rootView)
        weakHosting = hosting
        hosting.modalPresentationStyle = .fullScreen
        presenter.present(hosting, animated: true)
    }
}
