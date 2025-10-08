import SwiftUI
import WooFoundation

/// A view that displays an error message with a retry CTA when the list of POS items fails to load.
struct POSListErrorView: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    private let viewModel: POSListErrorViewModel
    private let onAction: (() -> Void)?

    @State private var viewWidth: CGFloat = 0

    @Environment(\.keyboardObserver) private var keyboard

    init(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil) {
        self.viewModel = POSListErrorViewModel(error: error)
        self.onAction = onAction
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

#Preview {
    POSListErrorView(error: .errorCouponsDisabled, onAction: {})
}

#Preview {
    POSListErrorView(error: .errorOnLoadingCoupons(), onAction: {})
}
