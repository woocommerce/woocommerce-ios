import SwiftUI

/// Displays the WooPayments onboarding UI based on the state.
struct PointOfSaleCardPresentPaymentOnboardingView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.posAccessSession) private var session
    @ObservedObject var viewModel: PointOfSaleCardPresentPaymentOnboardingViewModel
    var onSupportRequested: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: metrics.spacing.large) {
            AnyView(viewModel.onboardingViewContainer.view)
                // Hides the navigation bar title `navigationTitle` in `CardPresentPaymentsOnboardingView`.
                .toolbar(.hidden)
        }
        .posModalCloseButton(action: viewModel.cancelOnboarding,
                             accessibilityLabel: Localization.cancelOnboarding)
        .safariSheet(url: $viewModel.onboardingURL)
        .posModalSizing()
        .onChange(of: session.isLocked, initial: true) { _, _ in
            if let onSupportRequested {
                let context = POSExternalViewContext(session: session)
                viewModel.onboardingViewContainer.configuration.showSupport = context.whileSessionIsCurrent(onSupportRequested)
            }
        }
    }
}

extension View {
    func posCardPaymentsOnboarding(item: Binding<CardPresentPaymentOnboardingViewContainer?>,
                                   onDismiss: @escaping () -> Void,
                                   onSupportRequested: (() -> Void)? = nil,
                                   onPresented: @escaping () -> Void) -> some View {
        posModal(item: item, compactStyle: .cardPaymentsOnboarding, preservesOnLock: { true }, onDismiss: onDismiss) { factory in
            PointOfSaleCardPresentPaymentOnboardingView(
                viewModel: .init(onboardingViewContainer: factory, onDismissTap: onDismiss),
                onSupportRequested: onSupportRequested
            )
            .onAppear(perform: onPresented)
        }
    }
}

extension POSModalCompactStyle {
    static var cardPaymentsOnboarding: POSModalCompactStyle {
        .fullScreen(title: NSLocalizedString(
            "pos.cardPaymentsOnboarding.modal.title",
            value: "Card payments",
            comment: "Title in the header of the full-screen card payments onboarding flow on phone."
        ))
    }
}

private extension PointOfSaleCardPresentPaymentOnboardingView {
    enum Localization {
        static let cancelOnboarding = NSLocalizedString(
            "pointOfSaleDashboard.payments.onboarding.cancel",
            value: "Cancel",
            comment: "Button to dismiss the payments onboarding sheet from the POS dashboard."
        )
    }
}

#if DEBUG

import enum Yosemite.CardPresentPaymentOnboardingState

final class PreviewOnboardingViewContainerConfiguration: CardPresentPaymentsOnboardingViewConfiguration {
    var showSupport: (() -> Void)?
    var showURL: ((URL) -> Void)?
    var state: CardPresentPaymentOnboardingState = .loading
}

#Preview {
    PointOfSaleCardPresentPaymentOnboardingView(viewModel: .init(
        onboardingViewContainer: .init(configuration: PreviewOnboardingViewContainerConfiguration()), onDismissTap: nil)
    )
    .posPreviewModalParentSize()
}
#endif
