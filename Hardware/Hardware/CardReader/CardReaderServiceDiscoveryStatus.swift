/// Models the discovery status of a Card Reader Service
public enum CardReaderServiceDiscoveryStatus {
    // The service is idle
    case idle

    // The service is attempting to discover readers
    case discovering

    // The servide is at fault
    case fault
}
