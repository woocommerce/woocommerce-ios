/// Models errors thrown by the CardReaderService.
/// This is doing the bare minimum for now.
/// Proper error handling is coming in
/// https://github.com/woocommerce/woocommerce-ios/issues/3734
public enum CardReaderServiceError: Error {
    /// Error thrown during reader discovery
    case discovery

    /// Error thrown while connecting to a reader
    case connection

    /// Error thrown while creating a payment intent
    case intentCreation
}
