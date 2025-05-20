//
//  Session.swift
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

// MARK: - Session

/// Represents a user session containing authentication tokens and expiration details.
///
/// This struct holds session-related information, including the user's identifier,
/// access token, optional refresh token, and expiration date.
///
/// - Properties:
///   - `userID`: The unique identifier of the user associated with this session.
///   - `accessToken`: The access token used for authentication.
///   - `refreshToken`: An optional refresh token for obtaining a new access token.
///   - `expiration`: An optional expiration date for the access token.
///
/// - Computed Properties:
///   - `isExpired`: Checks if the session's access token is expired.
///   - `shouldRefresh`: Determines if the session should attempt to refresh the token.
///
/// - Example:
///   ```swift
///   let session = Session(
///       userID: "12345",
///       accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
///       refreshToken: "xyz-refresh-token",
///       expiration: Date().addingTimeInterval(3600) // Expires in 1 hour
///   )
///
///   if session.isExpired {
///       print("Session has expired. Attempting refresh...")
///   }
///   ```
public struct Session: Codable {
    /// The unique identifier of the user associated with this session.
    public let userID: String
    
    /// The access token used for authentication.
    public var accessToken: String
    
    /// An optional refresh token for obtaining a new access token.
    public var refreshToken: String?
    
    /// An optional expiration date for the access token.
    public var expiration: Date?
    
    /// Initializes a new session instance.
    ///
    /// - Parameters:
    ///   - userID: The user's unique identifier.
    ///   - accessToken: The authentication access token.
    ///   - refreshToken: An optional refresh token for renewing the access token.
    ///   - expiration: An optional expiration date for the access token.
    public init(userID: String, accessToken: String, refreshToken: String? = nil, expiration: Date? = nil) {
        self.userID = userID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
    }
    
    /// Checks whether the session's access token has expired.
    ///
    /// - Returns: `true` if the token is expired or `expiration` is `nil`, otherwise `false`.
    ///
    /// - Note:
    ///   - If `expiration` is `nil`, this function assumes the session **does not expire**.
    ///   - Expiration is checked against the **current system time**.
    public var isExpired: Bool {
        guard let expiration = expiration else { return false }
        return Date() >= expiration
    }

    /// Determines if the session should attempt to refresh the access token.
    ///
    /// - Returns: `true` if the session is **close to expiring** and has a `refreshToken`, otherwise `false`.
    ///
    /// - Note:
    ///   - A refresh is recommended if **less than 5 minutes** remain before expiration.
    public var shouldRefresh: Bool {
        guard let expiration = expiration, let _ = refreshToken else { return false }
        return Date().addingTimeInterval(300) >= expiration // 5-minute threshold
    }
    
}
