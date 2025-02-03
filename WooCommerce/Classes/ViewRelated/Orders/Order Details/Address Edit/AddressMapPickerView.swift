import MapKit
import SwiftUI

struct AddressMapPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddressMapPickerViewModel()
    @Binding var fields: AddressFormFields

    var body: some View {
        let _ = Self._printChanges()
        NavigationStack {
            ZStack(alignment: .top) {
                if viewModel.showingSearchResults {
                    // Search results list
                    VStack(spacing: 0) {
                        searchBar
                            .padding()
                            .background(Color(.systemBackground))

                        List(viewModel.searchResults, id: \.self) { result in
                            Button(action: {
                                viewModel.selectLocation(result)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title)
                                        .font(.body)
                                    Text(result.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    // Map view
                    VStack(spacing: 0) {
                        searchBar
                            .padding()

                        Map(coordinateRegion: $viewModel.region,
                            showsUserLocation: true,
                            annotationItems: viewModel.annotations) { item in
                            MapMarker(coordinate: item.coordinate)
                        }
                    }
                }
            }
            .navigationTitle(Localization.mapPickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.useThisAddress) {
                        viewModel.updateFields(&fields)
                        dismiss()
                    }
                    .disabled(!viewModel.hasValidSelection)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(Localization.searchPlaceholder,
                     text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

private extension AddressMapPickerView {
    enum Localization {
        static let mapPickerTitle = NSLocalizedString("Pick Address", comment: "Title for the map address picker view")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Edit Address Form")
        static let useThisAddress = NSLocalizedString("Use This Address", comment: "Button to confirm selected address from map")
        static let searchPlaceholder = NSLocalizedString("Search for an address", comment: "Placeholder text for address search bar")
        static let pickOnMap = NSLocalizedString("Pick on Map", comment: "Button to open map address picker")
    }
}

//#Preview {
//    AddressMapPickerView(fields: <#Binding<AddressFormFields>#>)
//}
