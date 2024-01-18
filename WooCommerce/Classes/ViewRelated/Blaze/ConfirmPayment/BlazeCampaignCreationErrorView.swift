import SwiftUI

/// View for the error state of a Blaze campaign creation request.
struct BlazeCampaignCreationErrorView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.titlePadding) {
                Image(systemName: "exclamationmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Layout.errorIconSize * scale)
                    .foregroundColor(Color(uiColor: .error))

                Text("Error creating campaign")
                    .bold()
                    .largeTitleStyle()

                VStack(alignment: .leading, spacing: Layout.contentPadding) {
                    Text("Something's not quite right.\nWe couldn't create your campaign.")
                        .bodyStyle()

                    Text("No payment has been taken.")
                        .headlineStyle()

                    Text("Please try again, or contact support for assistance.")
                        .bodyStyle()
                }

                Button {
                    // TODO
                } label: {
                    Label("Get support", systemImage: "questionmark.circle")
                }

                Spacer()
            }
            .padding(Layout.contentPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Layout.contentPadding) {
                Button("Try Again") {
                    // TODO
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Cancel Campaign") {
                    // TODO
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Layout.contentPadding)
            .background(Color(.systemBackground))
        }
    }
}

private extension BlazeCampaignCreationErrorView {
    enum Layout {
        static let errorIconSize: CGFloat = 56
        static let contentPadding: CGFloat = 16
        static let titlePadding: CGFloat = 32
    }
}

#Preview {
    BlazeCampaignCreationErrorView()
}
