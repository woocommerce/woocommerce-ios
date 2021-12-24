import UIKit
import SwiftUI
import Yosemite

/// View model for `ShippingLabelAddNewPackage`.
///
final class ShippingLabelAddNewPackageViewModel: ObservableObject {
    private let stores: StoresManager
    private let siteID: Int64

    /// Index of the selected tab
    ///
    @Published var selectedIndex: Int

    /// View for the selected tab
    ///
    var selectedView: PackageViewType {
        PackageViewType(rawValue: selectedIndex) ?? .customPackage
    }

    // View models for child views (tabs)
    private(set) var customPackageVM = ShippingLabelCustomPackageFormViewModel()
    private(set) var servicePackageVM: ShippingLabelServicePackageListViewModel

    /// Package selected on the Custom Package tab
    ///
    private var validatedCustomPackage: ShippingLabelCustomPackage? {
        customPackageVM.validatedCustomPackage
    }

    /// Package selected on the Service Package tab
    ///
    private var selectedServicePackage: ShippingLabelPredefinedPackage? {
        servicePackageVM.selectedPackage
    }

    /// Package details fetched from the API
    ///
    private var packagesResponse: ShippingLabelPackagesResponse?

    /// Error if package creation fails
    ///
    private(set) var error: PackageCreationError?

    /// Completion callback
    ///
    typealias Completion = (_ customPackage: ShippingLabelCustomPackage? ,
                            _ servicePackage: ShippingLabelPredefinedPackage? ,
                            _ packagesResponse: ShippingLabelPackagesResponse?) -> Void
    let onCompletion: Completion

    init(_ selectedIndex: Int = PackageViewType.customPackage.rawValue,
         stores: StoresManager = ServiceLocator.stores,
         siteID: Int64,
         packagesResponse: ShippingLabelPackagesResponse?,
         onCompletion: @escaping Completion) {
        self.selectedIndex = selectedIndex
        self.stores = stores
        self.siteID = siteID
        self.servicePackageVM = ShippingLabelServicePackageListViewModel(packagesResponse: packagesResponse)
        self.packagesResponse = packagesResponse
        self.onCompletion = onCompletion
    }

    enum PackageViewType: Int {
        case customPackage = 0
        case servicePackage = 1
    }
}

// MARK: - Helper methods
extension ShippingLabelAddNewPackageViewModel {

    /// Creates the custom package remotely and updates the package details to select the new package
    ///
    func createCustomPackage(onCompletion: @escaping (Bool) -> Void) {
        guard let newCustomPackage = validatedCustomPackage else {
            onCompletion(false)
            return
        }

        createPackage(customPackage: newCustomPackage) { [weak self] success in
            onCompletion(success)

            // On success, reset tab state and save new package details
            guard let self = self, success else { return }
            self.customPackageVM = ShippingLabelCustomPackageFormViewModel()
            self.onCompletion(newCustomPackage, nil, self.packagesResponse)
        }
    }

    /// Activates the selected service package remotely and updates the package details to select the new package
    ///
    func activateServicePackage(onCompletion: @escaping (Bool) -> Void) {
        guard let selectedServicePackage = selectedServicePackage,
              let shippingProvider = servicePackageVM.predefinedOptions.first(where: { $0.predefinedPackages.contains(selectedServicePackage) } ) else {
            onCompletion(false)
            return
        }

        let selectedOption = ShippingLabelPredefinedOption(title: shippingProvider.title,
                                                           providerID: shippingProvider.providerID,
                                                           predefinedPackages: [selectedServicePackage])

        createPackage(predefinedOption: selectedOption) { [weak self] success in
            onCompletion(success)

            // On success, reset tab state and save new package details
            guard let self = self, success else { return }
            self.customPackageVM = ShippingLabelCustomPackageFormViewModel()
            self.servicePackageVM = ShippingLabelServicePackageListViewModel(packagesResponse: self.packagesResponse)
            self.onCompletion(nil, selectedServicePackage, self.packagesResponse)
        }
    }
}

// MARK: - API Requests
private extension ShippingLabelAddNewPackageViewModel {

    /// Creates a custom package or activates a predefined option remotely and (if successful) syncs the package details.
    /// On completion, indicates if the API calls were successful.
    ///
    func createPackage(customPackage: ShippingLabelCustomPackage? = nil,
                       predefinedOption: ShippingLabelPredefinedOption? = nil,
                       onCompletion: ((Bool) -> Void)? = nil) {
        guard customPackage != nil || predefinedOption != nil else {
            onCompletion?(false)
            return
        }

        let action = ShippingLabelAction.createPackage(siteID: siteID,
                                                       customPackage: customPackage,
                                                       predefinedOption: predefinedOption) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                if customPackage != nil {
                    ServiceLocator.analytics.track(.shippingLabelPackageAddedSuccessfully, withProperties: ["type": "custom"])
                }
                if predefinedOption != nil {
                    ServiceLocator.analytics.track(.shippingLabelPackageAddedSuccessfully, withProperties: ["type": "predefined"])
                }
                self.syncPackageDetails() { success in
                    onCompletion?(success)
                }
            case .failure(let error):
                self.error = error
                if customPackage != nil {
                    ServiceLocator.analytics.track(.shippingLabelAddPackageFailed, withProperties: ["type": "custom",
                                                                                                    "error": error.localizedDescription])
                }
                if predefinedOption != nil {
                    ServiceLocator.analytics.track(.shippingLabelAddPackageFailed, withProperties: ["type": "predefined",
                                                                                                    "error": error.localizedDescription])
                }
                DDLogError("⛔️ Error creating package: \(error.localizedDescription)")
                onCompletion?(false)
            }
        }
        stores.dispatch(action)
    }

    /// Gets updated package list with new package. On completion, indicates if sync was successful.
    ///
    func syncPackageDetails(onCompletion: ((Bool) -> Void)? = nil) {
        let action = ShippingLabelAction.packagesDetails(siteID: siteID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let value):
                self.packagesResponse = value
                onCompletion?(true)
            case .failure:
                DDLogError("⛔️ Error synchronizing package details")
                onCompletion?(false)
            }
        }
        stores.dispatch(action)
    }
}
