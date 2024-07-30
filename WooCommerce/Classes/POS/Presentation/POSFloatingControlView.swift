import SwiftUI

struct POSFloatingControlView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel

    init(viewModel: PointOfSaleDashboardViewModel, totalsViewModel: TotalsViewModel) {
        self.viewModel = viewModel
        self.totalsViewModel = totalsViewModel
    }

    var body: some View {
        HStack {
            Menu {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        Image(uiImage: UIImage.posExitImage)
                        Text("Exit POS")
                    }
                }
                Button {
                    presentationMode.wrappedValue.dismiss()
                    // TODO: implement Get Support https://github.com/woocommerce/woocommerce-ios/issues/13401
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        Image(uiImage: UIImage.posGetSupportImage)
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
                CardReaderConnectionStatusView(connectionViewModel: viewModel.cardReaderConnectionViewModel, totalsViewModel: totalsViewModel)
                    .padding(Constants.cardStatusPadding)
                    .foregroundStyle(fontColor)
            }
            .frame(height: Constants.size)
            .background(backgroundColor)
            .cornerRadius(Constants.cornerRadius)
        }
        .background(Color.clear)
    }

    private var backgroundColor: Color {
        if totalsViewModel.paymentState == .processingPayment {
            return Color(.wooCommercePurple(.shade80))
        } else {
            return .white
        }
    }

    private var fontColor: Color {
        if totalsViewModel.paymentState == .processingPayment {
            return .posSecondaryTextDark
        } else {
            return .primaryText
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
