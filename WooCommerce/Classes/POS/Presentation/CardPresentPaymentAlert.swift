import SwiftUI

struct CardPresentPaymentAlert: View {
    // TODO: Figure out whether this is the right choice vs @StateObject
    // Using @StateObject resulted in the alert not being updated when
    // alertViewModel changed – possibly we needed to invalidate the view's id.
    @ObservedObject private var viewModel: CardPresentPaymentAlertSwiftUIViewModel

     init(alertViewModel: CardPresentPaymentAlertViewModel) {
        self.viewModel = .init(alertViewModel: alertViewModel)
    }

    var body: some View {
        BasicCardPresentPaymentAlert(viewModel: viewModel.alertViewModel)
            .sheet(item: $viewModel.wcSettingsWebViewModel) { webViewModel in
                WCSettingsWebView(adminUrl: webViewModel.webViewURL, completion: webViewModel.onCompletion)
            }
    }
}

struct BasicCardPresentPaymentAlert: View {
    let viewModel: CardPresentPaymentAlertViewModel

    var body: some View {
        VStack(spacing: Layout.stackViewVerticalSpacing) {
            VStack(alignment: .center, spacing: Layout.defaultVerticalSpacing) {
                Text(viewModel.topTitle)
                    .font(.body)
                if let topSubtitle = viewModel.topSubtitle, shouldShowTopSubtitle() {
                    Text(topSubtitle)
                        .font(.title)
                }
            }

            if viewModel.showLoadingIndicator {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(1.5, anchor: .center)
            } else {
                Image(uiImage: viewModel.image)
                    .padding()
            }

            if let bottomTitle = viewModel.bottomTitle, shouldShowBottomLabels() {
                VStack(alignment: .center, spacing: Layout.defaultVerticalSpacing) {
                    Text(bottomTitle)
                        .font(.subheadline)

                    if let bottomSubtitle = viewModel.bottomSubtitle, shouldShowBottomSubtitle() {
                        Text(bottomSubtitle)
                            .foregroundStyle(Color(uiColor: .systemColor(.secondaryLabel)))
                            .font(.footnote)
                    }
                }
            }

            VStack(spacing: Layout.defaultVerticalSpacing) {
                if let primaryButton = viewModel.primaryButtonViewModel {
                    Button(primaryButton.title, action: primaryButton.actionHandler)
                        .buttonStyle(PrimaryButtonStyle())
                }

                if let secondaryButton = viewModel.secondaryButtonViewModel {
                    Button(secondaryButton.title, action: secondaryButton.actionHandler)
                        .buttonStyle(SecondaryButtonStyle())
                }

                if let auxiliaryButton = viewModel.auxiliaryButtonViewModel {
                    Button(auxiliaryButton.title, action: auxiliaryButton.actionHandler)
                        .buttonStyle(LinkButtonStyle())
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding(Layout.padding)
    }
}

private extension BasicCardPresentPaymentAlert {
    func shouldShowTopSubtitle() -> Bool {
        viewModel.textMode != .reducedTopInfo
    }

    func shouldShowBottomLabels() -> Bool {
        viewModel.textMode != .noBottomInfo
    }

    func shouldShowBottomSubtitle() -> Bool {
        let textMode = viewModel.textMode
        return textMode == .fullInfo ||
            textMode == .reducedTopInfo
    }
}

private extension BasicCardPresentPaymentAlert {
    enum Layout {
        static let padding: EdgeInsets = .init(top: 40, leading: 96, bottom: 56, trailing: 96)
        static let stackViewVerticalSpacing: CGFloat = 32
        static let defaultVerticalSpacing: CGFloat = 16
    }
}

struct DismissableCardPresentPaymentAlert: View {
    let viewModel: CardPresentPaymentAlertViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Layout.stackViewVerticalSpacing) {
            VStack(alignment: .center, spacing: Layout.defaultVerticalSpacing) {
                Text(viewModel.topTitle)
                    .font(.body)
                if let topSubtitle = viewModel.topSubtitle, shouldShowTopSubtitle() {
                    Text(topSubtitle)
                        .font(.title)
                }
            }

            if viewModel.showLoadingIndicator {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(1.5, anchor: .center)
            } else {
                Image(uiImage: viewModel.image)
                    .padding()
            }

            if let bottomTitle = viewModel.bottomTitle, shouldShowBottomLabels() {
                VStack(alignment: .center, spacing: Layout.defaultVerticalSpacing) {
                    Text(bottomTitle)
                        .font(.subheadline)

                    if let bottomSubtitle = viewModel.bottomSubtitle, shouldShowBottomSubtitle() {
                        Text(bottomSubtitle)
                            .foregroundStyle(Color(uiColor: .systemColor(.secondaryLabel)))
                            .font(.footnote)
                    }
                }
            }

            VStack(spacing: Layout.defaultVerticalSpacing) {
                if let primaryButton = viewModel.primaryButtonViewModel {
                    Button(primaryButton.title, action: primaryButton.actionHandler)
                        .buttonStyle(PrimaryButtonStyle())
                }

                if let secondaryButton = viewModel.secondaryButtonViewModel {
                    Button(secondaryButton.title, action: secondaryButton.actionHandler)
                        .buttonStyle(SecondaryButtonStyle())
                }

                if let auxiliaryButton = viewModel.auxiliaryButtonViewModel {
                    Button(auxiliaryButton.title, action: auxiliaryButton.actionHandler)
                        .buttonStyle(LinkButtonStyle())
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding(Layout.padding)
    }
}

private extension DismissableCardPresentPaymentAlert {
    func shouldShowTopSubtitle() -> Bool {
        viewModel.textMode != .reducedTopInfo
    }

    func shouldShowBottomLabels() -> Bool {
        viewModel.textMode != .noBottomInfo
    }

    func shouldShowBottomSubtitle() -> Bool {
        let textMode = viewModel.textMode
        return textMode == .fullInfo ||
            textMode == .reducedTopInfo
    }
}

private extension DismissableCardPresentPaymentAlert {
    enum Layout {
        static let padding: EdgeInsets = .init(top: 40, leading: 96, bottom: 56, trailing: 96)
        static let stackViewVerticalSpacing: CGFloat = 32
        static let defaultVerticalSpacing: CGFloat = 16
    }
}

#if DEBUG

#Preview {
    struct AlertPreviewWrapper: View {
        enum AlertType: String, CaseIterable, Identifiable {
            case scanningForReaders
            case scanningFailed
            case bluetoothRequired
            case connectingToReader
            case connectingFailed
            case connectingFailedUpdatePostalCode
            case connectingFailedChargeReader
            case connectingFailedUpdateAddress
            case preparingForPayment
            case selectSearchType
            case foundReader
            case updateProgress
            case updateFailed
            case updateFailedLowBattery
            case updateFailedNonRetryable
            case tapCard
            case success
            case successWithoutEmail
            case error
            case errorNonRetryable
            case processing
            case displayReaderMessage

            var id: String {
                rawValue
            }
        }

        private let alertViewModelsByType: [AlertType: CardPresentPaymentAlertViewModel] = [
            .scanningForReaders: CardPresentModalScanningForReader(cancel: {}),
            .scanningFailed: CardPresentModalScanningFailed(error: NSError(domain: "", code: 1), image: .alarmBellRingImage, primaryAction: {}),
            .bluetoothRequired: CardPresentModalBluetoothRequired(error: NSError(domain: "", code: 1), primaryAction: {}),
            .connectingToReader: CardPresentModalConnectingToReader(),
            .connectingFailed: CardPresentModalConnectingFailed(error: NSError(domain: "", code: 1), retrySearch: {}, cancelSearch: {}),
            .connectingFailedUpdatePostalCode: CardPresentModalConnectingFailedUpdatePostalCode(image: .alarmBellRingImage, retrySearch: {}, cancelSearch: {}),
            .connectingFailedChargeReader: CardPresentModalConnectingFailedChargeReader(retrySearch: {}, cancelSearch: {}),
            .connectingFailedUpdateAddress: CardPresentModalConnectingFailedUpdateAddress(wcSettingsAdminURL: URL(string: "https://example.com/wp-admin")!,
                                                                                          openWCSettings: nil,
                                                                                          retrySearch: {},
                                                                                          cancelSearch: {}),
            .preparingForPayment: CardPresentModalPreparingForPayment(cancelAction: {}),
            .selectSearchType: CardPresentModalSelectSearchType(tapOnIPhoneAction: {}, bluetoothAction: {}, cancelAction: {}),
            .foundReader: CardPresentModalFoundReader(name: "Stripe M2", connect: {}, continueSearch: {}, cancel: {}),
            .updateProgress: CardPresentModalUpdateProgress(requiredUpdate: true, progress: 0.6, cancel: nil),
            .updateFailed: CardPresentModalUpdateFailed(image: .wcpayIcon, tryAgain: {}, close: {}),
            .updateFailedLowBattery: CardPresentModalUpdateFailedLowBattery(batteryLevel: 0.2, close: {}),
            .updateFailedNonRetryable: CardPresentModalUpdateFailedNonRetryable(image: .alarmBellRingImage, close: {}),
            .tapCard: CardPresentModalTapCard(name: "Stripe M2", amount: "$60", transactionType: .collectPayment, inputMethods: .init(rawValue: 1), onCancel: {}),
            .success: CardPresentModalSuccess(printReceipt: {}, emailReceipt: {}, noReceiptAction: {}),
            .successWithoutEmail: CardPresentModalSuccessWithoutEmail(printReceipt: {}, noReceiptAction: {}),
            .error: CardPresentModalError(errorDescription: "Preview error",
                                          transactionType: .collectPayment,
                                          image: .addImage,
                                          primaryAction: {},
                                          dismissCompletion: {}),
            .errorNonRetryable: CardPresentModalNonRetryableError(amount: "$60", error: NSError(domain: "", code: 1), onDismiss: {}),
            .processing: CardPresentModalProcessing(name: "Preview testing", amount: "$60", transactionType: .collectPayment),
            .displayReaderMessage: CardPresentModalDisplayMessage(name: "Reader displaying message", amount: "$60", message: "Preview testing")
        ]
        @State private var showsAlert: Bool = false
        @State private var alertType: AlertType?

        var body: some View {
            Group {
                ForEach(AlertType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        alertType = type
                    }
                }
            }
            .sheet(item: $alertType) { alertType in
                if let viewModel = alertViewModelsByType[alertType] {
                    CardPresentPaymentAlert(alertViewModel: viewModel)
                } else {
                    EmptyView()
                }
            }
        }
    }

    return AlertPreviewWrapper()
}

#endif
