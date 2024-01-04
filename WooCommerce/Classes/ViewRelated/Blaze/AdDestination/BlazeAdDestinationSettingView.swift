import SwiftUI

/// View to set ad destination for a new Blaze campaign
struct BlazeAdDestinationSettingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollableVStack(alignment: .leading) {
                // todo add content:
                // -----------------

                // Destination URL section
                // - small heading
                // - two rows (each row has a selection, only 1 can be selected at a time)
                //   - The product URL with label text below
                //   - The site home

                // URL parameters section
                // - small heading
                // - foreach row of added parameters
                // - + Add parameter button
                // - character count label
                // - Final URL destination preview
            }
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
}

private extension BlazeAdDestinationSettingView {
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
