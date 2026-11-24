@testable import PointOfSale

extension POSLocalPINStore {
    func setPIN(_ pin: String, for role: POSLocalRole) throws(POSPINStoreError) {
        try preparePIN(pin, for: role)()
    }
}
