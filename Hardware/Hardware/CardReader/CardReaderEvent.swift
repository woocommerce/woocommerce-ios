/// The possible events from a connected reader.
public enum CardReaderEvent {
    // A card was inserted.
    case cardInserted

    // A card was removed.
    case cardRemoved

    // Low battery warning.
    case lowBattery

    // Low battery warning resolved.
    case lowBatteryResolved

    // A software update is available.
    case softwareUpdateNeeded

    // Software is up to dat.
    case softwareUpToDate

    // The card reader disconnected.
    case disconnected
}
