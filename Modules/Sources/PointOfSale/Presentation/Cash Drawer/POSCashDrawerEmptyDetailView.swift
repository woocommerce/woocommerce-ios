import SwiftUI

/// Detail pane shown when nothing is selected in the `POSCashDrawerView` sidebar.
struct POSCashDrawerEmptyDetailView: View {
    var body: some View {
        ZStack {
            VStack {
                POSPageHeaderView(title: POSCashDrawerView.Localization.navigationTitle, backButtonConfiguration: nil)
                Spacer()
            }

            VStack {
                Spacer()

                Image(systemName: "dollarsign.circle")
                    .font(.system(size: Constants.iconSize))
                    .foregroundColor(.posOnSurface)

                Spacer().frame(height: POSSpacing.medium)

                Text(Localization.noSelection)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)

                Spacer()
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }
}

private enum Constants {
    static let iconSize: CGFloat = 64
}

private enum Localization {
    static let noSelection = NSLocalizedString(
        "pointOfSaleCashDrawerEmptyDetailView.noSelection",
        value: "Select an option to get started.",
        comment: "Text appearing in the cash drawer detail pane when nothing is selected in the sidebar."
    )
}

#if DEBUG
#Preview {
    POSCashDrawerEmptyDetailView()
}
#endif
