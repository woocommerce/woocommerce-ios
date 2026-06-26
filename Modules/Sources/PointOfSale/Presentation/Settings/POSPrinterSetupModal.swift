import SwiftUI
import struct Yosemite.PrinterDevice

/// Drives the receipt-printer setup flow from a `POSPrinterConnectionController`, presenting
/// pairing, discovery, connection, and error states. Dismisses itself once a printer connects.
struct POSPrinterSetupModal: View {
    @Binding var isPresented: Bool
    let controller: POSPrinterConnectionController
    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        Group {
            if isCompactWidth {
                // In compact width the modal fills the screen to avoid the cramped iPad-tuned card.
                modalCore
                    .frame(width: parentSize.width, height: parentSize.height)
            } else {
                modalCore
                    .frame(maxWidth: parentSize.width * Constants.parentWidthRatio,
                           maxHeight: parentSize.height * Constants.maxParentHeightRatio)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onChange(of: controller.isConnected) { _, isConnected in
            if isConnected {
                isPresented = false
            }
        }
        .onDisappear {
            Task {
                await controller.cancelSetup()
            }
        }
    }

    private var modalCore: some View {
        VStack(spacing: POSSpacing.xLarge) {
            ScrollView(showsIndicators: false) {
                HStack {
                    Spacer()
                    content
                    Spacer()
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: [.vertical])

            if let buttonConfiguration {
                PointOfSaleFlowButtonsView(configuration: buttonConfiguration)
            }
        }
        .posModalCloseButton(action: {
            isPresented = false
        })
        .padding(POSPadding.xLarge)
        .background(Color.posSurfaceBright)
    }
}

// MARK: - Content per discovery state
private extension POSPrinterSetupModal {
    @ViewBuilder
    var content: some View {
        switch controller.discoveryState {
        case .idle:
            messageContent(icon: "printer",
                           title: Localization.pairTitle,
                           message: Localization.pairInstruction)
        case .searching:
            progressContent(message: Localization.searching)
        case .found(let devices) where devices.isEmpty:
            messageContent(icon: "printer",
                           title: Localization.noPrintersTitle,
                           message: Localization.noPrintersMessage)
        case .found(let devices):
            deviceList(devices)
        case .connecting(let device):
            progressContent(message: String(format: Localization.connectingFormat, device.name))
        case .error:
            messageContent(icon: "exclamationmark.triangle",
                           title: Localization.errorTitle,
                           message: Localization.errorMessage)
        }
    }

    func messageContent(icon: String, title: String, message: String) -> some View {
        VStack(spacing: POSSpacing.xLarge) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundStyle(Color.posOnSurface)

            VStack(alignment: .center, spacing: POSSpacing.small) {
                Text(title)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurface)
                    .multilineTextAlignment(.center)
            }
        }
    }

    func progressContent(message: String) -> some View {
        VStack(spacing: POSSpacing.xLarge) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle(size: Constants.iconSize, lineWidth: 8))

            Text(message)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)
                .multilineTextAlignment(.center)
        }
    }

    func deviceList(_ devices: [PrinterDevice]) -> some View {
        VStack(spacing: POSSpacing.large) {
            Text(Localization.selectPrinterTitle)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: POSSpacing.small) {
                ForEach(devices) { device in
                    Button {
                        controller.connect(to: device)
                    } label: {
                        HStack(spacing: POSSpacing.medium) {
                            Text(device.name)
                                .font(.posBodyLargeRegular())
                                .foregroundStyle(Color.posOnSurface)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(POSPadding.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.posSurfaceContainerLowest)
                        .posItemCardBorderStyles()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(device.name)
                }
            }
        }
    }
}

// MARK: - Buttons per discovery state
private extension POSPrinterSetupModal {
    var buttonConfiguration: PointOfSaleFlowButtonConfiguration? {
        switch controller.discoveryState {
        case .idle:
            return setupButtons(primaryTitle: Localization.connectButton)
        case .found(let devices) where devices.isEmpty:
            return setupButtons(primaryTitle: Localization.searchAgainButton)
        case .error:
            return setupButtons(primaryTitle: Localization.searchAgainButton)
        case .searching, .found, .connecting:
            return nil
        }
    }

    func setupButtons(primaryTitle: String) -> PointOfSaleFlowButtonConfiguration {
        .init(primaryButton: .init(title: primaryTitle, action: {
            controller.startDiscovery()
        }),
              secondaryButton: .init(title: Localization.settingsButton, action: {
            openDeviceSettings()
        }))
    }

    func openDeviceSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }
}

// MARK: - Constants
private extension POSPrinterSetupModal {
    enum Constants {
        static let iconSize: CGFloat = 112
        static let maxParentHeightRatio: CGFloat = 0.9
        static let parentWidthRatio: CGFloat = 0.75
    }

    enum Localization {
        static let pairTitle = NSLocalizedString(
            "pos.printerSetup.pair.title",
            value: "Pair your printer",
            comment: "Title for the printer pairing step in POS settings.")

        static let pairInstruction = NSLocalizedString(
            "pos.printerSetup.pair.instruction",
            value: "Turn on your Star Micronics receipt printer and enable Bluetooth, "
                + "then tap Connect printer to start searching.",
            comment: "Instruction for pairing a receipt printer in POS settings.")

        static let connectButton = NSLocalizedString(
            "pos.printerSetup.connectButton",
            value: "Connect printer",
            comment: "Button to start printer discovery after pairing in POS settings.")

        static let settingsButton = NSLocalizedString(
            "pos.printerSetup.settingsButton",
            value: "Open Settings",
            comment: "Secondary button that opens the app's Settings page, where Bluetooth can be enabled, during receipt printer setup in POS.")

        static let searching = NSLocalizedString(
            "pos.printerSetup.searching",
            value: "Searching for printers…",
            comment: "Message shown while discovering receipt printers in POS settings.")

        static let selectPrinterTitle = NSLocalizedString(
            "pos.printerSetup.selectPrinter.title",
            value: "Select your printer",
            comment: "Title shown above the list of discovered receipt printers in POS settings.")

        static let connectingFormat = NSLocalizedString(
            "pos.printerSetup.connecting.format",
            value: "Connecting to %1$@…",
            comment: "Message shown while connecting to a receipt printer. %1$@ is the printer name.")

        static let noPrintersTitle = NSLocalizedString(
            "pos.printerSetup.noPrinters.title",
            value: "No printers found",
            comment: "Title shown when no receipt printers are discovered in POS settings.")

        static let noPrintersMessage = NSLocalizedString(
            "pos.printerSetup.noPrinters.message",
            value: "Make sure your printer is on and Bluetooth is enabled, then search again.",
            comment: "Message shown when no receipt printers are discovered in POS settings.")

        static let errorTitle = NSLocalizedString(
            "pos.printerSetup.error.title",
            value: "Something went wrong",
            comment: "Title shown when receipt printer setup fails in POS settings.")

        static let errorMessage = NSLocalizedString(
            "pos.printerSetup.error.message",
            value: "We couldn't connect to your printer. Please try again.",
            comment: "Message shown when receipt printer setup fails in POS settings.")

        static let searchAgainButton = NSLocalizedString(
            "pos.printerSetup.searchAgainButton",
            value: "Search again",
            comment: "Button to retry receipt printer discovery in POS settings.")
    }
}

#if DEBUG
#Preview {
    POSPrinterSetupModal(isPresented: .constant(true),
                         controller: POSPrinterConnectionController(service: POSReceiptPrinterPreviewService()))
}
#endif
