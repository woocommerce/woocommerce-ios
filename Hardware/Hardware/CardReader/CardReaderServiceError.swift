/// Models errors thrown by the CardReaderService.
/// This is doing the bare minimum for now.
/// Proper error handling is coming in
/// https://github.com/woocommerce/woocommerce-ios/issues/3734
public enum CardReaderServiceError: Error {
    case discovery
    case connection
    case intentCreation
}
