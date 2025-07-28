import Foundation

public struct CardReaderInput: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = CardReaderInput([])
    public static let swipe = CardReaderInput(rawValue: 1 << 0)
    public static let insert = CardReaderInput(rawValue: 1 << 1)
    public static let tap = CardReaderInput(rawValue: 1 << 2)
}


#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension CardReaderInput {
    init(stripeReaderInputOptions: ReaderInputOptions) {
        let value = Int(stripeReaderInputOptions.rawValue)
        self.init(rawValue: value)
    }
}
#endif
