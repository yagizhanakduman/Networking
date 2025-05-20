//
//  LogPrivacy.swift
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

// MARK: - Log Privacy

/// Defines privacy levels for logging network requests and responses.
///
/// `LogPrivacy` determines how sensitive data is handled in logs.
/// This is useful for controlling the visibility of logged data,
/// especially in debugging, analytics, or security-sensitive applications.
///
/// - Cases:
///   - `public`: Logs are fully visible and can be printed without restrictions.
///   - `private`: Logs contain **private** information and should be **masked or redacted**.
///   - `sensitive`: Logs contain **highly confidential -  sensitive** data (e.g., authentication tokens, user credentials).
///   - `auto`: The privacy level is **automatically determined** based on the logging system.
public enum LogPrivacy {
    
    /// Logs are fully visible and can be printed without restrictions.
    ///
    /// - **Use Case:** Debugging requests and responses when data sensitivity is not a concern.
    case `public`
    
    /// Logs contain **sensitive** information and should be **masked or redacted**.
    ///
    /// - **Use Case:** Logging data that may contain **user information**, but should be **partially obfuscated**.
    /// - **Example:** Masking user email (`john.doe@example.com → j***@example.com`).
    case `private`
    
    /// Logs contain **highly confidential** data (e.g., authentication tokens, user credentials).
    ///
    /// - **Use Case:** Logging **must be avoided** or highly restricted due to security policies.
    /// - **Example:** API Keys, OAuth Tokens, Banking Details.
    case sensitive
    
    /// The privacy level is **automatically determined** based on the logging system.
    ///
    /// - **Use Case:** Dynamic privacy rules, where privacy settings may change depending on app configuration.
    /// - **Example:** System-managed logging frameworks like **OSLog** may decide whether to redact certain fields.
    case auto
}
