import SwiftUI

struct PointOfSaleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            Text("Settings")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    PointOfSaleSettingsView()
}
