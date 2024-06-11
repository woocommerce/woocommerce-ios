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
                if let topSubtitle = viewModel.topSubtitle {
                    Text(topSubtitle)
                        .font(.title)
                }
            }

            if viewModel.showLoadingIndicator {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(1.5, anchor: .center)
            } else {
                viewModel.image
                    .padding()
            }

            if let bottomTitle = viewModel.bottomTitle {
                VStack(alignment: .center, spacing: Layout.defaultVerticalSpacing) {
                    Text(bottomTitle)
                        .font(.subheadline)

                    if let bottomSubtitle = viewModel.bottomSubtitle {
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
            case error
            case errorNonRetryable
            case processing
            case displayReaderMessage

            var id: String {
                rawValue
            }
        }

        private let alertDetailsByType: [AlertType: CardPresentPaymentAlertDetails] = [
            .scanningForReaders: .scanningForReaders(cancel: {}),
            .scanningFailed: .scanningFailed(error: NSError(domain: "", code: 1, userInfo: nil),
                                             close: {}),
            .bluetoothRequired: .
bluetoothRequired,
            .connectingToReader: .connectingToReader,
            .connectingFailed: .connectingFailed(error: NSError(domain: "", code: 1, userInfo: nil),
                                                 retrySearch: {},
                                                 cancelSearch: {}),
            .connectingFailedUpdatePostalCode: .connectingFailedUpdatePostalCode(retrySearch: {}, 
                                                                                 cancelSearch: {}),
            .connectingFailedChargeReader: .connectingFailedChargeReader(retrySearch: {},
                                                                         cancelSearch: {}),
            .connectingFailedUpdateAddress: .connectingFailedUpdateAddress(wcSettingsAdminURL: nil, 
                                                                           retrySearch: {},
                                                                           cancelSearch: {}),
            .preparingForPayment: .preparingForPayment(onCancel: {}),
            .selectSearchType: .selectSearchType(tapToPay: {},
                                                 bluetooth: {},
                                                 cancel: {}),
            .foundReader: .foundReader(name: "M100 Reader",
                                       connect: {},
                                       continueSearch: {},
                                       cancelSearch: {}),
            .updateProgress: .updateProgress(requiredUpdate: true,
                                             progress: 0.4,
                                             cancel: nil),
            .updateFailed: .updateFailed(tryAgain: {}, close: {}),
            .updateFailedLowBattery: .updateFailedLowBattery(batteryLevel: 0.6,
                                                             close: {}),
            .updateFailedNonRetryable: .errorNonRetryable(error: NSError(domain: "", code: 1, userInfo: nil),
                                                          dismissCompletion: {}),
            .tapCard: .tapSwipeOrInsertCard(inputMethods: [.tap, .insert, .swipe], 
                                            cancel: {}),
            .success: .success(done: {}),
            .error: .error(error: NSError(domain: "", code: 1, userInfo: nil),
                           tryAgain: {},
                           dismissCompletion: {}),
            .errorNonRetryable: .errorNonRetryable(error: NSError(domain: "", code: 1, userInfo: nil),
                                                   dismissCompletion: {}),
            .processing: .processing,
            .displayReaderMessage: .displayReaderMessage(message: "Reader message")
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
                if let alertDetails = alertDetailsByType[alertType] {
                    CardPresentPaymentAlert(
                        alertViewModel: CardPresentPaymentAlertViewModel(
                            alertDetails: alertDetails))
                } else {
                    EmptyView()
                }
            }
        }
    }

    return AlertPreviewWrapper()
}

#endif
