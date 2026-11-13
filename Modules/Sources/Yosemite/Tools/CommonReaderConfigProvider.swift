import Foundation
import Hardware
import Networking
import protocol WooFoundation.Analytics
import struct WooFoundationCore.WooAnalyticsEvent

public protocol CardReaderRemoteConfigLoading {
    func setContext(siteID: Int64, remote: CardReaderCapableRemote)
    func resetContext()
}

public protocol CommonReaderConfigProviding: CardReaderRemoteConfigLoading, CardReaderConfigProvider {}


public final class CommonReaderConfigProvider: CommonReaderConfigProviding {
    var siteID: Int64?
    var readerConfigRemote: CardReaderCapableRemote?
    private let analytics: Analytics?

    public init(siteID: Int64? = nil,
                readerConfigRemote: CardReaderCapableRemote? = nil,
                analytics: Analytics? = nil) {
        self.siteID = siteID
        self.readerConfigRemote = readerConfigRemote
        self.analytics = analytics
    }

    public func setContext(siteID: Int64, remote: CardReaderCapableRemote) {
        self.siteID = siteID
        self.readerConfigRemote = remote
    }

    public func resetContext() {
        self.siteID = nil
        self.readerConfigRemote = nil
    }

    public func fetchToken(completion: @escaping(Result<String, Error>) -> Void) {
        guard let siteID = self.siteID else {
            return
        }

        readerConfigRemote?.loadConnectionToken(for: siteID) { result in
            switch result {
            case .success(let token):
                completion(.success(token.token))
            case .failure(let error):
                if let configError = CardReaderConfigError(error: error) {
                    completion(.failure(configError))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    public func fetchDefaultLocationID(completion: @escaping(Result<String, Error>) -> Void) {
        guard let siteID = self.siteID else {
            return
        }

        let analytics = self.analytics
        readerConfigRemote?.loadDefaultReaderLocation(for: siteID) { result in
            switch result {
            case .success(let location):
                let readerLocation = location.toReaderLocation(siteID: siteID)
                analytics?.track(WooAnalyticsEvent.InPersonPaymentsLocation.cardReaderLocationSuccess(siteID: siteID))
                completion(.success(readerLocation.id))
            case .failure(let error):
                let configError = CardReaderConfigError(error: error)
                analytics?.track(WooAnalyticsEvent.InPersonPaymentsLocation
                    .cardReaderLocationFailure(siteID: siteID, reason: configError.locationFailureReason))
                if let configError {
                    completion(.failure(configError))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
}

private extension Analytics {
    /// Convenience for tracking a strongly-typed `WooAnalyticsEvent` from the data layer,
    /// where the app target's `track(event:)` convenience is not available.
    func track(_ event: WooAnalyticsEvent) {
        track(event.statName.rawValue, properties: event.properties, error: event.error)
    }
}

private extension Optional where Wrapped == CardReaderConfigError {
    /// Maps a resolved `CardReaderConfigError` (or its absence) to an analytics failure reason.
    var locationFailureReason: WooAnalyticsEvent.InPersonPaymentsLocation.FailureReason {
        switch self {
        case .incompleteStoreAddress?:
            return .incompleteStoreAddress
        case .invalidPostalCode?:
            return .invalidPostalCode
        case .none:
            return .other
        }
    }
}

private extension CardReaderConfigError {
    init?(error: Error) {
        switch error {
        case DotcomError.unknown(code: "store_address_is_incomplete", let message, _):
            self = .incompleteStoreAddress(adminUrl: URL(string: message ?? ""))
        case DotcomError.unknown(code: "postal_code_invalid", _, _):
            self = .invalidPostalCode
        case NetworkError.unacceptableStatusCode(_, let responseData):
            guard let responseData,
                  let details = try? JSONDecoder().decode(CardReaderConfigNetworkErrorDetails.self, from: responseData) else {
                return nil
            }
            switch details.code {
            case .storeAddressIncomplete:
                self = .incompleteStoreAddress(adminUrl: URL(string: details.message ?? ""))
            case .postalCodeInvalid:
                self = .invalidPostalCode
            }
        default:
            return nil
        }
    }
}

private struct CardReaderConfigNetworkErrorDetails: Decodable {
    let code: ErrorCode
    let message: String?

    enum CodingKeys: CodingKey {
        case code
        case message
    }

    enum ErrorCode: String, Decodable {
        case storeAddressIncomplete = "store_address_is_incomplete"
        case postalCodeInvalid = "postal_code_invalid"
    }
}
