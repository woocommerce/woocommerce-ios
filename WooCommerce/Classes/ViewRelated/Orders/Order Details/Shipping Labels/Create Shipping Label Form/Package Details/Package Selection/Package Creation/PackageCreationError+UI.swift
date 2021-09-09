import Yosemite

extension PackageCreationError {
    var alertTitle: String {
        switch self {
        case .duplicatePackageNames, .duplicateNamesByCarrier, .duplicateCustomPackageNames, .duplicatePredefinedPackageNames:
            return NSLocalizedString("Invalid Package Name",
                                     comment: "The title of the alert when there is an error with the package name")
        case .unknown:
            return NSLocalizedString("Cannot add package",
                                     comment: "The title of the alert when there is a generic error adding the package")
        }
    }
}

extension PackageCreationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .duplicatePackageNames, .duplicateCustomPackageNames:
            return NSLocalizedString("The new custom package name is not unique.",
                                     comment: "The message of the alert when another custom package has the same name")
        case .duplicateNamesByCarrier, .duplicatePredefinedPackageNames:
            return NSLocalizedString("The new service package name is not unique.",
                                     comment: "The message of the alert when another service package has the same name")
        case .unknown:
            return NSLocalizedString("Unexpected error", comment: "The message of the alert when there is an unexpected error adding the package")
        }
    }
}
