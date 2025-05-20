//
//  ConnectionMonitor.swift
//  Networking
//
//  MIT License
//
//  Copyright (c) 2025 Networking - Yağızhan Akduman
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import Network

// MARK: - ConnectionMonitor

/// A class responsible for monitoring network connectivity status.
///
/// This class utilizes `NWPathMonitor` from Apple's `Network` framework to detect
/// changes in the network state and notify subscribers accordingly. It is useful for
/// handling network-dependent operations in an application, ensuring that requests
/// are only made when the device has an active internet connection.
public class ConnectionMonitor {
    
    /// The `NWPathMonitor` instance used to observe network connectivity status.
    ///
    /// - Note:
    ///   - This monitor listens for changes in network reachability.
    ///   - It provides real-time updates about the **current** network connection state.
    private let monitor: NWPathMonitor
    
    /// A dedicated queue for handling network updates to avoid blocking the main thread.
    ///
    /// - Note:
    ///   - The monitor's callbacks run on this background queue.
    ///   - Ensures that network status updates do not **interfere** with UI operations.
    private let queue = DispatchQueue(label: "networking.connectionMonitor")
    
    /// A Boolean flag indicating whether the network is currently reachable.
    ///
    /// - This value is updated whenever the network state changes.
    /// - It reflects **real-time** network connectivity.
    /// - Accessible via **read-only** (`private(set)`) from outside.
    public private(set) var isReachable: Bool = false
    
    /// A closure that is called whenever network reachability status changes.
    ///
    /// - Parameters:
    ///   - `Bool`: Indicates whether the network is currently reachable (`true`) or not (`false`).
    ///
    /// - Usage:
    ///   - Subscribe to this closure to **react** to connectivity changes.
    ///   - Example:
    ///   ```swift
    ///   connectionMonitor.reachabilityChanged = { isConnected in
    ///       print("Network connectivity changed: \(isConnected ? "Online" : "Offline")")
    ///   }
    ///   ```
    public var reachabilityChanged: ((Bool) -> Void)?
    
    /// Initializes a `ConnectionMonitor` instance and sets up the `NWPathMonitor`.
    ///
    /// - Note:
    ///   - The monitor does **not** start automatically.
    ///   - You must explicitly call `startMonitoring()` to begin listening for changes.
    ///
    /// - Example:
    ///   ```swift
    ///   let connectionMonitor = ConnectionMonitor()
    ///   connectionMonitor.startMonitoring()
    ///   ```
    public init() {
        self.monitor = NWPathMonitor()
        self.startMonitoring()
    }
    
    /// Starts monitoring network connectivity.
    ///
    /// - How it works:
    ///   - Assigns a `pathUpdateHandler` to listen for connectivity changes.
    ///   - Updates the `isReachable` property when the network state changes.
    ///   - Calls the `reachabilityChanged` closure **only if** connectivity status changes.
    ///   - Runs the monitor on a background `DispatchQueue` to avoid UI lag.
    ///
    /// - Example:
    ///   ```swift
    ///   connectionMonitor.startMonitoring()
    ///   ```
    public func startMonitoring() {
        /// Handler is executed whenever the network path changes.
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else {
                return
            }
            /// Determine if the network is **currently reachable**.
            let newStatus = path.status == .satisfied
            /// Notify subscribers **only if** the connectivity status has changed.
            if newStatus != self.isReachable {
                self.isReachable = newStatus
                self.reachabilityChanged?(newStatus)
            }
        }
        /// Start the monitor on the designated queue.
        monitor.start(queue: queue)
    }
    
    /// Stops monitoring network connectivity.
    ///
    /// - After calling this method, `pathUpdateHandler` will **no longer receive updates**.
    /// - This method **should be called** when monitoring is no longer needed.
    ///
    /// - Example:
    ///   ```swift
    ///   connectionMonitor.stopMonitoring()
    ///   ```
    public func stopMonitoring() {
        monitor.cancel()
    }
    
}
