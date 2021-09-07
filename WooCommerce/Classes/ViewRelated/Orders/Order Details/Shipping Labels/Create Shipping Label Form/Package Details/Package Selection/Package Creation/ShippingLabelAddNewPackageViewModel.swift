import UIKit
import SwiftUI
import Yosemite

/// View model for `ShippingLabelAddNewPackage`.
///
final class ShippingLabelAddNewPackageViewModel: ObservableObject {
    private let stores: StoresManager
    private let siteID: Int64

    @Published var selectedIndex: Int
    var selectedView: PackageViewType {
        PackageViewType(rawValue: selectedIndex) ?? .customPackage
    }

    // View models for child views (tabs)
    var customPackageVM = ShippingLabelCustomPackageFormViewModel()
    lazy var servicePackageVM = ShippingLabelServicePackageListViewModel(packagesResponse: packagesResponse)

    private var validatedCustomPackage: ShippingLabelCustomPackage? {
        customPackageVM.validatedCustomPackage
    }
    private var selectedServicePackage: ShippingLabelPredefinedPackage? {
        servicePackageVM.selectedPackage
    }
    private var packagesResponse: ShippingLabelPackagesResponse?

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
            guard success else { return }
            self?.customPackageVM = ShippingLabelCustomPackageFormViewModel()
            self?.onCompletion(newCustomPackage, nil, self?.packagesResponse)
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
            guard success else { return }
            self?.customPackageVM = ShippingLabelCustomPackageFormViewModel()
            self?.servicePackageVM.packagesResponse = self?.packagesResponse
            self?.onCompletion(nil, selectedServicePackage, self?.packagesResponse)
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
                                                       predefinedOption: predefinedOption) { result in
            switch result {
            case .success(_):
                self.syncPackageDetails() { success in
                    onCompletion?(success)
                }
            case .failure(let error):
                DDLogError("⛔️ Error creating package: \(error.localizedDescription)")
                onCompletion?(false)
            }
        }
        stores.dispatch(action)
    }

    /// Gets updated package list with new package. On completion, indicates if sync was successful.
    ///
    func syncPackageDetails(onCompletion: ((Bool) -> Void)? = nil) {
        let action = ShippingLabelAction.packagesDetails(siteID: siteID) { result in
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
