import SwiftUI

struct POSConnectivityView: View {
    var body: some View {
        HStack(spacing: Constants.spacing) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(Color(.text.inverted))
                .font(.posDetailEmphasized)

            Text(Localization.title)
                .foregroundColor(Color(.text.inverted))
                .font(.posDetailEmphasized)
        }
        .padding(.vertical, Constants.verticalPadding)
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(minHeight: Constants.height)
        .background(Color(.systemGray6.inverted))
        .cornerRadius(Constants.cornerRadius)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
    }
}

private extension POSConnectivityView {
    enum Constants {
        static let cornerRadius: CGFloat = 16
        static let height: CGFloat = 64
        static let spacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 24
        static let verticalPadding: CGFloat = 8
    }


    enum Localization {
        static let title = NSLocalizedString(
            "pos.connectivity.title",
            value: "No internet connection",
            comment: "Title shown on a toast view that appears when there's no internet connection"
        )
    }
}
