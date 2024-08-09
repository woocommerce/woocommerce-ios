import SwiftUI

struct POSFloatingControlView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            Menu {
                Button {
                    viewModel.showExitPOSModal = true
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        Image(PointOfSaleAssets.exit.imageName)
                        Text("Exit POS")
                    }
                }
                Button {
                    presentationMode.wrappedValue.dismiss()
                    // TODO: implement Get Support https://github.com/woocommerce/woocommerce-ios/issues/13401
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        Image(PointOfSaleAssets.getSupport.imageName)
                        Text("Get Support")
                    }
                }
            } label: {
                HStack {
                    Text("⋯")
                        .font(Constants.ellipsisFont)
                        .foregroundStyle(fontColor)
                }
                .frame(width: Constants.size, height: Constants.size)
            }
            .background(backgroundColor)
            .cornerRadius(Constants.cornerRadius)
            .disabled(viewModel.isExitPOSDisabled)
            HStack {
                CardReaderConnectionStatusView(connectionViewModel: viewModel.cardReaderConnectionViewModel)
                    .padding(Constants.cardStatusPadding)
                    .foregroundStyle(fontColor)
            }
            .frame(height: Constants.size)
            .background(backgroundColor)
            .cornerRadius(Constants.cornerRadius)
        }
        .background(Color.clear)
    }
}

private extension POSFloatingControlView {
    var backgroundColor: Color {
        switch backgroundAppearance {
        case .primary:
            Color(.systemBackground)
        case .secondary:
            Color(.wooCommercePurple(.shade80))
        }
    }

    var fontColor: Color {
        switch backgroundAppearance {
        case .primary:
            .primaryText
        case .secondary:
            .posSecondaryTextInverted
        }
    }
}

private extension POSFloatingControlView {
    enum Constants {
        static let buttonImageAndTextSpacing: CGFloat = 12
        static let cardStatusPadding: CGFloat = 8
        static let size: CGFloat = 56
        static let cornerRadius: CGFloat = 8
        static let ellipsisFont = Font.system(size: 24.0, weight: .semibold)
    }
}
