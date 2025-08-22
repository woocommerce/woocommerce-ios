import SwiftUI

struct PointOfSaleSettingsHelpDetailView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Help Settings")
                    .font(.title2)
                Text("Help-related configuration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
