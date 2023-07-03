import SwiftUI

struct UpgradeTopBarView: View {
    let dismiss: () -> Void

    var body: some View {
        HStack {
            Spacer()

            Text(Localization.navigationTitle)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityAddTraits(.isHeader)

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .leading) {
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: Layout.closeButtonSize))
                    .foregroundColor(Color(.label))
                    .padding()
                    .frame(alignment: .leading)
            }
        }
    }
}

private extension UpgradeTopBarView {
    enum Localization {
        static let navigationTitle = NSLocalizedString("Upgrade", comment: "Navigation title for the Upgrades screen")
    }

    enum Layout {
        static let closeButtonSize: CGFloat = 16
    }
}
