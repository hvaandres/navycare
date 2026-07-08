// NetworkMonitor.swift
// navycare — Core
//
// Lightweight NWPathMonitor wrapper.
// The SyncEngine observes `isConnected` before dispatching Firestore writes.

import Foundation
import Network
import Observation

@Observable
final class NetworkMonitor: @unchecked Sendable {

    private(set) var isConnected: Bool = true
    private(set) var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "com.navycare.network", qos: .utility)

    enum ConnectionType: String {
        case wifi, cellular, ethernet, unknown
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected     = path.status == .satisfied
                self?.connectionType  = Self.connectionType(from: path)
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }

    private static func connectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi)      { return .wifi      }
        if path.usesInterfaceType(.cellular)  { return .cellular  }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        return .unknown
    }
}
