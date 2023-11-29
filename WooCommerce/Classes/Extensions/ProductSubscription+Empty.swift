import Foundation
import struct Yosemite.ProductSubscription

extension ProductSubscription {

    /// Default empty product subscription for product creation.
    static let empty: Self = {
        .init(length: "0",
              period: .month,
              periodInterval: "1",
              price: "",
              signUpFee: "",
              trialLength: "",
              trialPeriod: .day,
              oneTimeShipping: false,
              paymentSyncDate: "",
              paymentSyncMonth: "")
    }()
}
