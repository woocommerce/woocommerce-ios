import Foundation
import Hardware
import Networking

public protocol CardReaderRemoteConfigLoading {
    func setContext(siteID: Int64, remote: CardReaderCapableRemote)
}

public protocol CommonReaderConfigProviding: CardReaderRemoteConfigLoading & CardReaderConfigProvider {}


final public class CommonReaderConfigProvider: CommonReaderConfigProviding {
    var siteID: Int64?
    var readerConfigRemote: CardReaderCapableRemote?

    public init(siteID: Int64? = nil, readerConfigRemote: CardReaderCapableRemote? = nil) {
        self.siteID = siteID
        self.readerConfigRemote = readerConfigRemote
    }

    public func setContext(siteID: Int64, remote: CardReaderCapableRemote) {
        self.siteID = siteID
        self.readerConfigRemote = remote
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

        readerConfigRemote?.loadDefaultReaderLocation(for: siteID) { result in
            switch result {
            case .success(let location):
                let readerLocation = location.toReaderLocation(siteID: siteID)
                completion(.success(readerLocation.id))
            case .failure(let error):
                if let configError = CardReaderConfigError(error: error) {
                    completion(.failure(configError))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
}

private extension CardReaderConfigError {
    init?(error: Error) {
        switch error {
        case let networkError as NetworkError:
            guard let code = networkError.apiErrorCode else {
                return nil
            }
            switch code {
            case "store_address_is_incomplete":
                self = .incompleteStoreAddress(adminUrl: URL(string: networkError.apiErrorMessage ?? ""))
            case "postal_code_invalid":
                self = .invalidPostalCode
            default:
                return nil
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
