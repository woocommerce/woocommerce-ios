import SwiftUI
import WooFoundation

struct POSErrorView: View {
    @Environment(\.keyboardObserver) private var keyboard

    let viewModel: POSErrorViewModel
    @Binding var buttonWidth: CGFloat?

    init(viewModel: POSErrorViewModel, buttonWidth: Binding<CGFloat?>? = nil) {
        self.viewModel = viewModel
        if let buttonWidth {
            self._buttonWidth = buttonWidth
        } else {
            self._buttonWidth = Binding<CGFloat?>(
                get: { nil },
                set: { _ in })
        }
    }

    var body: some View {
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
                .font(.posHeadingBold)

            Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.textSpacing)

            Text(viewModel.subtitle)
                .foregroundStyle(Color.posOnSurface)
                .font(.posBodyLargeRegular())
                .padding([.leading, .trailing])

            if viewModel.primaryButton != nil || viewModel.secondaryButton != nil {
                Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.textAndButtonSpacing)
                VStack(spacing: POSSpacing.medium) {
                    if let primaryButtonViewModel = viewModel.primaryButton {
                        POSErrorButton(viewModel: primaryButtonViewModel)
                    }

                    if let secondaryButtonViewModel = viewModel.secondaryButton {
                        POSErrorButton(viewModel: secondaryButtonViewModel)
                    }
                }
                .frame(width: buttonWidth)
            }
        }
        .multilineTextAlignment(.center)
        .dynamicTypeSize(..<DynamicTypeSize.accessibility2)
    }
}

struct POSErrorButton: View {
    let viewModel: POSErrorButtonViewModel

    var body: some View {
        Button(action: {
            viewModel.action()
        }, label: {
            Text(viewModel.title)
                .dynamicTypeSize(..<DynamicTypeSize.accessibility2)
        })
        .buttonStyle(viewModel.buttonStyle)
    }
}

struct POSErrorViewModel {
    let title: String
    let subtitle: String
    let imageAsset: Image?
    let primaryButton: POSErrorButtonViewModel?
    let secondaryButton: POSErrorButtonViewModel?

    init(error: PointOfSaleErrorState,
         primaryButton: POSErrorButtonViewModel? = nil,
         secondaryButton: POSErrorButtonViewModel? = nil) {
        self.title = error.title
        self.subtitle = error.subtitle
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        switch error.errorType {
        case .couponsDisabled:
            self.imageAsset = SharedImageAsset.coupons.decorativeImage
        default:
            self.imageAsset = nil
        }
    }
}

struct POSErrorButtonViewModel {
    let title: String
    let buttonStyle: AnyButtonStyle
    let action: () -> Void

    init(title: String, buttonStyle: any ButtonStyle, action: @escaping () -> Void) {
        self.title = title
        self.buttonStyle = AnyButtonStyle(buttonStyle)
        self.action = action
    }
}

struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
