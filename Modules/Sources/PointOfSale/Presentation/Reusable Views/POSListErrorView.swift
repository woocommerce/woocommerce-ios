import SwiftUI
import WooFoundation
import struct WooFoundationCore.WooAnalyticsEvent

/// A view that displays an error message with a retry CTA when the list of POS items fails to load.
struct POSListErrorView: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(\.posAnalytics) private var analytics

    private let error: PointOfSaleErrorState
    private let viewModel: POSListErrorViewModel
    private let onAction: (() -> Void)?
    private let onExit: (() -> Void)?

    @State private var viewWidth: CGFloat = 0

    @Environment(\.keyboardObserver) private var keyboard

    init(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil, onExit: (() -> Void)? = nil) {
        self.error = error
        self.viewModel = POSListErrorViewModel(error: error)
        self.onAction = onAction
        self.onExit = onExit
    }

    var body: some View {
        ScrollableVStack {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                if !keyboard.isFullSizeKeyboardVisible {
                    if let image = viewModel.imageAsset {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 88, height: 88)
                            .foregroundColor(.posOnSurfaceVariantHighest)
                    } else {
                        POSErrorXMark(size: .large)
                    }
                    Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.imageAndTextSpacing)
                }

                Text(viewModel.title)
                    .accessibilityAddTraits(.isHeader)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)
                    .font(.posHeadingBold)

                Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.textSpacing)

                Text(viewModel.subtitle)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posBodyLargeRegular())
                    .multilineTextAlignment(.center)
                    .padding([.leading, .trailing])

                if let onAction {
                    Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.textAndButtonSpacing)
                    Button(action: {
                        // Track retry tapped for splash screen errors (initial catalog sync)
                        if error.errorType == .initialCatalogSyncError {
                            analytics.track(event: WooAnalyticsEvent.LocalCatalog.splashScreenRetryTapped())
                        }
                        onAction()
                    }, label: {
                        Text(viewModel.buttonText)
                    })
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
                    .frame(width: viewWidth / 2)
                    .padding([.leading, .trailing])
                }

                if let onExit {
                    Spacer().frame(height: POSSpacing.medium)
                    Button(action: {
                        onExit()
                    }, label: {
                        Text(Localization.exitButtonText)
                    })
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                    .frame(width: viewWidth / 2)
                    .padding([.leading, .trailing])
                }
            }
            Spacer()
        }
        .padding(.bottom, !keyboard.isFullSizeKeyboardVisible ? floatingControlAreaSize.height : 0)
        .measureWidth { width in
            viewWidth = width
        }
        .onAppear {
            // Track error shown for splash screen errors (initial catalog sync)
            if error.errorType == .initialCatalogSyncError {
                analytics.track(event: WooAnalyticsEvent.LocalCatalog.splashScreenErrorShown())
            }
        }
    }
}

struct POSListErrorViewModel {
    let title: String
    let subtitle: String
    let buttonText: String
    let imageAsset: Image?

    init(error: PointOfSaleErrorState) {
        self.title = error.title
        self.subtitle = error.subtitle
        self.buttonText = error.buttonText
        switch error.errorType {
        case .couponsDisabled:
            self.imageAsset = SharedImageAsset.coupons.decorativeImage
        default:
            self.imageAsset = nil
        }
    }
}

private enum Localization {
    static let exitButtonText = NSLocalizedString(
        "pos.listError.exitButton",
        value: "Exit POS",
        comment: "Button text to exit Point of Sale when there's a critical error"
    )
}

#Preview {
    POSListErrorView(error: .errorCouponsDisabled, onAction: {})
}

#Preview {
    POSListErrorView(error: .errorOnLoadingCoupons(), onAction: {})
}
