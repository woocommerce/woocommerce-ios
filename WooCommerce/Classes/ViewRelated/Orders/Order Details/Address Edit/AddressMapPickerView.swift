import MapKit
import SwiftUI
import Observation

@available(iOS 17, *)
struct AddressMapPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddressMapPickerViewModel
    @Binding var fields: AddressFormFields
    @FocusState private var isSearchFocused: Bool

    init(fields: Binding<AddressFormFields>) {
        self._fields = fields
        self.viewModel = AddressMapPickerViewModel(fields: fields.wrappedValue)
    }

    var body: some View {
        let _ = Self._printChanges()
        NavigationStack {
            ZStack(alignment: .top) {
                Map(coordinateRegion: $viewModel.region,
                    showsUserLocation: true,
                    annotationItems: viewModel.annotations) { item in
                    MapMarker(coordinate: item.coordinate)
                }

                // Search results list
                VStack(spacing: 0) {
                    searchBar
                        .padding()
                        .background(Color(.systemBackground))

                    if viewModel.showingSearchResults {
                        List(viewModel.searchResults, id: \.self) { result in
                            Button(action: {
                                isSearchFocused = false
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
                        isSearchFocused = false
                        viewModel.updateFields(&fields)
                        dismiss()
                    }
                    .disabled(!viewModel.hasValidSelection)
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
        .task {
            await viewModel.startStream()
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
                .focused($isSearchFocused)

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

@available(iOS 17, *)
private extension AddressMapPickerView {
    enum Localization {
        static let mapPickerTitle = NSLocalizedString("Pick Address", comment: "Title for the map address picker view")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Edit Address Form")
        static let useThisAddress = NSLocalizedString("Use This Address", comment: "Button to confirm selected address from map")
        static let searchPlaceholder = NSLocalizedString("Search for an address", comment: "Placeholder text for address search bar")
        static let pickOnMap = NSLocalizedString("Pick on Map", comment: "Button to open map address picker")
    }
}

#Preview {
    if #available(iOS 17, *) {
        AddressMapPickerView(fields: .constant(.init()))
    } else {
        EmptyView()
    }
}
