import SwiftUI

struct PointOfSaleSettingsStoreDetailView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Store Settings")
                    .font(.title2)
                Text("Store-related configuration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
