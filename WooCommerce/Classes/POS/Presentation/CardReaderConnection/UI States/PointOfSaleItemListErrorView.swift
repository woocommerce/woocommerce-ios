import SwiftUI

/// A view that displays an error message with a retry CTA when the list of POS items fails to load.
@available(iOS 17.0, *)
struct PointOfSaleItemListErrorView: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    private let error: PointOfSaleErrorState
    private let onAction: (() -> Void)?
    private let iconView: () -> AnyView

    @State private var viewWidth: CGFloat = 0

    @Environment(\.keyboardObserver) private var keyboard

    init(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil) {
        self.error = error
        self.onAction = onAction
        self.iconView = { AnyView(POSErrorExclamationMark(size: .large)) }
    }

    init<Icon: View>(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil, iconView: @escaping () -> Icon) {
        self.error = error
        self.onAction = onAction
        self.iconView = { AnyView(iconView()) }
    }

    var body: some View {
        ScrollableVStack {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                if !keyboard.isFullSizeKeyboardVisible {
                    iconView()

                    Spacer().frame(height: POSSpacing.medium)
                }

                Text(error.title)
                    .accessibilityAddTraits(.isHeader)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)
                    .font(.posHeadingBold)

                Spacer().frame(height: POSSpacing.small)

                Text(error.subtitle)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posBodyLargeRegular())
                    .multilineTextAlignment(.center)
                    .padding([.leading, .trailing])

                Spacer().frame(height: POSSpacing.large)

                Button(action: {
                    onAction?()
                }, label: {
                    Text(error.buttonText)
                })
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .frame(width: viewWidth / 2)
                .padding([.leading, .trailing])
            }
            Spacer()
        }
        .padding(.bottom, !keyboard.isFullSizeKeyboardVisible ? floatingControlAreaSize.height : 0)
        .measureWidth { width in
            viewWidth = width
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    VStack(spacing: 40) {
        PointOfSaleItemListErrorView(error: .errorOnLoadingCoupons(), onAction: nil)
        PointOfSaleItemListErrorView(error: .errorOnLoadingCoupons(), onAction: nil) {
            Image(systemName: "xmark.octagon.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.red)
        }
    }
}
