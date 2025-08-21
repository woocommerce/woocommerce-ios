import SwiftUI

struct PointOfSaleSettingsStoreDetailView: View {
    @Environment(\.dismiss) private var dismiss

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
