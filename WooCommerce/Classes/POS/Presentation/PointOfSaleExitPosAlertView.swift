import SwiftUI

struct PointOfSaleExitPosAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding private var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        VStack(spacing: 0 ) {
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.posButtonSymbol)
                }
                .foregroundColor(Color.posTertiaryText)
            }
            Text(Localization.exitTitle)
                .font(.posTitleEmphasized)
                .padding(.bottom, Constants.titleBottomPadding)
            Text(Localization.exitBody)
                .font(.posBodyRegular)
                .padding(.bottom, Constants.bodyBottomPadding)
            Button {
                dismiss()
            } label: {
                Text(Localization.exitButton)
            }
            .buttonStyle(POSPrimaryButtonStyle())
        }
        .padding(Constants.padding)
    }
}

private extension PointOfSaleExitPosAlertView {
    enum Constants {
        static let titleBottomPadding: CGFloat = 20.0
        static let bodyBottomPadding: CGFloat = 60.0
        static let padding: CGFloat = 40.0
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
