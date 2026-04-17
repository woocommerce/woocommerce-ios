import SwiftUI

struct POSPrinterSetupModal: View {
    @Binding var isPresented: Bool
    let onConnect: () -> Void
    @Environment(\.posModalParentSize) var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            ScrollView(showsIndicators: false) {
                HStack {
                    Spacer()
                    pairingContent
                    Spacer()
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: [.vertical])

            PointOfSaleFlowButtonsView(
                configuration: .init(
                    primaryButton: .init(
                        title: Localization.connectButton,
                        action: onConnect),
                    secondaryButton: nil))
        }
        .posModalCloseButton(action: {
            isPresented = false
        })
        .padding(POSPadding.xLarge)
        .background(Color.posSurfaceBright)
        .frame(maxWidth: parentSize.width * Constants.parentWidthRatio,
               maxHeight: parentSize.height * Constants.maxParentHeightRatio)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var pairingContent: some View {
        VStack(spacing: POSSpacing.xLarge) {
            Image(systemName: "printer")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundStyle(Color.posOnSurface)

            VStack(alignment: .center, spacing: POSSpacing.small) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(Localization.instruction)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurface)
                    .multilineTextAlignment(.center)
            }

            Button {
                guard let targetURL = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                UIApplication.shared.open(targetURL)
            } label: {
                Text(Localization.settingsButton)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posPrimaryContainer)
                    .underline()
            }
            .padding(.top, POSSpacing.large)
        }
    }
}

private extension POSPrinterSetupModal {
    enum Constants {
        static let iconSize: CGFloat = 112
        static let maxParentHeightRatio: CGFloat = 0.9
        static let parentWidthRatio: CGFloat = 0.75
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.printerSetup.title",
            value: "Pair your printer",
            comment: "Title for the printer pairing step in POS settings")

        static let instruction = NSLocalizedString(
            "pos.printerSetup.instruction",
            value: "Turn on your Star Micronics receipt printer, enable Bluetooth, and select it in your iPad's Bluetooth settings. Then tap Connect printer below.",
            comment: "Instruction for pairing a receipt printer via iPad Bluetooth settings")

        static let settingsButton = NSLocalizedString(
            "pos.printerSetup.settingsButton",
            value: "Go to your device settings",
            comment: "Button to open iPad Settings for Bluetooth printer pairing")

        static let connectButton = NSLocalizedString(
            "pos.printerSetup.connectButton",
            value: "Connect printer",
            comment: "Button to start printer discovery after pairing in POS settings")
    }
}

#if DEBUG
#Preview {
    POSPrinterSetupModal(isPresented: .constant(true), onConnect: { })
}
#endif
