import SwiftUI

struct POSFloatingControlView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @Environment(\.colorScheme) var colorScheme

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            Menu {
                Button {
                    viewModel.showExitPOSModal = true
                } label: {
                    Label(
                        title: { Text(Localization.exitPointOfSale) },
                        icon: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
                    )
                }
                Button {
                    viewModel.showSupport = true
                } label: {
                    Label(
                        title: { Text(Localization.getSupport) },
                        icon: { Image(systemName: "questionmark.circle") }
                    )
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.posBodyEmphasized, maximumContentSizeCategory: .accessibilityLarge)
                    .foregroundStyle(fontColor)
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
            colorScheme == .light ? .posSecondaryBackground : .posTertiaryBackground
        case .secondary:
            colorScheme == .light ? Color(.wooCommercePurple(.shade80)) : Color(.wooCommercePurple(.shade20))
        }
    }

    var fontColor: Color {
        switch backgroundAppearance {
        case .primary:
            .posPrimaryText
        case .secondary:
            .posSecondaryText
        }
    }
}

private extension POSFloatingControlView {
    enum Constants {
        static let cardStatusPadding: CGFloat = 8
        static let size: CGFloat = 56
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let exitPointOfSale = NSLocalizedString(
            "pointOfSale.floatingButtons.exit.button.title",
            value: "Exit POS",
            comment: "The title of the floating button to exit Point of Sale, shown in a popover menu." +
            "The action is confirmed in a modal."
        )

        static let getSupport = NSLocalizedString(
            "pointOfSale.floatingButtons.getSupport.button.title",
            value: "Get Support",
            comment: "The title of the floating button to get support for Point of Sale, shown in a popover menu."
        )
    }
}
