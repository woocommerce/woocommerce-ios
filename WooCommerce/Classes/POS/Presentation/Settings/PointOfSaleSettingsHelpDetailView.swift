import SwiftUI

struct PointOfSaleSettingsHelpDetailView: View {
    @Environment(\.dismiss) private var dismiss

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
