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
            VStack(alignment: .center) {
                Text(viewModel.topTitle)
                    .multilineTextAlignment(.center)
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
                VStack(alignment: .center) {
                    Text(bottomTitle)
                        .font(.subheadline)

                    if let bottomSubtitle = viewModel.bottomSubtitle, shouldShowBottomSubtitle() {
                        Text(bottomSubtitle)
                            .font(.footnote)
                    }
                }
            }

            VStack(spacing: Layout.buttonVerticalSpacing) {
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
        static let buttonVerticalSpacing: CGFloat = 16
    }
}

#if DEBUG

#Preview {
    enum AlertType: String {
        case scanningForReaders
        case foundReader
    }

    let alertViewModelsByType: [AlertType: CardPresentPaymentAlertViewModel] = [
        .scanningForReaders: CardPresentModalScanningForReader(cancel: {}),
        .foundReader: CardPresentModalFoundReader(name: "Stripe M2", connect: {}, continueSearch: {}, cancel: {})
    ]

    return Text("Presenting view")
        .sheet(isPresented: .constant(true)) {
            if let viewModel = alertViewModelsByType[.foundReader] {
                CardPresentPaymentAlert(alertViewModel: viewModel)
            } else {
                EmptyView()
            }
        }
}

#endif
