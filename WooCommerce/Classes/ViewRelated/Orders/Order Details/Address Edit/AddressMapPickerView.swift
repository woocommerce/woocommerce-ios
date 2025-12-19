import MapKit
import SwiftUI
import Observation
import struct Yosemite.Country

struct AddressMapPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddressMapPickerViewModel
    @Binding private var fields: AddressFormFields
    @FocusState private var isSearchFocused: Bool

    init(fields: Binding<AddressFormFields>, countryByCode: @escaping (_ countryCode: String) -> Country?) {
        self._fields = fields
        self.viewModel = AddressMapPickerViewModel(fields: fields.wrappedValue, countryByCode: countryByCode)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $viewModel.position) {
                    UserAnnotation()
                    ForEach(viewModel.annotations) { item in
                        Marker("", coordinate: item.coordinate)
                    }
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding()
                        .background(Color(.systemBackground))

                    if viewModel.showsSearchResults {
                        List(viewModel.searchResults, id: \.self) { result in
                            Button(action: {
                                Task { @MainActor in
                                    isSearchFocused = false
                                    await viewModel.selectLocation(result)
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title)
                                        .font(.body)
                                        .foregroundStyle(Color(uiColor: .textLink))
                                    Text(result.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(Color(uiColor: .textSubtle))
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .padding()
                        }
                        .listStyle(.plain)
                        .padding(.top, 0)
                    } else if viewModel.showsNoResultsMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(Color(uiColor: .warning))
                                Text(Localization.noResultsTitle)
                                    .font(.headline)
                                    .foregroundColor(Color(uiColor: .warning))
                            }

                            Text(Localization.noResultsHint)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                    } else if viewModel.selectedPlaceAddress.isNotEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.selectedPlaceAddress)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                    }
                }
            }
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
                        ServiceLocator.analytics.track(.orderDetailEditAddressMapPickerUseAddressTapped)
                    }
                    .disabled(!viewModel.hasValidSelection)
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
        .task {
            await viewModel.startObservingSearchQuery()
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

private extension AddressMapPickerView {
    enum Localization {
        static let close = NSLocalizedString("addressMapPicker.button.close", value: "Close", comment: "Text for the close button in the Edit Address Form.")
        static let useThisAddress = NSLocalizedString(
            "addressMapPicker.button.useThisAddress",
            value: "Use This Address",
            comment: "Button to confirm selected address from map."
        )
        static let searchPlaceholder = NSLocalizedString(
            "addressMapPicker.search.placeholder",
            value: "Search for an address",
            comment: "Placeholder text for address search bar."
        )
        static let noResultsTitle = NSLocalizedString(
            "addressMapPicker.noResults.title",
            value: "No Results Found",
            comment: "Title shown when address search returns no results."
        )
        static let noResultsHint = NSLocalizedString(
            "addressMapPicker.noResults.hint",
            value: "Try searching without apartment, suite, or floor numbers. You can add those details to Address Line 2 later.",
            comment: "Hint shown when address search returns no results, suggesting to omit unit details and add them to address line 2."
        )
    }
}

#Preview {
    AddressMapPickerView(fields: .constant(.init()), countryByCode: { _ in nil })
}
