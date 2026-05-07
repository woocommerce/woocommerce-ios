import SwiftUI

struct ARParcelFittingResultsView: View {
    let viewModel: ARParcelFittingResultsViewModel
    let starredPackageIDs: Set<String>
    let onToggleStar: ((String, String) -> Void)?
    let onConfirm: (ParcelFittingResult) -> Void
    let onBack: () -> Void

    @State private var selection: Selection?

    enum Selection: Hashable {
        case carrier(String)
        case custom
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.carrierResults) { result in
                    carrierRow(result)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
                customRow
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)

            Divider()
            Button {
                confirmSelection()
            } label: {
                Text("Use selected package")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .disabled(selection == nil)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .navigationTitle("Select a package")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { onBack() } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }

    private func carrierRow(_ result: ARParcelFittingResultsViewModel.CarrierResult) -> some View {
        let isSelected = selection == .carrier(result.package.id)
        let isStarred = starredPackageIDs.contains(result.package.id)
        return HStack(spacing: 0) {
            Button { selection = .carrier(result.package.id) } label: {
                HStack(spacing: 0) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .gray)
                        .font(.title)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if let logo = result.carrier.logo {
                                Image(uiImage: logo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 16)
                            }
                            Text(result.carrier.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(result.package.name)
                            .font(.body)
                        Text(Self.formatDimensions(result.package, unit: viewModel.unit))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 4)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if onToggleStar != nil {
                Button {
                    onToggleStar?(result.package.id, result.carrier.id)
                } label: {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(.secondary)
                        .padding(16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 16)
    }

    private var customRow: some View {
        let isSelected = selection == .custom
        return Button { selection = .custom } label: {
            HStack(spacing: 0) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray)
                    .font(.title)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom dimensions")
                        .font(.body)
                    Text(viewModel.dimensionsLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 4)
                Spacer()
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private func confirmSelection() {
        switch selection {
        case .carrier(let packageID):
            if let result = viewModel.carrierResults.first(where: { $0.package.id == packageID }) {
                onConfirm(.carrierPackage(result.package))
            }
        case .custom:
            onConfirm(.customDimensions(viewModel.measuredDimensions))
        case nil:
            break
        }
    }

    private static func formatDimensions(_ package: ParcelPresetPackage, unit: UnitLength) -> String {
        String(format: "%.2f × %.2f × %.2f %@", package.length, package.width, package.height, unit.symbol)
    }
}
