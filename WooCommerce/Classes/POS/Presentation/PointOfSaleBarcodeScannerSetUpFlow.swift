import SwiftUI

// MARK: - Data Models
struct ScannerOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let scannerType: ScannerType
}

enum ScannerType {
    case socketS720
    case starBSH20B
    case tbcScanner
    case other
}

// MARK: - Flow State
enum SetupFlowState {
    case scannerSelection
    case setupFlow(ScannerType)
}

// MARK: - Setup Flow Manager
class SetupFlowManager: ObservableObject {
    @Published var currentState: SetupFlowState = .scannerSelection

    func selectScanner(_ scannerType: ScannerType) {
        currentState = .setupFlow(scannerType)
    }

    func goBackToSelection() {
        currentState = .scannerSelection
    }

    func getCurrentStep() -> SetupStep? {
        switch currentState {
        case .scannerSelection:
            return nil
        case .setupFlow(let scannerType):
            return getStep(for: scannerType)
        }
    }

    private func getStep(for scannerType: ScannerType) -> SetupStep {
        switch scannerType {
        case .socketS720:
            return SetupStep(
                title: "Socket S720 Setup",
                content: { SocketS720WelcomeView() },
                nextButtonTitle: "Done",
                canGoBack: true
            )
        case .starBSH20B:
            return SetupStep(
                title: "Star BSH-20B Setup",
                content: { StarBSH20BWelcomeView() },
                nextButtonTitle: "Done",
                canGoBack: true
            )
        case .tbcScanner:
            return SetupStep(
                title: "TBC Scanner Setup",
                content: { TBCScannerWelcomeView() },
                nextButtonTitle: "Done",
                canGoBack: true
            )
        case .other:
            return SetupStep(
                title: "General Scanner Setup",
                content: { OtherScannerView() },
                nextButtonTitle: "Done",
                canGoBack: true
            )
        }
    }
}

// MARK: - Setup Step
struct SetupStep {
    let title: String
    let content: any View
    let nextButtonTitle: String
    let isNextButtonEnabled: Bool
    let canGoBack: Bool

    init(
        title: String,
        @ViewBuilder content: () -> any View,
        nextButtonTitle: String = "Next",
        isNextButtonEnabled: Bool = true,
        canGoBack: Bool = true
    ) {
        self.title = title
        self.content = content()
        self.nextButtonTitle = nextButtonTitle
        self.isNextButtonEnabled = isNextButtonEnabled
        self.canGoBack = canGoBack
    }
}

@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerSetUpFlow: View {
    @Binding var isPresented: Bool
    @StateObject private var flowManager = SetupFlowManager()

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            // Header
            PointOfSaleModalHeader(isPresented: $isPresented,
                                   title: .constant(AttributedString(currentTitle)))

            VStack {
                currentContent
                Spacer()
            }
            .scrollVerticallyIfNeeded()

            // Bottom buttons
            HStack(spacing: POSSpacing.medium) {
                Button(Localization.backButtonTitle) {
                    handleBackButton()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                .renderedIf(shouldShowBackButton)

                Button(currentNextButtonTitle) {
                    handleNextButton()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .disabled(!isNextButtonEnabled)
            }
        }
        .padding(POSPadding.xxLarge)
        .background(Color.posSurfaceBright)
        .containerRelativeFrame([.horizontal, .vertical]) { length, _ in
            max(length * 0.75, Constants.modalFrameMaxSmallDimension)
        }
        .onAppear {
            ServiceLocator.analytics.track(.pointOfSaleBarcodeScannerSetupFlowShown)
        }
    }

    // MARK: - Computed Properties
    private var currentTitle: String {
        switch flowManager.currentState {
        case .scannerSelection:
            return Localization.setupHeading
        case .setupFlow:
            return flowManager.getCurrentStep()?.title ?? Localization.setupHeading
        }
    }

    @ViewBuilder
    private var currentContent: some View {
        switch flowManager.currentState {
        case .scannerSelection:
            ScannerSelectionView(options: scannerOptions) { scannerType in
                flowManager.selectScanner(scannerType)
            }
        case .setupFlow:
            if let step = flowManager.getCurrentStep() {
                AnyView(step.content)
            }
        }
    }

    private var currentNextButtonTitle: String {
        switch flowManager.currentState {
        case .scannerSelection:
            return Localization.selectButtonTitle
        case .setupFlow:
            return flowManager.getCurrentStep()?.nextButtonTitle ?? Localization.nextButtonTitle
        }
    }

    private var isNextButtonEnabled: Bool {
        switch flowManager.currentState {
        case .scannerSelection:
            return false // No selection made yet
        case .setupFlow:
            return flowManager.getCurrentStep()?.isNextButtonEnabled ?? false
        }
    }

    private var shouldShowBackButton: Bool {
        switch flowManager.currentState {
        case .scannerSelection:
            return false
        case .setupFlow:
            return flowManager.getCurrentStep()?.canGoBack ?? false
        }
    }

    // MARK: - Actions
    private func handleBackButton() {
        switch flowManager.currentState {
        case .scannerSelection:
            break // Should not happen
        case .setupFlow:
            flowManager.goBackToSelection()
        }
    }

    private func handleNextButton() {
        switch flowManager.currentState {
        case .scannerSelection:
            break // Should not happen
        case .setupFlow:
            isPresented = false
        }
    }

    private var scannerOptions: [ScannerOption] {
        [
            ScannerOption(
                title: Localization.socketS720Title,
                subtitle: Localization.socketS720Subtitle,
                scannerType: .socketS720
            ),
            ScannerOption(
                title: Localization.starBSH20BTitle,
                subtitle: Localization.starBSH20BSubtitle,
                scannerType: .starBSH20B
            ),
            ScannerOption(
                title: Localization.tbcScannerTitle,
                subtitle: Localization.tbcScannerSubtitle,
                scannerType: .tbcScanner
            ),
            ScannerOption(
                title: Localization.otherTitle,
                subtitle: Localization.otherSubtitle,
                scannerType: .other
            )
        ]
    }
}

// MARK: - Scanner Selection View
struct ScannerSelectionView: View {
    let options: [ScannerOption]
    let onSelection: (ScannerType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.setupIntroMessage)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurface)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: POSSpacing.small) {
                ForEach(options) { option in
                    Button {
                        onSelection(option.scannerType)
                    } label: {
                        ScannerOptionView(
                            title: option.title,
                            subtitle: option.subtitle
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Scanner Option View
struct ScannerOptionView: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text(title)
                    .font(.posBodyLargeBold)
                    .foregroundColor(.posOnSurface)
                Text(subtitle)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(.posOnSurfaceVariantHighest)
            }
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.posBodyMediumBold)
                .foregroundColor(.posOnSurfaceVariantHighest)
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceDim)
        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
    }
}

// MARK: - Step Views
struct SocketS720WelcomeView: View {
    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            Text("Socket S720 Scanner")
                .font(.posBodyLargeBold)
                .foregroundColor(.posOnSurface)

            Text("TODO: Implement Socket S720 setup flow WOOMOB-698")
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StarBSH20BWelcomeView: View {
    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            Text("Star BSH-20B Scanner")
                .font(.posBodyLargeBold)
                .foregroundColor(.posOnSurface)

            Text("TODO: Implement Star BSH-20B setup flow WOOMOB-696")
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TBCScannerWelcomeView: View {
    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            Text("TBC Scanner")
                .font(.posBodyLargeBold)
                .foregroundColor(.posOnSurface)

            Text("TODO: Implement TBC scanner setup flow WOOMOB-699")
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OtherScannerView: View {
    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            BarcodeScannerInformationContent()
        }
    }
}

// MARK: - Constants
private enum Constants {
    static var modalFrameMaxSmallDimension: CGFloat { 752 }
}

// MARK: - Localization
private enum Localization {
    static let setupHeading = NSLocalizedString(
        "pos.barcodeScannerSetup.heading",
        value: "Barcode Scanner Setup",
        comment: "Heading for the barcode scanner setup flow in POS"
    )
    static let setupIntroMessage = NSLocalizedString(
        "pos.barcodeScannerSetup.introMessage",
        value: "Choose your barcode scanner to get started with the setup process.",
        comment: "Introductory message in the barcode scanner setup flow in POS"
    )
    static let socketS720Title = NSLocalizedString(
        "pos.barcodeScannerSetup.socketS720.title",
        value: "Socket S720",
        comment: "Title for Socket S720 scanner option in barcode scanner setup"
    )
    static let socketS720Subtitle = NSLocalizedString(
        "pos.barcodeScannerSetup.socketS720.subtitle",
        value: "Small handheld scanner with a charging dock or stand",
        comment: "Subtitle for Socket S720 scanner option in barcode scanner setup"
    )
    static let starBSH20BTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.starBSH20B.title",
        value: "Star BSH-20B",
        comment: "Title for Star BSH-20B scanner option in barcode scanner setup"
    )
    static let starBSH20BSubtitle = NSLocalizedString(
        "pos.barcodeScannerSetup.starBSH20B.subtitle",
        value: "Ergonomic scanner with a stand",
        comment: "Subtitle for Star BSH-20B scanner option in barcode scanner setup"
    )
    static let tbcScannerTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.tbcScanner.title",
        value: "Scanner TBC",
        comment: "Title for TBC scanner option in barcode scanner setup"
    )
    static let tbcScannerSubtitle = NSLocalizedString(
        "pos.barcodeScannerSetup.tbcScanner.subtitle",
        value: "Recommended scanner",
        comment: "Subtitle for TBC scanner option in barcode scanner setup"
    )
    static let otherTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.other.title",
        value: "Other",
        comment: "Title for other scanner option in barcode scanner setup"
    )
    static let otherSubtitle = NSLocalizedString(
        "pos.barcodeScannerSetup.other.subtitle",
        value: "General scanner setup instructions",
        comment: "Subtitle for other scanner option in barcode scanner setup"
    )
    static let backButtonTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.back.button.title",
        value: "Back",
        comment: "Title for the back button in barcode scanner setup navigation"
    )
    static let nextButtonTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.next.button.title",
        value: "Next",
        comment: "Title for the next button in barcode scanner setup navigation"
    )
    static let doneButtonTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.done.button.title",
        value: "Done",
        comment: "Title for the done button in barcode scanner setup navigation"
    )
    static let selectButtonTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.select.button.title",
        value: "Select",
        comment: "Title for the select button in barcode scanner setup navigation"
    )
}

@available(iOS 17.0, *)
#Preview {
    PointOfSaleBarcodeScannerSetUpFlow(isPresented: .constant(true))
}
