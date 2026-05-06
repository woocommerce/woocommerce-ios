import ARKit
import Combine
import Experiments
import Foundation
import ParcelFittingCheck
import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

final class WooShippingAddPackageViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager
    private let storage: StorageManagerType
    private let analytics: Analytics
    private let featureFlagService: FeatureFlagService
    private let shippingSettingsService: ShippingSettingsService

    private let starAnimation: Animation = .spring(duration: 0.2)

    // Holds type of selected package, it can be `custom`, `carrier` or `saved`
    @Published var selectedPackageType: WooShippingAddPackageView.PackageProviderType

    init(selectedPackage: WooShippingPackageDataRepresentable? = nil,
         siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService) {
        self.siteID = siteID
        self.stores = stores
        self.storage = storage
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.shippingSettingsService = shippingSettingsService

        selectedPackageType = .custom
        previousSelectedPackage = selectedPackage
        // Optimistically set the selected package ID.
        // We will select the correct package type (custom, carrier or saved) after loading the packages.
        switch selectedPackage?.source {
        case .custom:
            selectedSavedPackageId = selectedPackage?.id
        case .predefined:
            selectedCarriersPackageId = selectedPackage?.id
            selectedSavedPackageId = selectedPackage?.id
        case nil:
            break
        }
        configureResultsController()
        analytics.track(event: .WooShipping.packageSelectionStep(state: .started))
    }

    @Published private(set) var isLoadingPackages: Bool = false
    @Published private(set) var packageLoadingError: Error?
    @Published var notice: Notice?

    /// Holds the previously selected package data, which can be transformed e.g. to select the correct tabs in the view.
    let previousSelectedPackage: WooShippingPackageDataRepresentable?

    // MARK: - saved

    @Published var selectedSavedPackageId: String? = nil  // Track the selected package index
    @Published private(set) var customSavedPackages: [any WooShippingPackageDataRepresentable] = []
    @Published private(set) var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] = []
    var hasSavedPackages: Bool {
        return customSavedPackages.isNotEmpty || predefinedSavedPackages.isNotEmpty
    }

    var selectedSavedPackage: WooShippingPackageDataRepresentable? {
        guard let selectedSavedPackageId else { return nil }

        let packages = customSavedPackages + predefinedSavedPackages

        for packageItem in packages {
            if selectedSavedPackageId == packageItem.id {
                return packageItem
            }
        }

        return nil
    }

    var previousSelectedAndSelectedSavedPackageAreSame: Bool {
        guard let previousSelectedPackage else {
            return false
        }
        return previousSelectedPackage.id == selectedSavedPackageId
    }

    // MARK: - carrier

    @Published private(set) var carrierPackages: [WooShippingCarrierPackages] = []
    @Published var selectedCarriersTabIndex = 0
    @Published var selectedCarriersPackageId: String? = nil
    @Published var starredCarriersPackages: Set<String> = []
    @Published private(set) var carrierTabs: [TopTabItem<EmptyView>] = []
    private var allPredefinedOptions: [WooShippingCarrierPredefinedOptions] = []
    var selectedCarrierTab: WooShippingCarrierPackages? {
        carrierPackages[safe: selectedCarriersTabIndex]
    }
    var selectedCarriersPackage: WooShippingPackageDataRepresentable? {
        guard let selectedCarriersPackageId else { return nil }

        for carrierTab in carrierPackages {
            for packageGroup in carrierTab.packageGroups {
                for packageItem in packageGroup.packages {
                    if selectedCarriersPackageId == packageItem.id {
                        return packageItem
                    }
                }
            }
        }

        return nil
    }
    var previousSelectedAndSelectedCarriersPackageAreSame: Bool {
        guard let previousSelectedPackage else {
            return false
        }
        return previousSelectedPackage.id == selectedCarriersPackageId
    }

    // MARK: - AR Parcel Fitting

    var isARParcelFittingAvailable: Bool {
        featureFlagService.isFeatureFlagEnabled(.arParcelFitting)
        && ARWorldTrackingConfiguration.isSupported
    }

    var arDimensionUnit: UnitLength {
        .fromStoreUnit(shippingSettingsService.dimensionUnit ?? "in")
    }

    var parcelPresetCarriers: [ParcelPresetCarrier] {
        carrierPackages.map { carrier in
            let packages: [ParcelPresetPackage] = carrier.packageGroups.flatMap { group in
                group.packages.compactMap { package in
                    guard let length = Float(package.length),
                          let width = Float(package.width),
                          let height = Float(package.height),
                          length > 0, width > 0, height > 0 else {
                        return nil
                    }
                    return ParcelPresetPackage(
                        id: package.id,
                        name: package.name,
                        length: length,
                        width: width,
                        height: height
                    )
                }
            }
            return ParcelPresetCarrier(
                id: carrier.carrier.rawValue,
                name: carrier.carrier.name,
                packages: packages
            )
        }
    }

    func selectCarrierPackage(withID packageID: String) {
        for (index, carrier) in carrierPackages.enumerated() {
            for group in carrier.packageGroups {
                if group.packages.contains(where: { $0.id == packageID }) {
                    selectedCarriersTabIndex = index
                    selectedCarriersPackageId = packageID
                    return
                }
            }
        }
    }

    // MARK: - Storage

    /// Packages
    ///
    private lazy var packagesResultsController: ResultsController<StorageWooShippingPackagesResponse> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        return ResultsController<StorageWooShippingPackagesResponse>(storageManager: storage, matching: predicate, sortedBy: [])
    }()

    func configureResultsController() {
        packagesResultsController.onDidChangeContent = transformLoadedPackages
        packagesResultsController.onDidResetContent = transformLoadedPackages

        do {
            try packagesResultsController.performFetch()
            transformLoadedPackages()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    // MARK: - loading

    @MainActor
    func loadPackages() async {
        guard !isLoadingPackages else {
            return
        }

        isLoadingPackages = true
        packageLoadingError = nil

        do {
            _ = try await withCheckedThrowingContinuation { continuation in
                let loadPackagesAction = WooShippingAction.loadPackages(siteID: siteID) { result in
                    continuation.resume(with: result)
                }
                stores.dispatch(loadPackagesAction)
            }
            analytics.track(event: .WooShipping.packageSelectionStep(state: .loadingSuccess))
        } catch {
            DDLogError("⛔️ Error loading packages for Woo Shipping labels: \(error)")
            packageLoadingError = error
            analytics.track(event: .WooShipping.packageSelectionStep(state: .loadingFailed, error: error))
        }

        isLoadingPackages = false
    }

    // transform packages
    private func transformLoadedPackages() {
        guard let packages = packagesResultsController.fetchedObjects.first else {
            return
        }
        let customSavedPackages = packages.customPackages.map {
            return $0.toPackageData()
        }.sorted { $0.id < $1.id }
        let predefinedSavedPackages = packages.savedPredefinedPackages.map {
            return $0.toPackageData()
        }.sorted { $0.id < $1.id }
        var carrierPackages: [WooShippingCarrierPackages] = packages.allPredefinedOptions.compactMap {
            return $0.toCarrierPackages()
        }
        if self.carrierPackages.isNotEmpty {
            // sort new packages so they stay in similar order
            // sort only if we already had carrier packages before
            let sortedCarrierPackages = self.carrierPackages.sorted { (carrierA, carrierB) in
                let carrierAIndex = self.carrierPackages.firstIndex(where: { $0.id == carrierA.id })
                let carrierBIndex = self.carrierPackages.firstIndex(where: { $0.id == carrierB.id })
                if let firstI = carrierAIndex, let secondI = carrierBIndex {
                    return firstI < secondI
                }
                else {
                    return carrierAIndex != nil
                }
            }
            carrierPackages = sortedCarrierPackages
        }
        let carrierTabs: [TopTabItem<EmptyView>] = carrierPackages.map { carrierTab in
            return TopTabItem(name: carrierTab.carrier.name, icon: carrierTab.carrier.logo, content: {
                EmptyView()
            })
        }

        self.customSavedPackages = customSavedPackages
        self.predefinedSavedPackages = predefinedSavedPackages
        self.carrierPackages = carrierPackages
        self.carrierTabs = carrierTabs

        self.allPredefinedOptions = packages.allPredefinedOptions

        starredCarriersPackages = Set(predefinedSavedPackages.map { $0.id })

        // Select package type matching the previous selected package, if it is the currently selected package
        if let previousSelectedPackage, previousSelectedPackage.id == selectedSavedPackageId || previousSelectedPackage.id == selectedCarriersPackageId {
            switch previousSelectedPackage.source {
            case .predefined:
                selectedPackageType = predefinedSavedPackages.contains(where: { $0.id == previousSelectedPackage.id }) ? .saved : .carrier
            case .custom:
                selectedPackageType = customSavedPackages.contains(where: { $0.id == previousSelectedPackage.id }) ? .saved : .custom
            }
        }
    }

    // star/unstar packages
    func starUnstarPackage(_ packageID: String, carrierID: String) {
        if starredCarriersPackages.contains(packageID) {
            _ = withAnimation(starAnimation) {
                starredCarriersPackages.remove(packageID)
            }
            let action = WooShippingAction.deletePackage(siteID: siteID,
                                                         packageID: packageID,
                                                         packageType: .predefined,
                                                         completion: { [weak self] result in
                guard let self else { return }
                if case .failure(let error) = result {
                    DDLogError("⛔️ Error saving Woo Shipping package: \(error)")
                    starredCarriersPackages.insert(packageID)
                    notice = Notice(title: Localization.removingPackageFailure,
                                          feedbackType: .error,
                                          actionTitle: Localization.retry,
                                          actionHandler: { [weak self] in
                        self?.starUnstarPackage(packageID, carrierID: carrierID)
                    })
                    analytics.track(event: .WooShipping.packageSelectionStep(state: .removingFailed, error: error))
                } else {
                    analytics.track(event: .WooShipping.packageSelectionStep(state: .removingSuccess))
                }
            })
            stores.dispatch(action)
        }
        else {
            _ = withAnimation(starAnimation) {
                starredCarriersPackages.insert(packageID)
            }

            let predefined = WooShippingPredefinedSavedOption(id: carrierID, predefinedPackageIDs: [packageID])
            let createAction = WooShippingAction.createPackage(siteID: siteID, customPackage: nil, predefinedOption: predefined) { [weak self] result in
                guard let self else { return }
                if case .failure(let error) = result {
                    DDLogError("⛔️ Error saving Woo Shipping package: \(error)")
                    starredCarriersPackages.remove(packageID)
                    notice = Notice(title: Localization.savingPackageFailure,
                                          feedbackType: .error,
                                          actionTitle: Localization.retry,
                                          actionHandler: { [weak self] in
                        self?.starUnstarPackage(packageID, carrierID: carrierID)
                    })
                    analytics.track(event: .WooShipping.packageSelectionStep(state: .savingFailed, error: error))
                } else {
                    analytics.track(event: .WooShipping.packageSelectionStep(state: .savingSuccess))
                }
            }
            stores.dispatch(createAction)
        }
    }

    // delete saved packages
    func removeSavedPackage(_ packageToRemove: WooShippingPackageDataRepresentable) {
        // delete the package locally and on backend

        // delete locally
        let customPackagesIndex = customSavedPackages.firstIndex(where: { $0.id == packageToRemove.id })
        let predefinedPackagesIndex = predefinedSavedPackages.firstIndex(where: { $0.id == packageToRemove.id })

        if let customPackagesIndex {
            customSavedPackages.remove(at: customPackagesIndex)
        }
        if let predefinedPackagesIndex {
            predefinedSavedPackages.remove(at: predefinedPackagesIndex)
        }

        let removedStarredCarrierID = starredCarriersPackages.remove(packageToRemove.id)

        if selectedSavedPackageId == packageToRemove.id {
            selectedSavedPackageId = nil
        }

        // delete on backend
        let deleteAction = WooShippingAction.deletePackage(siteID: siteID,
                                                           packageID: packageToRemove.id,
                                                           packageType: packageToRemove.source.isCustomPackage ? .custom : .predefined) { [weak self] result in
            guard let self else { return }
            if case .failure(let error) = result {
                DDLogError("⛔️ Error removing saved Woo Shipping package: \(error)")

                // undo removing of the package
                // first: undo starring
                if let carrierID = removedStarredCarrierID {
                    starredCarriersPackages.insert(carrierID)
                }
                // second: undo removing from custom saved
                if let customPackagesIndex {
                    customSavedPackages.insert(packageToRemove, at: customPackagesIndex)
                }
                // third: undo removing from predefined saved
                if let predefinedPackagesIndex {
                    predefinedSavedPackages.insert(packageToRemove, at: predefinedPackagesIndex)
                }

                notice = Notice(title: Localization.removingPackageFailure,
                                      feedbackType: .error,
                                      actionTitle: Localization.retry,
                                      actionHandler: { [weak self] in
                    self?.removeSavedPackage(packageToRemove)
                })
                analytics.track(event: .WooShipping.packageSelectionStep(state: .removingFailed, error: error))
            } else {
                analytics.track(event: .WooShipping.packageSelectionStep(state: .removingSuccess))
            }
        }

        stores.dispatch(deleteAction)
    }
}

extension WooShippingAddPackageViewModel {
    enum Localization {
        static let removingPackageFailure = NSLocalizedString(
            "wooShippingAddPackageViewModel.removingPackageFailure",
            value: "Unable to remove package",
            comment: "Message on a notice when removing a package fails in the shipping creation flow"
        )
        static let savingPackageFailure = NSLocalizedString(
            "wooShippingAddPackageViewModel.savingPackageFailure",
            value: "Unable to save package",
            comment: "Message on a notice when saving a package fails in the shipping creation flow"
        )
        static let retry = NSLocalizedString(
            "wooShippingAddPackageViewModel.retry",
            value: "Retry",
            comment: "Button to retry saving/removing a package in the shipping creation flow"
        )
    }
}

extension WooShippingCustomPackage {
    func toPackageData() -> WooShippingPackageData {
        return WooShippingPackageData(id: id,
                                      name: name,
                                      length: String(getLength()),
                                      width: String(getWidth()),
                                      height: String(getHeight()),
                                      weight: String(boxWeight),
                                      source: .custom,
                                      packageType: rawType)
    }
}

extension WooShippingPredefinedPackage {
    func toPackageData(groupTitle: String, sourceID: String) -> WooShippingPackageData {
        return WooShippingPackageData(id: id,
                                      name: name,
                                      length: String(getLength()),
                                      width: String(getWidth()),
                                      height: String(getHeight()),
                                      weight: String(boxWeight),
                                      source: .predefined(sourceTitle: groupTitle, sourceID: sourceID),
                                      packageType: isLetter ? "envelope" : "box")
    }
}

extension WooShippingSavedPredefinedPackage {
    func toPackageData() -> WooShippingPackageData {
        return WooShippingPackageData(id: id,
                                      name: self.package.name,
                                      length: String(self.package.getLength()),
                                      width: String(self.package.getWidth()),
                                      height: String(self.package.getHeight()),
                                      weight: self.package.boxWeight,
                                      source: .predefined(sourceTitle: groupTitle, sourceID: providerID),
                                      packageType: self.package.isLetter ? "envelope" : "box")
    }
}

extension WooShippingCarrierPredefinedOptions {
    func toCarrierPackages() -> WooShippingCarrierPackages? {
        guard let shippingCarrier = WooShippingCarrier(rawValue: carrierID) else { return nil }

        let packageGroups = predefinedOptions.compactMap { predefinedOption in
            let packages = predefinedOption.predefinedPackages.map { package in
                return package.toPackageData(groupTitle: predefinedOption.title, sourceID: predefinedOption.providerID)
            }.sorted { $0.id < $1.id }
            let group = WooPackageGroup(name: predefinedOption.title, packages: packages)
            return group
        }
        let carrierPackages = WooShippingCarrierPackages(carrier: shippingCarrier, packageGroups: packageGroups)
        return carrierPackages
    }
}
