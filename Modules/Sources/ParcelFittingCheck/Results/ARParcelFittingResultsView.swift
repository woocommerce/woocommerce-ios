import SwiftUI
import EventHorizonSDK

public struct ARParcelFittingResultsView: View {
    let viewModel: ARParcelFittingResultsViewModel
    let analytics: ParcelFittingAnalyticsTracking
    let delegate: ParcelFittingDelegate?
    let onConfirm: (ParcelFittingResult) -> Void
    let onBrowseAllPackages: (() -> Void)?

    @State private var starredPackageIDs: Set<String>
    @State private var selection: Selection?
    @State private var hasTrackedAppearance = false

    public init(viewModel: ARParcelFittingResultsViewModel,
         starredPackageIDs: Set<String>,
         analytics: ParcelFittingAnalyticsTracking,
         delegate: ParcelFittingDelegate?,
         onConfirm: @escaping (ParcelFittingResult) -> Void,
         onBrowseAllPackages: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.analytics = analytics
        self.delegate = delegate
        self.onConfirm = onConfirm
        self.onBrowseAllPackages = onBrowseAllPackages
        self._starredPackageIDs = State(initialValue: starredPackageIDs)
    }

    enum Selection: Hashable {
        case carrier(String)
        case custom
    }

    public var body: some View {
        VStack(spacing: 0) {
            resultsScrollView

            selectPackageButton
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Localization.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !hasTrackedAppearance else { return }
            hasTrackedAppearance = true
            analytics.track(Event.arfittingResultsDisplayed(
                carrierMatchCount: viewModel.carrierResults.count,
                totalCarrierCount: viewModel.totalCarrierCount
            ))
        }
    }

    // MARK: - Subviews

    private var resultsScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                measuredSection

                if viewModel.carrierResults.isEmpty {
                    noMatchSection
                } else {
                    bestFitSection
                }

                exactSizeSection

                browseAllPackagesLink
            }
            .padding(.horizontal)
            .padding(.top, Constants.topPadding)
        }
    }

    private var measuredSection: some View {
        ResultsSectionView(title: Localization.measuredHeader) {
            MeasuredDimensionsCard(
                dimensions: viewModel.measuredDimensions,
                unit: viewModel.unit
            )
        }
    }

    private var bestFitSection: some View {
        ResultsSectionView(title: bestFitHeaderText) {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.carrierResults.enumerated()), id: \.element.id) { index, result in
                    CarrierPackageRow(
                        carrier: result.carrier,
                        package: result.package,
                        unit: viewModel.unit,
                        isSelected: selection == .carrier(result.package.id),
                        isStarred: starredPackageIDs.contains(result.package.id),
                        onSelect: {
                            selection = .carrier(result.package.id)
                            analytics.track(Event.arfittingCarrierPackageSelected(
                                index: index,
                                isStarred: starredPackageIDs.contains(result.package.id)
                            ))
                        },
                        onToggleStar: delegate.map { delegate in
                            { toggleStar(packageID: result.package.id, carrierID: result.carrier.id, index: index, delegate: delegate) }
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
        ResultsSectionView(title: Localization.noCarrierMatchHeader) {
            NoCarrierMatchView()
        }
    }

    private var exactSizeSection: some View {
        ResultsSectionView(title: Localization.useExactSizeHeader) {
            CustomDimensionsRow(
                dimensions: viewModel.measuredDimensions,
                unit: viewModel.unit,
                isSelected: selection == .custom,
                onSelect: {
                    selection = .custom
                    analytics.track(Event.arfittingCustomDimensionsSelected)
                }
            )
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
        }
    }

    @ViewBuilder
    private var browseAllPackagesLink: some View {
        if let onBrowseAllPackages {
            Button {
                analytics.track(Event.arfittingBrowseAllPackagesTapped)
                onBrowseAllPackages()
            } label: {
                Text(Localization.browseAllPackages)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var selectPackageButton: some View {
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

    // MARK: - Helpers

    private var bestFitHeaderText: String {
        let count = viewModel.carrierResults.count
        let format = count == 1 ? Localization.bestFitHeaderSingular : Localization.bestFitHeaderPlural
        return String.localizedStringWithFormat(format, count)
    }

    // MARK: - Actions

    private func toggleStar(packageID: String, carrierID: String, index: Int, delegate: ParcelFittingDelegate) {
        let willBeStarred = !starredPackageIDs.contains(packageID)
        if willBeStarred {
            starredPackageIDs.insert(packageID)
        } else {
            starredPackageIDs.remove(packageID)
        }
        analytics.track(Event.arfittingPackageStarTapped(index: index, isStarred: willBeStarred))
        delegate.parcelFittingDidToggleStar(packageID: packageID, carrierID: carrierID, isStarred: willBeStarred)
    }

    private func confirmSelection() {
        switch selection {
        case .carrier(let packageID):
            if let result = viewModel.carrierResults.first(where: { $0.package.id == packageID }) {
                analytics.track(Event.arfittingSelectPackageTapped(selectionType: .carrier))
                onConfirm(.carrierPackage(result.package, measurement: viewModel.measuredDimensions))
            }
        case .custom:
            analytics.track(Event.arfittingSelectPackageTapped(selectionType: .custom))
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
            analytics: NoOpParcelFittingAnalytics(),
            delegate: nil,
            onConfirm: { _ in }
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
            analytics: NoOpParcelFittingAnalytics(),
            delegate: nil,
            onConfirm: { _ in }
        )
    }
}

private extension ARParcelFittingResultsView {
    enum Constants {
        static let sectionSpacing: CGFloat = 24
        static let topPadding: CGFloat = 16
        static let dividerLeadingPadding: CGFloat = 60
        static let cornerRadius: CGFloat = 12
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
