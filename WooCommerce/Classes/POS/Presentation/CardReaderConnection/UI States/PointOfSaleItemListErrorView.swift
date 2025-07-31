import SwiftUI
import struct WooFoundation.ScrollableVStack

/// A view that displays an error message with a retry CTA when the list of POS items fails to load.
@available(iOS 17.0, *)
struct PointOfSaleItemListErrorView: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    private let viewModel: PointOfSaleItemListErrorViewModel
    private let onAction: (() -> Void)?

    @State private var viewWidth: CGFloat = 0

    @Environment(\.keyboardObserver) private var keyboard

    init(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil) {
        self.viewModel = PointOfSaleItemListErrorViewModel(error: error)
        self.onAction = onAction
    }

    var body: some View {
        ScrollableVStack {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                if !keyboard.isFullSizeKeyboardVisible {
                    if let imageName = viewModel.imageAsset?.imageName {
                        Image(decorative: imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 88, height: 88)
                            .foregroundColor(.posOnSurfaceVariantHighest)
                    } else {
                        POSErrorExclamationMark(size: .large)
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
                        onAction()
                    }, label: {
                        Text(viewModel.buttonText)
                    })
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
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
    }
}

struct PointOfSaleItemListErrorViewModel {
    let title: String
    let subtitle: String
    let buttonText: String
    let imageAsset: PointOfSaleAssets?

    init(error: PointOfSaleErrorState) {
        self.title = error.title
        self.subtitle = error.subtitle
        self.buttonText = error.buttonText
        switch error.errorType {
        case .couponsDisabled:
            self.imageAsset = PointOfSaleAssets.coupons
        default:
            self.imageAsset = nil
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    PointOfSaleItemListErrorView(error: .errorCouponsDisabled, onAction: {})
}

@available(iOS 17.0, *)
#Preview {
    PointOfSaleItemListErrorView(error: .errorOnLoadingCoupons(), onAction: {})
}
