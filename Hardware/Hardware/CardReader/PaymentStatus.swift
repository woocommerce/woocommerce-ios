/// The possible payment statuses
public enum PaymentStatus {
    /// The service is not ready to start a payment.
    /// It might be busy with another command or a reader might not be connected
    case notReady

    /// The service is ready to start a payment
    case ready

    /// The service is waiting for input from the customer
    /// e.g, waiting for a card to be presented
    case waitingForInput

    /// The service is processing a payment
    case processing
}
