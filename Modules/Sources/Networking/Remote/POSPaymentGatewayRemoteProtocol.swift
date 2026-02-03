import Foundation

public protocol POSPaymentGatewayRemoteProtocol {
    func loadAllPaymentGateways(siteID: Int64, completion: @escaping (Result<[PaymentGateway], Error>) -> Void)
}
