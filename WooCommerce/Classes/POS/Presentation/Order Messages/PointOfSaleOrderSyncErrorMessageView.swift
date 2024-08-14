import SwiftUI

struct PointOfSaleOrderSyncErrorMessageView: View {
    let viewModel: PointOfSaleOrderSyncErrorMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: Constants.headerSpacing) {
                Spacer()
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Color(.wooCommerceAmber(.shade60)))
                    .font(.system(size: 64))
                VStack(alignment: .center, spacing: Constants.textSpacing) {
                    Text(viewModel.title)
                        .foregroundStyle(Color.posPrimaryTexti3)
                        .font(.posTitleEmphasized)

                    Text(viewModel.message)
                        .foregroundStyle(Color.posPrimaryTexti3)
                        .font(.posBodyRegular)
                        .padding([.leading, .trailing])
                }
                Spacer()
                Button(viewModel.actionModel.title, action: viewModel.actionModel.handler)
                    .buttonStyle(POSPrimaryButtonStyle())
                    .padding([.leading, .trailing], Constants.buttonSidePadding)
                    .padding([.bottom], Constants.buttonBottomPadding)
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

private extension PointOfSaleOrderSyncErrorMessageView {
    enum Constants {
        static let headerSpacing: CGFloat = 24
        static let textSpacing: CGFloat = 16
        static let buttonSidePadding: CGFloat = 40
        static let buttonBottomPadding: CGFloat = 16
    }
}
