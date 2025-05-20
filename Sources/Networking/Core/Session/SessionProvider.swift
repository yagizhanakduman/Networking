//
//  SessionProvider.swift
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
import Security

// MARK: - Session Provider

/// Manages user sessions securely using Apple's **Keychain Services**.
///
/// - Features:
///   - **Uses Keychain for secure storage** instead of `UserDefaults`.
///   - **Prevents unauthorized access** to sensitive session data.
///   - **Handles access token expiration automatically**.
///   - **Thread-safe** with `DispatchQueue`.
///
/// - Methods:
///   - `setSession(_:)` → Stores a session securely.
///   - `getSession(for:)` → Retrieves a session securely (if not expired).
///   - `removeSession(for:)` → Deletes a session from Keychain.
///   - `clearAll()` → Clears all stored sessions.
///
/// - Example:
///   ```swift
///   let sessionProvider = SecureSessionProvider()
///   let session = Session(userID: "12345", accessToken: "secureAccessToken", expiration: Date().addingTimeInterval(3600))
///   sessionProvider.setSession(session)
///
///   if let retrievedSession = sessionProvider.getSession(for: "12345") {
///       print("Active session: \(retrievedSession.userID)")
///   }
///   ```
public class SessionProvider {
    
    /// A `DispatchQueue` used to synchronize access to session storage.
    private let queue = DispatchQueue(label: "networking.secureSessionProvider.lock", attributes: .concurrent)
    
    /// **Stores a session securely in the Keychain.**
    ///
    /// - Parameter session: The `Session` object to store.
    public func setSession(_ session: Session) {
        queue.async(flags: .barrier) {
            guard let encodedData = try? JSONEncoder().encode(session) else {
                return
            }
            let query: [String: Any] = [
                kSecClass as String       : kSecClassGenericPassword,
                kSecAttrAccount as String : session.userID,
                kSecValueData as String   : encodedData,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            /// **Delete existing session first to prevent duplicates.**
            SecItemDelete(query as CFDictionary)
            /// **Add new session securely.**
            SecItemAdd(query as CFDictionary, nil)
        }
    }
    
    /// **Retrieves a session securely from the Keychain.**
    ///
    /// - Parameter userID: The user identifier for which to retrieve the session.
    /// - Returns: The `Session` object if found and **not expired**, otherwise `nil`.
    public func getSession(for userID: String) -> Session? {
        queue.sync {
            let query: [String: Any] = [
                kSecClass as String       : kSecClassGenericPassword,
                kSecAttrAccount as String : userID,
                kSecReturnData as String  : true,
                kSecMatchLimit as String  : kSecMatchLimitOne
            ]
            var retrievedData: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &retrievedData)
            guard
                status == errSecSuccess,
                let data = retrievedData as? Data,
                let session = try? JSONDecoder().decode(Session.self, from: data),
                !session.isExpired
            else {
                removeSession(for: userID) // Auto-remove expired session
                return nil
            }
            return session
        }
    }
    
    /// **Removes a session securely from the Keychain.**
    ///
    /// - Parameter userID: The user identifier for which to remove the session.
    public func removeSession(for userID: String) {
        queue.async(flags: .barrier) {
            let query: [String: Any] = [
                kSecClass as String       : kSecClassGenericPassword,
                kSecAttrAccount as String : userID
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
    
    /// **Clears all stored sessions securely.**
    public func clearAll() {
        queue.async(flags: .barrier) {
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
            SecItemDelete(query as CFDictionary)
        }
    }
    
}
