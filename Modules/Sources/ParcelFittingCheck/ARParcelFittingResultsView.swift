import SwiftUI

public struct ARParcelFittingResultsView: View {
    let viewModel: ARParcelFittingResultsViewModel
    var delegate: ParcelFittingDelegate?
    let onConfirm: (ParcelFittingResult) -> Void
    let onBack: () -> Void
    let onBrowseAllPackages: (() -> Void)?

    @State private var starredPackageIDs: Set<String>
    @State private var selection: Selection?

    public init(viewModel: ARParcelFittingResultsViewModel,
         starredPackageIDs: Set<String>,
         delegate: ParcelFittingDelegate?,
         onConfirm: @escaping (ParcelFittingResult) -> Void,
         onBack: @escaping () -> Void,
         onBrowseAllPackages: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.onConfirm = onConfirm
        self.onBack = onBack
        self.onBrowseAllPackages = onBrowseAllPackages
        self._starredPackageIDs = State(initialValue: starredPackageIDs)
    }

    enum Selection: Hashable {
        case carrier(String)
        case custom
    }

    public var body: some View {
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

                    if let onBrowseAllPackages {
                        Button {
                            onBrowseAllPackages()
                        } label: {
                            Text(Localization.browseAllPackages)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
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
            let count = viewModel.carrierResults.count
            let headerFormat = count == 1 ? Localization.bestFitHeaderSingular : Localization.bestFitHeaderPlural
            sectionHeader(String.localizedStringWithFormat(headerFormat, count))

            VStack(spacing: 0) {
                ForEach(viewModel.carrierResults) { result in
                    CarrierPackageRow(
                        carrier: result.carrier,
                        package: result.package,
                        unit: viewModel.unit,
                        isSelected: selection == .carrier(result.package.id),
                        isStarred: starredPackageIDs.contains(result.package.id),
                        onSelect: { selection = .carrier(result.package.id) },
                        onToggleStar: delegate.map { delegate in
                            {
                                let id = result.package.id
                                let willBeStarred = !starredPackageIDs.contains(id)
                                if willBeStarred {
                                    starredPackageIDs.insert(id)
                                } else {
                                    starredPackageIDs.remove(id)
                                }
                                delegate.parcelFittingDidToggleStar(packageID: id, carrierID: result.carrier.id, isStarred: willBeStarred)
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
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .padding(.bottom, Constants.sectionHeaderBottomPadding)
    }

    // MARK: - Actions

    private func confirmSelection() {
        switch selection {
        case .carrier(let packageID):
            if let result = viewModel.carrierResults.first(where: { $0.package.id == packageID }) {
                onConfirm(.carrierPackage(result.package, measurement: viewModel.measuredDimensions))
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
            delegate: nil,
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
            delegate: nil,
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
        static let navigationTitle = NSLocalizedString(
            "parcelFitting.results.navigationTitle",
            value: "Pick a package",
            comment: "Navigation title for the AR parcel fitting results screen")
        static let measuredHeader = NSLocalizedString(
            "parcelFitting.results.measuredHeader",
            value: "Measured",
            comment: "Section header for the measured dimensions on the AR results screen")
        static let useSelectedPackage = NSLocalizedString(
            "parcelFitting.results.selectPackage",
            value: "Select Package",
            comment: "Button to confirm the selected package on the AR results screen")
        static let bestFitHeaderSingular = NSLocalizedString(
            "parcelFitting.results.bestFitHeader.singular",
            value: "Best fit · %1$d option",
            comment: "Section header for best-fit carrier packages when exactly one option is shown. %1$d is the number of options")
        static let bestFitHeaderPlural = NSLocalizedString(
            "parcelFitting.results.bestFitHeader.plural",
            value: "Best fit · %1$d options",
            comment: "Section header for best-fit carrier packages when more than one option is shown. %1$d is the number of options")
        static let noCarrierMatchHeader = NSLocalizedString(
            "parcelFitting.results.noCarrierMatchHeader",
            value: "No carrier match",
            comment: "Section header when no carrier packages fit the measured dimensions")
        static let useExactSizeHeader = NSLocalizedString(
            "parcelFitting.results.useExactSizeHeader",
            value: "Use exact size",
            comment: "Section header for the custom dimensions option on the AR results screen")
        static let browseAllPackages = NSLocalizedString(
            "parcelFitting.results.browseAllPackages",
            value: "Browse all packages",
            comment: "Link to open the full package selection screen from the AR results screen")
    }
}
