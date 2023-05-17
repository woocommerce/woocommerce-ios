import Foundation
import Yosemite

protocol CardReaderSupportDetermining {
    func connectedReader() async -> CardReader?
    func hasPreviousTapToPayUsage() async -> Bool
    func siteSupportsLocalMobileReader() -> Bool
    func deviceSupportsLocalMobileReader() async -> Bool
}

final class CardReaderSupportDeterminer: CardReaderSupportDetermining {
    private let stores: StoresManager
    private let configuration: CardPresentPaymentsConfiguration
    private let siteID: Int64

    init(siteID: Int64,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.configuration = configuration
        self.stores = stores
    }

    @MainActor
    func connectedReader() async -> CardReader? {
        await withCheckedContinuation { continuation in
            let action = CardPresentPaymentAction.publishCardReaderConnections { connectionPublisher in
                _ = connectionPublisher.sink { readers in
                    continuation.resume(returning: readers.first)
                }
            }
            self.stores.dispatch(action)
        }
    }

    @MainActor
    func hasPreviousTapToPayUsage() async -> Bool {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(siteID: siteID,
                                                                                    cardReaderType: .appleBuiltIn) { date in
                continuation.resume(returning: date != nil)
            }

            self.stores.dispatch(action)
        }
    }

    func siteSupportsLocalMobileReader() -> Bool {
        configuration.supportedReaders.contains(.appleBuiltIn)
    }

    @MainActor
    func deviceSupportsLocalMobileReader() async -> Bool {
        await withCheckedContinuation { continuation in
            let action = CardPresentPaymentAction.checkDeviceSupport(siteID: siteID,
                                                                     cardReaderType: .appleBuiltIn,
                                                                     discoveryMethod: .localMobile) { result in
                continuation.resume(returning: result)
            }
            stores.dispatch(action)
        }
    }
}
