//
//  PinningURLSessionDelegate.swift
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

// MARK: - PinningURLSessionDelegate

/// A delegate for `URLSession` that performs **SSL certificate pinning** to improve security by ensuring
/// the server's SSL certificate matches one of the certificates bundled with the application.
///
/// - What is Certificate Pinning?
///   - It helps prevent **man-in-the-middle (MITM) attacks** by rejecting any server
///     certificates that **do not exactly match** the pinned data.
///   - This ensures that even if a hacker compromises a certificate authority (CA),
///     the app will **only trust pre-specified certificates**.
///
/// - How It Works:
///   - Stores **pinned certificates** inside the app bundle.
///   - When a server presents an SSL certificate, compares it **byte-for-byte** with the pinned one.
///   - If the certificates **do not match**, the connection is **rejected**.
///
/// - Important:
///   - The app **must include** `.cer` files (DER-encoded) inside the bundle.
///   - If the certificate changes (e.g., renewal, CA switch), the app **must be updated** with the new pinned certificate.
///
/// - Example Usage:
///   ```swift
///   let delegate = PinningURLSessionDelegate(pinnedCertificateNamesByHost: [
///       "api.example.com": ["example_certificate"]
///   ])
///   let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
///   ```
public class PinningURLSessionDelegate: NSObject {
    
    /// Maps a hostname (e.g., `"api.example.com"`) to an array of DER-encoded pinned certificate data.
    ///
    /// - Key: Hostname string.
    /// - Value: Array of `Data` representing `.cer` certificates.
    private let pinnedCertificatesByHost: [String: [Data]]
    
    /// Delegate responsible for handling upload-related task and data callbacks.
    ///
    /// - Used for forwarding `URLSessionTaskDelegate` and `URLSessionDataDelegate` events.
    weak var uploadDelegate: (URLSessionTaskDelegate & URLSessionDataDelegate)?
    
    /// Delegate responsible for handling download-related events.
    ///
    /// - Used for forwarding `URLSessionDownloadDelegate` events from download sessions.
    weak var downloadDelegate: URLSessionDownloadDelegate?
    
    /// Initializes a new `PinningURLSessionDelegate` using the provided dictionary of hostnames and their
    /// corresponding certificate file names (without the `.cer` extension).
    ///
    /// This initializer will load each `.cer` file from the main bundle and store its contents as `Data`.
    ///
    /// - Parameter pinnedCertificateNamesByHost: A dictionary where each key is a hostname (like "api.example.com")
    ///   and each value is an array of `.cer` file names (strings) corresponding to pinned certificates.
    ///
    /// - Returns: An optional `PinningURLSessionDelegate`. If any certificate specified cannot be located
    ///   or loaded from the app bundle, this initializer returns `nil`.
    ///
    /// - Important: Make sure to include the `.cer` files in your application's bundle so they can be accessed
    ///   by this delegate. If the file is missing or has a different filename, the initialization will fail.
    public init?(pinnedCertificateNamesByHost: [String: [String]] = [:]) {
        var tempMap: [String: [Data]] = [:]
        /// Loop through the dictionary to build a map from hostname to an array of certificate data.
        for (host, cerNames) in pinnedCertificateNamesByHost {
            var pinnedDatas: [Data] = []
            /// For each hostname, gather all the `.cer` files specified by their base names.
            for cerName in cerNames {
                /// Attempt to find the `.cer` file in the app bundle and load its contents as Data.
                guard
                    let url = Bundle.main.url(forResource: cerName, withExtension: "cer"),
                    let data = try? Data(contentsOf: url)
                else {
                    /// If we fail to load any certificate for a particular host, return nil and abort initialization.
                    return nil
                }
                /// Append the successfully loaded certificate data to the array for this host.
                pinnedDatas.append(data)
            }
            /// After loading all certificates for a given host, store them in our local map.
            tempMap[host] = pinnedDatas
        }
        /// Assign the final map of host -> array of certificate data.
        self.pinnedCertificatesByHost = tempMap
        /// Call the superclass initializer.
        super.init()
    }
    
}

// MARK: - URLSessionDelegate
extension PinningURLSessionDelegate: URLSessionDelegate {
    
    /// Handles **SSL authentication challenges** during the `URLSession` connection process.
    ///
    /// This method verifies the **server's SSL certificate** by checking if it matches one of the **pinned certificates**.
    ///
    /// This delegate method is called when the session receives an authentication challenge. Typically, this occurs
    /// during the SSL/TLS handshake for secure connections. We use this method to check whether the server's certificate
    /// matches our pinned certificate data.
    ///
    /// - Parameters:
    ///   - session: The `URLSession` that received the authentication challenge.
    ///   - challenge: The `URLAuthenticationChallenge` containing details of the **server's SSL identity**.
    ///   - completionHandler: A closure to **accept** or **reject** the server's certificate.
    ///
    /// - Behavior:
    ///   - If the server certificate **matches** a pinned certificate → ✅ **Connection is allowed**.
    ///   - If the server certificate **does not match** any pinned certificate → ❌ **Connection is rejected**.
    ///
    /// - Important:
    ///   - If no **pinned certificates exist** for the host, the request is automatically **canceled**.
    ///   - If the **server certificate chain cannot be retrieved**, the request is also **canceled**.
    public func urlSession( _ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        /// Verify that this challenge is indeed a server trust challenge (the kind we want to handle for SSL pinning).
        /// If it's not server trust (e.g., client certificate challenge), we do default handling.
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            /// Let the system handle any other type of challenge normally.
            completionHandler(.performDefaultHandling, nil)
            return
        }
        /// Extract the host name from the challenge. We'll use it to look up the pinned certificates.
        let host = challenge.protectionSpace.host
        /// Fetch the pinned certificate data (if any) for this specific host.
        /// If we have no pinned certificates for this host, we reject the connection.
        guard
            let pinnedDatas = pinnedCertificatesByHost[host],
            !pinnedDatas.isEmpty
        else {
            /// No pinned certificates found for the requested host, do not cancel the connection, let the system verify.
            completionHandler(.performDefaultHandling, nil)
            return
        }
        /// Retrieve the server's certificate chain from the serverTrust object. We need to compare it against our pinned data.
        guard
            let chainCFArray = SecTrustCopyCertificateChain(serverTrust),
            let chain = chainCFArray as? [SecCertificate],
            !chain.isEmpty
        else {
            /// If we can't get the server's certificate chain, we can't verify it, so cancel the connection.
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        /// We'll use this boolean to track whether we've found a match between the server's certificate
        /// and any pinned certificate for this host.
        var foundMatch = false
        /// Compare each pinned certificate's raw `Data` with each certificate in the server's chain.
        /// Even if there's a chain of multiple certificates, finding a single exact match is enough
        /// to validate the server's identity.
        for pinnedData in pinnedDatas {
            for serverCert in chain {
                /// Extract the raw data from the server certificate.
                let serverCertData = SecCertificateCopyData(serverCert) as Data
                /// Check if the pinned certificate data exactly matches the server certificate data.
                if serverCertData == pinnedData {
                    foundMatch = true
                    break
                }
            }
            /// If we've found a match already, no need to check the remaining pinned certificates.
            if foundMatch { break }
        }
        /// If we've confirmed that at least one of our pinned certificates matches the server's certificate chain,
        /// we accept the server and proceed with the connection. Otherwise, we cancel it.
        if foundMatch {
            /// Provide the server trust as a credential, indicating we trust the server.
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            /// If the server's certificate chain does not match any pinned data, we consider it untrusted.
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}

// MARK: - URLSessionTaskDelegate & URLSessionDataDelegate
extension PinningURLSessionDelegate: URLSessionTaskDelegate, URLSessionDataDelegate {
    
    /// Forwards task completion events to the `uploadDelegate`, if set.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        uploadDelegate?.urlSession?(session, task: task, didCompleteWithError: error)
        downloadDelegate?.urlSession?(session, task: task, didCompleteWithError: error)
    }
    
    /// Forwards data-receiving events to the `uploadDelegate`, if set.
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        uploadDelegate?.urlSession?(session, dataTask: dataTask, didReceive: data)
    }
    
}

// MARK: - URLSessionTaskDelegate & URLSessionDataDelegate
extension PinningURLSessionDelegate: URLSessionDownloadDelegate {
    
    /// Forwards file download completion events to the `downloadDelegate`, if set.
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        downloadDelegate?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }
    
}
