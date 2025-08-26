import SwiftUI

struct PointOfSaleSettingsHardwareDetailView: View {
    @State private var navigationPath: [NavigationDestination] = []
    @State private var showBarcodeScanningSetupModal: Bool = false
    @State private var showBarcodeScanningDocumentationModal: Bool = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List(PointOfSaleSettingsView.HardwareDestination.allCases) { destination in
                NavigationLink(value: NavigationDestination.hardware(destination)) {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: destination.icon)
                            .font(.posBodyLargeRegular())
                        VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                            Text(destination.title)
                                .font(.posBodyLargeRegular())
                            Text(destination.subtitle)
                                .font(.posBodyMediumRegular())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .hardware(.cardReaders):
                    cardReadersView
                case .hardware(.scanners):
                    scannersView
                case .scanner:
                    // This case in the navigation stack is not reached,
                    // as we present the destination modally instead of further navigation through the stack.
                    EmptyView()
                }
            }
            .posModal(isPresented: $showBarcodeScanningSetupModal) {
                PointOfSaleBarcodeScannerSetup(isPresented: $showBarcodeScanningSetupModal)
            }
            .posSheet(isPresented: $showBarcodeScanningDocumentationModal) {
                SafariView(url: WooConstants.URLs.pointOfSaleDocumentation.asURL())
            }
        }
    }

    private func handleScannerDestination(_ destination: ScannerDestination) {
        switch destination {
        case .setup:
            showBarcodeScanningSetupModal = true
        case .documentation:
            showBarcodeScanningDocumentationModal = true
        }
    }

    private var cardReadersView: some View {
        VStack(spacing: POSSpacing.medium) {
            Image(systemName: "creditcard").font(.largeTitle)
            Text("Card readers settings")
                .font(.posBodyLargeRegular())
            Text("Manage your card reader connections")
                .font(.posBodyMediumRegular())
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(Localization.cardReadersTitle)
    }

    private var scannersView: some View {
        List(ScannerDestination.allCases) { destination in
            Button {
                handleScannerDestination(destination)
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: destination.icon)
                        .font(.posBodyLargeRegular())
                    VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                        Text(destination.title)
                            .font(.posBodyLargeRegular())
                        Text(destination.subtitle)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle(Localization.scannersTitle)
    }

}

extension PointOfSaleSettingsHardwareDetailView {
    enum NavigationDestination: Hashable {
        case hardware(PointOfSaleSettingsView.HardwareDestination)
        case scanner(ScannerDestination)
    }

    enum ScannerDestination: Identifiable, CaseIterable {
        case setup
        case documentation

        var id: Self { self }

        var title: String {
            switch self {
            case .setup:
                return Localization.scannerSetupTitle
            case .documentation:
                return Localization.scannerDocumentationTitle
            }
        }

        var subtitle: String {
            switch self {
            case .setup:
                return Localization.scannerSetupSubtitle
            case .documentation:
                return Localization.scannerDocumentationSubtitle
            }
        }

        var icon: String {
            switch self {
            case .setup:
                return "gearshape"
            case .documentation:
                return "doc.text"
            }
        }
    }
}

private extension PointOfSaleSettingsHardwareDetailView {
    enum Localization {
        static let cardReadersTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cardReadersTitle",
            value: "Card readers",
            comment: "Navigation title for card readers settings in Point of Sale."
        )

        static let scannersTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.scannersTitle",
            value: "Barcode scanners",
            comment: "Navigation title for barcode scanners settings in Point of Sale."
        )

        static let scannerSetupTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.scannerSetupTitle",
            value: "Scanner Setup",
            comment: "Title for scanner setup option in barcode scanners settings in Point of Sale."
        )

        static let scannerSetupSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.scannerSetupSubtitle",
            value: "Configure and test your barcode scanner",
            comment: "Subtitle describing scanner setup in Point of Sale settings."
        )

        static let scannerDocumentationTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.scannerDocumentationTitle",
            value: "Documentation",
            comment: "Title for barcode scanner documentation option in Point of Sale settings."
        )

        static let scannerDocumentationSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.scannerDocumentationSubtitle",
            value: "Learn more about barcode scanning in POS",
            comment: "Subtitle describing barcode scanner documentation in Point of Sale settings."
        )
    }
}
