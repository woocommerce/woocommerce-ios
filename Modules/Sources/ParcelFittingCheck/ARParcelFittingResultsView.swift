import SwiftUI

struct ARParcelFittingResultsView: View {
    let viewModel: ARParcelFittingResultsViewModel
    let onToggleStar: ((String, String) -> Void)?
    let onConfirm: (ParcelFittingResult) -> Void
    let onBack: () -> Void

    @State private var starredPackageIDs: Set<String>
    @State private var selection: Selection?

    init(viewModel: ARParcelFittingResultsViewModel,
         starredPackageIDs: Set<String>,
         onToggleStar: ((String, String) -> Void)?,
         onConfirm: @escaping (ParcelFittingResult) -> Void,
         onBack: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onToggleStar = onToggleStar
        self.onConfirm = onConfirm
        self.onBack = onBack
        self._starredPackageIDs = State(initialValue: starredPackageIDs)
    }

    enum Selection: Hashable {
        case carrier(String)
        case custom
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionHeader(Localization.measuredHeader)
                        MeasuredDimensionsCard(
                            dimensions: viewModel.measuredDimensions,
                            unit: viewModel.unit
                        )
                    }

                    if viewModel.carrierResults.isEmpty {
                        noMatchSection
                    } else {
                        bestFitSection
                    }

                    exactSizeSection
                }
                .padding(.horizontal)
                .padding(.top, Constants.topPadding)
            }

            Button {
                confirmSelection()
            } label: {
                Text(Localization.useSelectedPackage)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .disabled(selection == nil)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Localization.navigationTitle)
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

    // MARK: - Sections

    private var bestFitSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(String(format: Localization.bestFitHeader, viewModel.carrierResults.count))

            VStack(spacing: 0) {
                ForEach(viewModel.carrierResults) { result in
                    CarrierPackageRow(
                        carrier: result.carrier,
                        package: result.package,
                        unit: viewModel.unit,
                        isSelected: selection == .carrier(result.package.id),
                        isStarred: starredPackageIDs.contains(result.package.id),
                        onSelect: { selection = .carrier(result.package.id) },
                        onToggleStar: onToggleStar.map { callback in
                            {
                                let id = result.package.id
                                if starredPackageIDs.contains(id) {
                                    starredPackageIDs.remove(id)
                                } else {
                                    starredPackageIDs.insert(id)
                                }
                                callback(id, result.carrier.id)
                            }
                        }
                    )

                    if result.id != viewModel.carrierResults.last?.id {
                        Divider().padding(.leading, Constants.dividerLeadingPadding)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
        }
    }

    private var noMatchSection: some View {
        VStack(alignment: .leading, spacing: Constants.sectionHeaderBottomPadding) {
            sectionHeader(Localization.noCarrierMatchHeader)
            NoCarrierMatchView()
        }
    }

    private var exactSizeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(Localization.useExactSizeHeader)

            CustomDimensionsRow(
                dimensions: viewModel.measuredDimensions,
                unit: viewModel.unit,
                isSelected: selection == .custom,
                onSelect: { selection = .custom }
            )
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.bottom, Constants.sectionHeaderBottomPadding)
    }

    // MARK: - Actions

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
}

#Preview("With carrier matches") {
    NavigationView {
        ARParcelFittingResultsView(
            viewModel: ARParcelFittingResultsViewModel(
                measuredDimensions: ParcelDimensions(length: 20.0, width: 15.0, height: 10.0),
                unit: .centimeters,
                carriers: [
                    ParcelPresetCarrier(id: "usps", name: "USPS", packages: [
                        ParcelPresetPackage(id: "usps_medium", name: "Priority Mail Medium Box",
                                            length: 28.0, width: 22.0, height: 15.0),
                    ]),
                    ParcelPresetCarrier(id: "fedex", name: "FedEx", packages: [
                        ParcelPresetPackage(id: "fedex_medium", name: "Medium Box (M2)",
                                            length: 33.0, width: 24.0, height: 17.0),
                    ]),
                ]
            ),
            starredPackageIDs: ["usps_medium"],
            onToggleStar: { _, _ in },
            onConfirm: { _ in },
            onBack: {}
        )
    }
}

#Preview("No carrier matches") {
    NavigationView {
        ARParcelFittingResultsView(
            viewModel: ARParcelFittingResultsViewModel(
                measuredDimensions: ParcelDimensions(length: 20.0, width: 15.0, height: 10.0),
                unit: .centimeters,
                carriers: []
            ),
            starredPackageIDs: [],
            onToggleStar: nil,
            onConfirm: { _ in },
            onBack: {}
        )
    }
}

private extension ARParcelFittingResultsView {
    enum Constants {
        static let sectionSpacing: CGFloat = 24
        static let topPadding: CGFloat = 16
        static let dividerLeadingPadding: CGFloat = 60
        static let cornerRadius: CGFloat = 12
        static let sectionHeaderBottomPadding: CGFloat = 8
    }

    enum Localization {
        static let navigationTitle = "Pick a package"
        static let measuredHeader = "MEASURED"
        static let useSelectedPackage = "Select Package"
        static let bestFitHeader = "BEST FIT · %d OPTIONS"
        static let noCarrierMatchHeader = "NO CARRIER MATCH"
        static let useExactSizeHeader = "USE EXACT SIZE"
    }
}
