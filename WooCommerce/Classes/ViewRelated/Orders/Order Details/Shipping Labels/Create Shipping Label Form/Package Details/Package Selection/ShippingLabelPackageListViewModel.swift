import Foundation
import Yosemite

protocol ShippingLabelPackageSelectionDelegate: AnyObject {
    func didSelectPackage(id: String)
    func didSyncPackages(packagesResponse: ShippingLabelPackagesResponse?)
}

/// View model for `ShippingLabelPackageList` and `ShippingLabelPackageSelection`.
///
final class ShippingLabelPackageListViewModel: ObservableObject {
    @Published private(set) var selectedCustomPackage: ShippingLabelCustomPackage?
    @Published private(set) var selectedPredefinedPackage: ShippingLabelPredefinedPackage?

    var dimensionUnit: String {
        return packagesResponse?.storeOptions.dimensionUnit ?? ""
    }
    var customPackages: [ShippingLabelCustomPackage] {
        return packagesResponse?.customPackages ?? []
    }
    var predefinedOptions: [ShippingLabelPredefinedOption] {
        return packagesResponse?.predefinedOptions ?? []
    }

    /// Returns if the custom packages header should be shown in Package List
    ///
    var showCustomPackagesHeader: Bool {
        return customPackages.count > 0
    }

    /// Whether there are saved custom or predefined packages to select from.
    ///
    var hasCustomOrPredefinedPackages: Bool {
        return customPackages.isNotEmpty || predefinedOptions.isNotEmpty
    }

    lazy var addNewPackageViewModel = ShippingLabelAddNewPackageViewModel(siteID: siteID,
                                                                          packagesResponse: packagesResponse,
                                                                          onCompletion: { [weak self] (customPackage, predefinedOption, packagesResponse) in
                                                                            guard let self = self else { return }
                                                                            self.handleNewPackage(customPackage, predefinedOption, packagesResponse)
                                                                          })

    weak var delegate: ShippingLabelPackageSelectionDelegate?

    /// The packages  response fetched from API
    ///
    private var packagesResponse: ShippingLabelPackagesResponse?

    private let siteID: Int64

    init(siteID: Int64, packagesResponse: ShippingLabelPackagesResponse?) {
        self.siteID = siteID
        self.packagesResponse = packagesResponse
    }
}

// MARK: - Package Selection
extension ShippingLabelPackageListViewModel {
    func didSelectPackage(_ id: String) {
        selectCustomPackage(id)
        selectPredefinedPackage(id)
    }

    func confirmPackageSelection() {
        let newPackageID: String? = {
            if let selectedCustomPackage = selectedCustomPackage {
                return selectedCustomPackage.title
            } else if let selectedPredefinedPackage = selectedPredefinedPackage {
                return selectedPredefinedPackage.id
            }
            return nil
        }()
        guard let newPackageID = newPackageID else {
            return
        }
        delegate?.didSelectPackage(id: newPackageID)
    }

    private func selectCustomPackage(_ id: String) {
        guard let packagesResponse = packagesResponse else {
            return
        }

        for customPackage in packagesResponse.customPackages {
            if customPackage.title == id {
                selectedCustomPackage = customPackage
                selectedPredefinedPackage = nil
                return
            }
        }
    }

    private func selectPredefinedPackage(_ id: String) {
        guard let packagesResponse = packagesResponse else {
            return
        }

        for option in packagesResponse.predefinedOptions {
            for predefinedPackage in option.predefinedPackages {
                if predefinedPackage.id == id {
                    selectedCustomPackage = nil
                    selectedPredefinedPackage = predefinedPackage
                    return
                }
            }
        }
    }

    /// Selects a newly created custom package or newly activated service package and adds it to the package list
    ///
    private func handleNewPackage(_ customPackage: ShippingLabelCustomPackage?,
                          _ servicePackage: ShippingLabelPredefinedPackage?,
                          _ packagesResponse: ShippingLabelPackagesResponse?) {
        guard let packagesResponse = packagesResponse else {
            return
        }
        let shouldNotifyDelegate = !hasCustomOrPredefinedPackages
        self.packagesResponse = packagesResponse
        delegate?.didSyncPackages(packagesResponse: packagesResponse)

        addNewPackageViewModel = .init(siteID: siteID,
                                       packagesResponse: packagesResponse,
                                       onCompletion: { [weak self] (customPackage, predefinedOption, packagesResponse) in
                                         guard let self = self else { return }
                                         self.handleNewPackage(customPackage, predefinedOption, packagesResponse)
                                       })

        if let customPackage = customPackage {
            selectCustomPackage(customPackage.title)
            if shouldNotifyDelegate {
                delegate?.didSelectPackage(id: customPackage.title)
            }
        } else if let servicePackage = servicePackage {
            selectPredefinedPackage(servicePackage.id)
            if shouldNotifyDelegate {
                delegate?.didSelectPackage(id: servicePackage.id)
            }
        }
    }
}
