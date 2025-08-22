import SwiftUI

struct PointOfSaleSettingsStoreDetailView: View {
    @Environment(\.dismiss) private var dismiss

    var storeName: String {
        guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
            return "Not set"
        }
        return site.name
    }

    var storeAddress: String {
        SiteAddress().address
    }

    var storeEmail: String {
        "Not set" // TBD
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Store Information")
                    .font(.title2)

                Text("Store name")
                Text(storeName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Address")
                Text(storeAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Email")
                Text(storeEmail)
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


#Preview {
    PointOfSaleSettingsStoreDetailView()
}
