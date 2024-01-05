import SwiftUI

/// View to set ad destination for a new Blaze campaign
struct BlazeAdDestinationSettingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                Text("Destination URL")

                destinationItem(title: "The Product URL",
                                subtitle: "It will link to https://woo.com/",
                                showCheckmark: true,
                                showBottomDivider: true)

                destinationItem(title: "The site home",
                                subtitle: "It will link to https://woo.com/")

                Text("URL Parameters")

                parameterItem(itemName: "specialpromo")

                Button("Add parameter") {
                    // todo
                }
                .buttonStyle(PlusButtonStyle())

                Text("2096 characters remaining")

                Text("Destination: http://woo.com/")

                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.adDestination)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destinationItem(title: String,
                                 subtitle: String,
                                 showCheckmark: Bool = false,
                                 showBottomDivider: Bool = false) -> some View {
        HStack(alignment: .center, spacing: Layout.contentSpacing) {
            if showCheckmark {
                Image(systemName: "checkmark")
                    .padding(.leading, Layout.contentSpacing)
            } else {
                Image(systemName: "checkmark")
                    .hidden() // Small hack to make the icon space consistent while not showing the icon.
                    .padding(.leading, Layout.contentSpacing)
            }

            VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                Text(title)
                    .font(.body)
                    .fontWeight(.bold)

                Text(subtitle)
                    .font(.caption)

                if showBottomDivider {
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private func parameterItem(itemName: String)  -> some View {
        VStack {
            HStack {
                Text(itemName)
                Spacer()
                Image(systemName: "chevron.right")
            }
            Divider()
        }
    }
}

private extension BlazeAdDestinationSettingView {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
        static let contentSpacing: CGFloat = 16
    }

    enum Localization {
        static let cancel = NSLocalizedString(
            "blazeAdDestinationSettingView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the Blaze Ad Destination setting screen"
        )
        static let adDestination = NSLocalizedString(
            "blazeAdDestinationSettingView.adDestination",
            value: "Ad Destination",
            comment: "Title of the Blaze Ad Destination setting screen."
        )
    }
}

struct BlazeAdDestinationSettingView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeAdDestinationSettingView()
    }
}
