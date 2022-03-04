import SwiftUI

/// Adds a currency symbol to the left or right of the provided content
///
struct CurrencySymbol: ViewModifier {
    let symbol: String
    let position: CurrencySettings.CurrencyPosition
    let symbolSpacing: CGFloat?

    init(symbol: String, position: CurrencySettings.CurrencyPosition) {
        self.symbol = symbol
        self.position = position
        self.symbolSpacing = {
            switch position {
            case .left, .right:
                return .zero
            case .leftSpace, .rightSpace:
                return nil
            }
        }()
    }

    func body(content: Content) -> some View {
        HStack(spacing: symbolSpacing) {
            switch position {
            case .left, .leftSpace:
                Text(symbol)
                    .bodyStyle()
                content
            case .right, .rightSpace:
                content
                Text(symbol)
                    .bodyStyle()
            }
        }
    }
}

extension View {
    /// Adds the provided symbol to the left or right of the text field
    /// - Parameters:
    ///   - symbol: Currency symbol
    ///   - position: Position for the currency symbol, in relation to the text field
    func addingCurrencySymbol(_ symbol: String, on position: CurrencySettings.CurrencyPosition) -> some View {
        modifier(CurrencySymbol(symbol: symbol, position: position))
    }
}
