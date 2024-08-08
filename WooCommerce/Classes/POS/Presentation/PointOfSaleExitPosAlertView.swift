import SwiftUI

struct PointOfSaleExitPosAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0 ) {
            HStack {
                Spacer()
                Button {
                    viewModel.showExitPOSModal = false
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: Constants.closeIconSize, height: Constants.closeIconSize)
                        .foregroundColor(Color.posTertiaryTexti3)
                }
                .frame(width: Constants.closeButtonSize, height: Constants.closeButtonSize)
            }
            Text(Localization.exitTitle)
                .font(.posModalTitle)
                .padding(.bottom)
            Text(Localization.exitBody)
                .font(.posModalBody)
                .padding(.bottom)
                .padding(.bottom)
                .padding(.bottom)
            Button {
                dismiss()
            } label: {
                Text(Localization.exitButton)
            }
            .buttonStyle(POSPrimaryButtonStyle())
        }
        .padding()
        .padding()
    }
}

private extension PointOfSaleExitPosAlertView {
    enum Constants {
        static let closeIconSize: CGFloat = 30.0
        static let closeButtonSize: CGFloat = 40.0
    }

    enum Localization {
        static let exitTitle = NSLocalizedString(
            "pos.exitPOSModal.exitTitle",
            value: "Exit Point of Sale mode?",
            comment: "Title of the exit Point of Sale modal alert"
        )
        static let exitBody = NSLocalizedString(
            "pos.exitPOSModal.exitBody",
            value: "Any orders in progress will be lost.",
            comment: "Body text of the exit Point of Sale modal alert"
        )
        static let exitButton = NSLocalizedString(
            "pos.exitPOSModal.exitButtom",
            value: "Exit",
            comment: "Button text of the exit Point of Sale modal alert"
        )
    }
}
