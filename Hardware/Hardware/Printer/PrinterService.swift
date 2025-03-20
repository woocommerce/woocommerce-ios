/// Abstracts the integration with a Receipt Printer
public protocol PrinterService {
    /// Prints a receipt
    /// - Parameter ReceiptContent: the data that needs to be printed in the receipt
    func printReceipt(content: ReceiptContent, completion: @escaping (PrintingResult) -> Void)
    func printReceipt(content: ReceiptContent) async throws
}

import Combine
public protocol DiscoverableHardwareService<Device> {
    associatedtype Device: Identifiable
    func discover() -> AsyncThrowingStream<Device, Error>

    func stopDiscovery()

    func connect(to device: Device) async throws

    func disconnect() async throws

    var statusPublisher: AnyPublisher<DeviceStatus, Never> { get }
}

public enum DeviceStatus {
    case connecting
    case connected
    case busy
    case error(Error)
    case disconnecting
    case disconnected
}

public struct Printer: Identifiable {
    public let id: String
    public let interface: Interface

    public enum Interface {
        case bluetooth
        case bluetoothLE
        case lan
        case usb
    }
}
