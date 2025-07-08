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
    case setupFlow(ScannerType, stepIndex: Int = 0)
}

// MARK: - Setup Step
struct SetupStep {
    let title: String
    let content: any View
    let nextButtonTitle: String
    let isNextButtonEnabled: Bool
    let canGoBack: Bool
    let onNext: () -> Void
    let onBack: () -> Void

    init(
        title: String,
        @ViewBuilder content: () -> any View,
        nextButtonTitle: String = Localization.nextButtonTitle,
        isNextButtonEnabled: Bool = true,
        canGoBack: Bool = true,
        onNext: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.title = title
        self.content = content()
        self.nextButtonTitle = nextButtonTitle
        self.isNextButtonEnabled = isNextButtonEnabled
        self.canGoBack = canGoBack
        self.onNext = onNext
        self.onBack = onBack
    }
}

extension SetupStep {
    var shouldShowBackButton: Bool {
        canGoBack
    }

    var shouldShowNextButton: Bool {
        true // Always show next button
    }
}

// MARK: - Setup Flow Manager
@available(iOS 17.0, *)
@Observable
class SetupFlowManager {
    var currentState: SetupFlowState = .scannerSelection
    @ObservationIgnored @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    func selectScanner(_ scannerType: ScannerType) {
        currentState = .setupFlow(scannerType, stepIndex: 0)
    }

    func goBackToSelection() {
        currentState = .scannerSelection
    }

    func nextStep() {
        switch currentState {
        case .scannerSelection:
            break
        case .setupFlow(let scannerType, let stepIndex):
            let steps = getSteps(for: scannerType)
            if stepIndex < steps.count - 1 {
                currentState = .setupFlow(scannerType, stepIndex: stepIndex + 1)
            }
        }
    }

    func previousStep() {
        switch currentState {
        case .scannerSelection:
            break
        case .setupFlow(let scannerType, let stepIndex):
            if stepIndex > 0 {
                currentState = .setupFlow(scannerType, stepIndex: stepIndex - 1)
            } else {
                goBackToSelection()
            }
        }
    }

    func getCurrentStep() -> SetupStep? {
        switch currentState {
        case .scannerSelection:
            return nil
        case .setupFlow(let scannerType, let stepIndex):
            let steps = getSteps(for: scannerType)
            return steps[safe: stepIndex]
        }
    }

    func isComplete() -> Bool {
        switch currentState {
        case .scannerSelection:
            return false
        case .setupFlow(let scannerType, let stepIndex):
            let steps = getSteps(for: scannerType)
            return stepIndex >= steps.count - 1
        }
    }

    private func createWelcomeStep(title: String) -> SetupStep {
        SetupStep(
            title: title,
            content: { ScannerWelcomeView(title: title) },
            nextButtonTitle: Localization.doneButtonTitle,
            canGoBack: true,
            onNext: { [weak self] in
                self?.isPresented = false
            },
            onBack: { [weak self] in
                self?.previousStep()
            }
        )
    }

    private func getSteps(for scannerType: ScannerType) -> [SetupStep] {
        switch scannerType {
        case .socketS720:
            return [
                createWelcomeStep(title: "Socket S720 Setup")
                // TODO: Add more steps for Socket S720 WOOMOB-698
            ]
        case .starBSH20B:
            return [
                createWelcomeStep(title: "Star BSH-20B Setup")
                // TODO: Add more steps for Star BSH-20B WOOMOB-696
            ]
        case .tbcScanner:
            return [
                createWelcomeStep(title: "TBC Scanner Setup")
                // TODO: Add more steps for TBC Scanner WOOMOB-699
            ]
        case .other:
            return [
                SetupStep(
                    title: "General Scanner Setup",
                    content: { BarcodeScannerInformationContent() },
                    nextButtonTitle: Localization.doneButtonTitle,
                    canGoBack: true,
                    onNext: { [weak self] in
                        self?.isPresented = false
                    },
                    onBack: { [weak self] in
                        self?.previousStep()
                    }
                )
            ]
        }
    }
}

@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerSetUpFlow: View {
    @Binding var isPresented: Bool
    @State private var flowManager: SetupFlowManager

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.flowManager = SetupFlowManager(isPresented: isPresented)
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
            FlowButtonsView(flowManager: flowManager)
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

// MARK: - Flow Buttons View
@available(iOS 17.0, *)
struct FlowButtonsView: View {
    let flowManager: SetupFlowManager

    var body: some View {
        HStack(spacing: POSSpacing.medium) {
            if let step = flowManager.getCurrentStep(), step.shouldShowBackButton {
                Button(Localization.backButtonTitle) {
                    step.onBack()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))

                Button(step.nextButtonTitle) {
                    step.onNext()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .disabled(!step.isNextButtonEnabled)
            }
        }
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
struct ScannerWelcomeView: View {
    let title: String

    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            Text(title)
                .font(.posBodyLargeBold)
                .foregroundColor(.posOnSurface)

            Text("TODO: Implement \(title) setup flow")
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}

@available(iOS 17.0, *)
#Preview {
    PointOfSaleBarcodeScannerSetUpFlow(isPresented: .constant(true))
}
