//
//  Request.swift
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

// MARK: - Request

/// This protocol defines the contract for executing HTTP requests and decoding responses into a given `Decodable` type (`T`).
/// It also provides flexibility for handling retries, caching policies, and custom decoding strategies.
///
/// - Purpose:
///   - To standardize network request operations across different parts of the application.
///   - To abstract away complexities such as retry logic, caching, and decoding responses.
///
/// - Requirements:
///   1. Conforming types must implement both the async/await method and the completion handler method.
///   2. Both methods must handle errors gracefully, including network failures, decoding errors, and connectivity issues.
///
/// - Usage:
///   - **Async/Await (`Swift Concurrency`)**:
///     - Use `request(_:retryCount:cachePolicy:decoder:) async throws -> T` in modern Swift concurrency scenarios.
///     - Provides cleaner syntax, structured concurrency, and improved error handling.
///   - **Completion Handler**:
///     - Use `request(_:retryCount:cachePolicy:decoder:completion:)` in UIKit-based or legacy code where async/await is not available.
///     - Leverages a closure to return the result, aligning well with callback-based approaches.
///
/// - Note:
///   - Conforming to `RequestProtocol` ensures a uniform interface for network requests throughout your codebase.
///   - Facilitates testing, since conforming classes can be easily mocked or swapped.
///   - Encourages clean separation of concerns by isolating network logic in a dedicated component.
protocol RequestProtocol: AnyObject {
    
    /// Executes an HTTP request using the provided `RequestConfig` and returns a decoded `Decodable` object of type `T` via Swift's async/await.
    ///
    /// - Parameters:
    ///   - config: A configuration object describing the endpoint, HTTP method, headers, and body parameters.
    ///   - retryCount: The maximum number of retry attempts if the request fails. Defaults to 0 (no retries).
    ///   - cachePolicy: An optional `CachePolicy` that determines how the response is cached or fetched from the cache.
    ///   - decoder: A `JSONDecoder` to parse the response. Defaults to a standard `JSONDecoder()` if not specified.
    ///
    /// - Returns: A `NetworkingResponse<T>` containing either a successfully decoded object or a `NetworkError`.
    ///
    /// - Throws:
    ///   - `NetworkError.invalidURL` if the URL in `RequestConfig` is malformed.
    ///   - `NetworkError.noInternetConnection` if there is no active internet connection.
    ///   - `NetworkError.requestFailed(statusCode:data:)` if the server responds with an error status code.
    ///   - `NetworkError.decodingError(error)` if the response cannot be decoded into the specified type `T`.
    ///   - `NetworkError.unknown(error)` for unexpected or unhandled errors.
    ///
    /// - Note:
    ///   - Ideal for Swift Concurrency contexts (async/await).
    ///   - Supports optional request retries up to `retryCount`.
    ///   - Integrates with caching logic if `cachePolicy` is provided and supported by the conforming type.
    func request<T: Decodable>(_ config: RequestConfig, retryCount: Int, cachePolicy: CachePolicy?, decoder: JSONDecoder) async throws -> NetworkingResponse<T>
    
    /// Executes an HTTP request using the provided `RequestConfig` and returns a decoded `Decodable` object of type `T` via a completion handler.
    ///
    /// - Parameters:
    ///   - config: A configuration object describing the endpoint, HTTP method, headers, and body parameters.
    ///   - retryCount: The maximum number of retry attempts if the request fails. Defaults to 0 (no retries).
    ///   - cachePolicy: An optional `CachePolicy` that determines how the response is cached or fetched from the cache.
    ///   - queue: The dispatch queue on which the completion handler is executed (default: `.main`).
    ///   - decoder: A `JSONDecoder` to parse the response. Defaults to a standard `JSONDecoder()` if not specified.
    ///   - completion: A `NetworkingResponse<T>` containing either a successfully decoded object or a `NetworkError`.
    ///
    /// - Note:
    ///   - Well-suited for UIKit or legacy code that relies on callbacks rather than async/await.
    ///   - Supports optional request retries up to `retryCount`.
    ///   - Integrates with caching logic if `cachePolicy` is provided and supported by the conforming type.
    func request<T: Decodable>(_ config: RequestConfig, retryCount: Int, cachePolicy: CachePolicy?, queue: DispatchQueue, decoder: JSONDecoder, completion: @escaping (NetworkingResponse<T>) -> Void)
}

/// A network request handler that manages HTTP requests, caching, logging, connection monitor and request interception.
///
/// This class is responsible for executing network requests, handling caching, logging request details,
/// and applying request modifications or retries via an interceptor.
///
/// - Note:
///   - Supports optional request interception using `RequestInterceptor`.
///   - Provides optional caching using `ResponseCaching`.
///   - Logs requests and responses via `NetworkLogger`.
///
/// ## Example Usage:
/// ```swift
/// let session = URLSession.shared
/// let interceptor = RequestInterceptor()
/// let logger = NetworkLogger()
/// let cache = NetworkCache()
/// let request = Request(urlSession: session, cache: cache, logger: logger)
/// ```
/// This class is intended to be used only by `Networking`.
/// Please DO NOT create or use this class directly.
open class Request: RequestProtocol {
    
    /// The URL session used to execute network requests.
    private(set) var urlSession: URLSession
    
    /// Optional interceptor that modifies requests before sending them or determines retry behavior.
    private(set) var interceptor: RequestInterceptor?
    
    /// Optional logger for tracking network request and response details.
    private(set) var logger: NetworkLoggerProtocol?
    
    /// Optional cache for storing and retrieving network responses.
    private(set) var cache: ResponseCaching?
    
    /// A connection monitor that tracks network availability.
    private(set) var connectionMonitor: ConnectionMonitor
    
    /// Initializes the `Request` handler with optional interceptor, cache, logging, and network monitoring support.
    ///
    /// - This initializer sets up a network request handler that can manage network requests,
    ///   apply request modifications, cache responses, and log network activity.
    /// - It ensures that requests are executed efficiently by monitoring network availability.
    ///
    /// - Parameters:
    ///   - urlSession: The `URLSession` used for network requests.
    ///                 - This session handles all HTTP requests and responses.
    ///                 - It must be properly configured for background or foreground tasks.
    ///   - interceptor: An optional `RequestInterceptor` for modifying requests and handling retries.
    ///                 - If provided, it allows preprocessing requests before they are sent.
    ///                 - Can be used for adding authentication headers, retrying failed requests, etc.
    ///   - cache: An optional `ResponseCaching` instance to enable caching of responses.
    ///           - If `nil`, responses will not be cached.
    ///           - Useful for reducing network requests and improving performance.
    ///   - logger: An optional `NetworkLogger` instance for logging network activity.
    ///           - If `nil`, logging is disabled.
    ///           - Helps in debugging by capturing request and response details.
    ///   - connectionMonitor: A `ConnectionMonitor` instance to track network availability.
    ///                        - Used to check if a network connection is available before sending requests.
    ///                        - Helps in managing offline scenarios efficiently.
    ///
    /// - Note:
    ///   - If no `interceptor`, `cache`, or `logger` is provided, they remain `nil`, and requests
    ///     will be executed without modifications, caching, or logging.
    ///   - The `connectionMonitor` is **required** to ensure that network requests can be managed
    ///     efficiently based on network status.
    ///   - This initializer should be called before making any network requests to ensure
    ///     proper setup.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let urlSession = URLSession(configuration: .default)
    ///   let connectionMonitor = ConnectionMonitor()
    ///   let requestHandler = Request(urlSession: urlSession, connectionMonitor: connectionMonitor)
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This initializer should be called from a **safe thread context**, especially
    ///     when multiple network handlers are being initialized in parallel.
    public init(urlSession: URLSession, interceptor: RequestInterceptor? = nil, cache: ResponseCaching? = nil, logger: NetworkLogger? = nil, connectionMontitor: ConnectionMonitor) {
        self.urlSession = urlSession
        self.interceptor = interceptor
        self.cache = cache
        self.logger = logger
        self.connectionMonitor = connectionMontitor
    }
    
}

// MARK: - Request - Async/Await Request
extension Request {
    
    /// Sends an HTTP request using the given `RequestConfig` and decodes the response into a specified `Decodable` type (`T`).
    ///
    /// - This method performs an asynchronous HTTP request, processes the response, and attempts to decode the response body.
    /// - It supports caching, request modifications through an interceptor, and automatic retry mechanisms.
    /// - The request will be retried up to the specified `retryCount` if an error occurs.
    ///
    /// - Parameters:
    ///   - config: A `RequestConfig` object containing request details such as:
    ///             - `URL`: The endpoint to send the request to.
    ///             - `method`: The HTTP method (e.g., `.get`, `.post`).
    ///             - `parameters`: Any query or body parameters to be included in the request.
    ///             - `headers`: Custom HTTP headers to send with the request.
    ///   - retryCount: The number of retry attempts in case of failure (default: `0`).
    ///                 - If greater than `0`, the request will be automatically retried on failure.
    ///                 - Retries are useful for handling temporary network issues.
    ///   - cachePolicy: An optional `CachePolicy` determining how the request interacts with caching.
    ///                  - If `nil`, the default cache policy is used.
    ///                  - This allows fine-grained control over request and response caching.
    ///   - decoder: The `JSONDecoder` used to decode the response (default: `JSONDecoder()`).
    ///              - Can be customized to use different decoding strategies.
    ///
    /// - Returns: A `NetworkingResponse<T>` containing either the decoded response model or a `NetworkError`.
    ///
    /// - Throws:
    ///   - `NetworkError.invalidURL`: If the request URL is malformed or missing.
    ///   - `NetworkError.requestFailed(statusCode:data:)`: If the HTTP request fails (e.g., network failure, 404, 500 errors).
    ///   - `NetworkError.decodingError(error)`: If the response could not be decoded into the expected type `T`.
    ///   - `NetworkError.unknown(error)`: If an unexpected error occurs.
    ///   - `NetworkError.noInternetConnection` if there is no active internet connection when the request is attempted.
    ///
    /// - Note:
    ///   - **Caching Support**: If a `CachePolicy` is provided, responses can be retrieved from or stored in the cache.
    ///   - **Interceptor Support**: If an interceptor is configured, it will be used to modify or handle requests before execution.
    ///   - **Retry Mechanism**: If a retry strategy is implemented, failed requests may be automatically retried based on `retryCount`.
    ///
    /// - Thread Safety:
    ///   - This method is **asynchronous** (`async`) and should be called from an **async context**.
    ///   - If UI updates are required after completion, ensure they are performed on the **main thread**.
    public func request<T: Decodable>(_ config: RequestConfig, retryCount: Int = 0, cachePolicy: CachePolicy? = nil, decoder: JSONDecoder = JSONDecoder()) async throws -> NetworkingResponse<T> {
        /// Create `URLRequest` from the request configuration.
        var urlRequest: URLRequest
        do {
            urlRequest = try buildURLRequest(config: config)
        } catch {
            /// e.g. invalid URL or missing param
            let networkError = convertToNetworkError(error: error)
            return NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(networkError))
        }
        
        /// Check if caching is enabled and a valid cached response exists.
        if let cachePolicy = cachePolicy, cachePolicy.useCache, let cache = cache {
            logger?.logMessage(message: "useCache = true, attempting to retrieve from cache", level: .debug, logPrivacy: .public)
            if let finalURL = urlRequest.url, let cachedData = cache.getResponse(for: finalURL) {
                logger?.logMessage(message: "Cached response found for \(finalURL.absoluteString)", level: .info, logPrivacy: .public)
                /// Log request before returning cached response.
                logger?.log(request: urlRequest)
                /// Log response before returning cached response.
                logger?.log(responseData: cachedData, response: nil, error: nil)
                /// Return decoded data from the cache.
                do {
                    let decodedValue: T = try decoder.decode(T.self, from: cachedData)
                    /// Build success response
                    /// There is no data and response for cached response
                    return NetworkingResponse(request: urlRequest, response: nil, data: cachedData, result: .success(decodedValue))
                } catch {
                    let networkError = NetworkError.decodingError(error)
                    return NetworkingResponse(request: urlRequest, response: nil, data: cachedData, result: .failure(networkError))
                }
            }
        }
        /// Check if the device has an active internet connection before proceeding with the network request.
        if !connectionMonitor.isReachable {
            logger?.logMessage(message: "Request cancel, no internet connection, throwing .noInternetConnection", level: .error, logPrivacy: .public)
            /// If the device is offline, throw a `NetworkError.noInternetConnection` error.
            /// This prevents unnecessary network calls and allows the caller to handle offline scenarios gracefully.
            let networkError = NetworkError.noInternetConnection
            return NetworkingResponse(request: urlRequest, response: nil, data: nil, result: .failure(networkError))
        }
        /// Adapt the request using the interceptor, if available.
        if let interceptor = interceptor {
            urlRequest = try await interceptor.adapt(urlRequest)
            logger?.logMessage(message: "Request adapted by interceptor", level: .debug, logPrivacy: .public)
        }
        /// Log the outgoing request.
        logger?.log(request: urlRequest)
        /// dataTask do catch block
        do {
            /// Execute the network request using `URLSession`.
            let (data, response) = try await urlSession.data(for: urlRequest)
            /// Log response data.
            logger?.log(responseData: data, response: response, error: nil)
            /// Validate the response and throw an error if necessary.
            try validate(response: response, data: data)
            /// Store the response in cache if caching is enabled.
            if let cachePolicy = cachePolicy, cachePolicy.storeCache, let finalURL = urlRequest.url, let cache = cache {
                logger?.logMessage(message: "storeCache = true, caching response for \(finalURL.absoluteString)", level: .debug, logPrivacy: .public)
                cache.setResponse(data, for: finalURL, expireTime: cachePolicy.expireTime)
            }
            logger?.logMessage(message: "Decoded object of type \(T.self) successfully", level: .info, logPrivacy: .public)
            /// Decode and return the response data.
            let decodedData: T = try decodeData(data, with: decoder)
            return NetworkingResponse(request: urlRequest, response: response, data: data, result: .success(decodedData))
        } catch {
            /// Log the error before retrying or throwing it.
            logger?.log(responseData: nil, response: nil, error: error)
            /// Convert the error into a `NetworkError`.
            let networkError = convertToNetworkError(error: error)
            /// If an interceptor and retry mechanism exist, attempt to retry
            /// Otherwise, return an error
            if let interceptor = interceptor {
                return try await handleRetry(interceptor: interceptor, urlRequest: urlRequest, config: config, retryCount: retryCount, decoder: decoder, networkError: networkError)
            } else {
                /// If no retry mechanism is available, throw the error.
                return NetworkingResponse(request: urlRequest, response: nil, data: nil, result: .failure(networkError))
            }
        }
    }
    
    /// Handles request retries based on the provided `RequestInterceptor`, retry count, and network error.
    ///
    /// - This method determines whether a failed network request should be retried.
    /// - It supports various retry strategies, including:
    ///   - **Immediate Retry**: Instantly resends the request.
    ///   - **Retry with Delay**: Waits for a fixed delay before retrying.
    ///   - **Exponential Backoff**: Gradually increases the delay between retries to prevent server overload.
    /// - The retry logic is managed via the `RequestInterceptor`, which can dictate:
    ///   - Whether a request should be retried.
    ///   - The delay duration before retrying.
    ///
    /// - Parameters:
    ///   - interceptor: A `RequestInterceptor` responsible for deciding whether the request should be retried.
    ///   - urlRequest: The `URLRequest` that previously failed.
    ///   - config: The original `RequestConfig` used for the request.
    ///   - retryCount: The current retry attempt number.
    ///   - decoder: A `JSONDecoder` used to decode the response.
    ///   - networkError: The `NetworkError` that triggered the retry attempt.
    ///
    /// - Returns: A `NetworkingResponse<T>` representing either a successful retry or a failure result.
    ///
    /// - Throws:
    ///   - The original `networkError` if no retry is allowed.
    ///   - Any error encountered during the retry attempt.
    ///
    /// - Note:
    ///   - This method ensures **non-blocking retries** using `Task.sleep(nanoseconds:)`.
    ///   - The retry strategy may be **adaptive**, increasing the delay based on previous failures.
    ///   - If the retry count exceeds the maximum allowed attempts, the method throws the original error.
    ///
    /// - Thread Safety:
    ///   - This method runs **asynchronously** and must be called from an **async context**.
    ///   - Non-blocking sleep (`Task.sleep(nanoseconds:)`) ensures efficient use of system resources.
    private func handleRetry<T: Decodable>(interceptor: RequestInterceptor, urlRequest: URLRequest, config: RequestConfig, retryCount: Int, decoder: JSONDecoder, networkError: NetworkError) async throws -> NetworkingResponse<T> {
        logger?.logMessage(message: "handleRetry called. Current retryCount = \(retryCount)", level: .debug, logPrivacy: .public)
        do {
            let second: TimeInterval = 1_000_000_000
            let retryResult = try await interceptor.retry(urlRequest, dueTo: networkError, currentRetryCount: retryCount)
            switch retryResult {
            case .doNotRetry:
                /// No retry attempt; return failure immediately.
                logger?.logMessage(message: "Interceptor decided: doNotRetry", level: .info, logPrivacy: .public)
                throw networkError
            case .retry:
                /// Retry immediately without delay.
                logger?.logMessage(message: "Interceptor decided: retry immediately", level: .info, logPrivacy: .public)
                return try await request(config, retryCount: retryCount + 1, decoder: decoder)
            case .retryWithDelay(let delay):
                /// Wait for the specified delay before retrying.
                logger?.logMessage(message: "Interceptor decided: retryWithDelay (\(delay) sec)", level: .info, logPrivacy: .public)
                try await Task.sleep(nanoseconds: UInt64(delay * second))
                return try await request(config, retryCount: retryCount + 1, decoder: decoder)
            case .retryWithExponentialBackoff(let backOff):
                /// Calculate the exponential backoff delay based on the retry count.
                let computedDelay = backOff.delay(for: retryCount)
                logger?.logMessage(message: "Interceptor decided: retryWithExponentialBackoff => \(computedDelay) sec", level: .info, logPrivacy: .public)
                try await Task.sleep(nanoseconds: UInt64(computedDelay * second))
                return try await request(config, retryCount: retryCount + 1, decoder: decoder)
            }
        } catch {
            let networkError = convertToNetworkError(error: error)
            return NetworkingResponse(request: urlRequest, response: nil, data: nil, result: .failure(networkError))
        }
    }
    
}

// MARK: - Request - Completion Handler
extension Request {
    
    /// Sends an HTTP request using the given `RequestConfig` and decodes the response into a specified `Decodable` type (`T`), using a completion handler.
    ///
    /// - This method executes an HTTP request, processes the response, and attempts to decode the response body.
    /// - It supports caching, request modifications through an interceptor, and automatic retry mechanisms.
    /// - The request will be retried up to the specified `retryCount` if an error occurs.
    ///
    /// - Parameters:
    ///   - config: A `RequestConfig` object containing request details such as:
    ///             - `URL`: The endpoint to send the request to.
    ///             - `method`: The HTTP method (e.g., `.get`, `.post`).
    ///             - `parameters`: Any query or body parameters to be included in the request.
    ///             - `headers`: Custom HTTP headers to send with the request.
    ///   - retryCount: The number of retry attempts in case of failure (default: `0`).
    ///                 - If greater than `0`, the request will be automatically retried on failure.
    ///                 - Retries help in handling temporary network failures.
    ///   - cachePolicy: An optional `CachePolicy` determining how the request interacts with caching.
    ///                  - If `nil`, the default cache policy is used.
    ///                  - Allows fine-grained control over request and response caching.
    ///   - queue: The dispatch queue on which the completion handler is executed (default: `.main`).
    ///   - decoder: The `JSONDecoder` used to decode the response (default: `JSONDecoder()`).
    ///              - Can be customized to use different decoding strategies.
    ///   - completion: A closure that receives a `NetworkingResponse<T>`, containing either a successfully decoded model or a `NetworkError`.
    ///                 - `.success(T)`: The successfully decoded response object.
    ///                 - `.failure(NetworkError)`: An error describing why the request failed.
    ///
    /// - Note:
    ///   - **Caching Support**: If a `CachePolicy` is provided, responses can be retrieved from or stored in the cache.
    ///   - **Interceptor Support**: If an interceptor is configured, it will be used to modify or handle requests before execution.
    ///   - **Retry Mechanism**: If a retry strategy is implemented, failed requests may be automatically retried based on `retryCount`.
    ///   - **Completion-Based API**: This method is useful in **non-async contexts**, such as when working with UIKit or older APIs that rely on completion handlers.
    ///
    /// - Thread Safety:
    ///   - The method should be **called on a background thread**, as network requests may take time.
    ///   - UI updates should be performed on the **main thread** inside the completion handler.
    public func request<T: Decodable>(_ config: RequestConfig, retryCount: Int = 0, cachePolicy: CachePolicy? = nil, queue: DispatchQueue = .main, decoder: JSONDecoder = JSONDecoder(), completion: @escaping (NetworkingResponse<T>) -> Void) {
        do {
            /// Create a `URLRequest` from the request configuration.
            var urlRequest = try buildURLRequest(config: config)
            /// If an interceptor is available, adapt the request before execution.
            if let interceptor = interceptor {
                Task {
                    do {
                        logger?.logMessage(message: "Request adapted by interceptor (completion)", level: .debug, logPrivacy: .public)
                        /// Modify the request before sending it (e.g., add authentication headers).
                        urlRequest = try await interceptor.adapt(urlRequest)
                        /// Proceed with executing the request.
                        self.performRequest(urlRequest, config: config, retryCount: retryCount, cachePolicy: cachePolicy, queue: queue, decoder: decoder, completion: completion)
                    } catch {
                        /// Log the error and return a failure result.
                        self.logger?.log(responseData: nil, response: nil, error: error)
                        let networkError = self.convertToNetworkError(error: error)
                        let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: urlRequest, response: nil, data: nil, result: .failure(networkError))
                        completion(networkingResponse)
                    }
                }
            } else {
                /// If no interceptor is available, directly perform the request.
                performRequest(urlRequest, config: config, retryCount: retryCount, cachePolicy: cachePolicy, queue: queue, decoder: decoder, completion: completion)
            }
        } catch {
            /// If request creation fails, log the error and return an invalid request error.
            logger?.log(responseData: nil, response: nil, error: error)
            let networkError = NetworkError.invalidRequest
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(networkError))
            completion(networkingResponse)
        }
    }
    
    /// Executes an HTTP request and decodes the response into a specified `Decodable` type (`T`), using a completion handler.
    ///
    /// - This method performs an HTTP request, handles caching, logs the request/response, and decodes the response data.
    /// - If a **valid cached response** exists (based on `cachePolicy`), the request will **not** be sent to the server.
    /// - Supports **automatic retries** via an interceptor in case of request failures.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` to be executed.
    ///   - config: A `RequestConfig` object containing additional request settings.
    ///   - retryCount: The number of retry attempts if the request fails.
    ///                 - If greater than `0`, the request will be automatically retried on failure.
    ///                 - Retries help in handling temporary network failures.
    ///   - cachePolicy: An optional `CachePolicy` defining how the request should interact with caching.
    ///                  - If `nil`, the default caching behavior is used.
    ///   - queue: The dispatch queue on which the completion handler is executed (default: `.main`).
    ///   - decoder: The `JSONDecoder` used to decode the response.
    ///              - Can be customized to use different decoding strategies.
    ///   - completion: A closure receiving a `NetworkingResponse<T>`, containing the decoded value or a `NetworkError`.
    ///                 - `.success(T)`: The successfully decoded response object.
    ///                 - `.failure(NetworkError)`: An error indicating why the request failed.
    ///
    /// - Throws:
    ///   - `NetworkError.invalidURL` if the request URL is malformed.
    ///   - `NetworkError.requestFailed(statusCode:data:)` if the HTTP request fails (e.g., 404, 500).
    ///   - `NetworkError.decodingError(error)` if the response could not be decoded into `T`.
    ///   - `NetworkError.unknown(error)` for unexpected errors.
    ///   - `NetworkError.noInternetConnection` if there is no active internet connection when the request is attempted.
    ///
    /// - Note:
    ///   - **Caching Support**: If a valid cached response is available, the request will **not** be executed.
    ///   - **Logging Support**: The request, response, and any errors are **logged** for debugging purposes.
    ///   - **Retry Mechanism**: If an interceptor is available, it determines whether and how to retry failed requests.
    ///   - **Completion-Based API**: This function is useful in **non-async contexts**, such as UIKit-based applications.
    ///
    /// - Thread Safety:
    ///   - The method should be **executed in a background thread**, as network operations are blocking.
    ///   - UI updates (e.g., displaying results) should be performed on the **main thread** inside the completion handler.
    private func performRequest<T: Decodable>(_ request: URLRequest, config: RequestConfig, retryCount: Int, cachePolicy: CachePolicy? = nil, queue: DispatchQueue, decoder: JSONDecoder, completion: @escaping (NetworkingResponse<T>) -> Void) {
        /// Check if the device has an active internet connection before proceeding with the network request.
        if !connectionMonitor.isReachable {
            logger?.logMessage(message: "Request cancel, no internet connection (completion) => .noInternetConnection", level: .error, logPrivacy: .public)
            /// If the device is offline, throw a `NetworkError.noInternetConnection` error.
            /// This prevents unnecessary network calls and allows the caller to handle offline scenarios gracefully.
            let networkError = NetworkError.noInternetConnection
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: nil, data: nil, result: .failure(networkError))
            completion(networkingResponse)
            return
        }
        /// Check if caching is enabled and a valid cached response exists.
        if let cachePolicy = cachePolicy, cachePolicy.useCache, let cache = cache {
            logger?.logMessage(message: "useCache = true, attempting to retrieve from cache", level: .debug, logPrivacy: .public)
            if let finalURL = request.url, let cachedData = cache.getResponse(for: finalURL) {
                logger?.logMessage(message: "Cached response found for \(finalURL.absoluteString) (completion)", level: .info, logPrivacy: .public)
                /// Log request before returning cached response.
                logger?.log(request: request)
                /// Log response before returning cached response.
                logger?.log(responseData: cachedData, response: nil, error: nil)
                /// Attempt to decode the cached response; return an error if decoding fails.
                do {
                    let decoded: T = try self.decodeData(cachedData, with: decoder)
                    queue.async {
                        let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: nil, data: cachedData, result: .success(decoded))
                        completion(networkingResponse)
                    }
                    return
                } catch {
                    let networkError = NetworkError.decodingError(error)
                    let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: nil, data: cachedData, result: .failure(networkError))
                    completion(networkingResponse)
                }
            }
        }
        /// Log the outgoing request.
        logger?.log(request: request)
        /// Start the network request using `URLSession`.
        let task = urlSession.dataTask(with: request) { data, response, error in
            /// Log response, response data, and error if any.
            self.logger?.log(responseData: data, response: response, error: error)
            /// Check if an error occurred.
            if let error = error {
                let networkError = self.convertToNetworkError(error: error)
                /// If an interceptor exists and retry conditions are met, retry the request
                /// Otherwise, do not proceed and return an error
                if let interceptor = self.interceptor {
                    self.handleRetry(interceptor: interceptor, urlRequest: request, config: config, retryCount: retryCount, cachePolicy: cachePolicy, response: response, data: data, queue: queue, decoder: decoder, networkError: networkError, completion: completion)
                } else {
                    let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: response, data: data, result: .failure(networkError))
                    completion(networkingResponse)
                }
                return
            }
            /// Ensure both data and response are available.
            guard
                let data = data,
                let response = response
            else {
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: response, data: data, result: .failure(.noData))
                completion(networkingResponse)
                return
            }
            /// Attempt to validate the response; return an error if validation fails.
            do {
                try self.validate(response: response, data: data)
            } catch let networkError as NetworkError {
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: response, data: data, result: .failure(networkError))
                completion(networkingResponse)
                return
            } catch {
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: response, data: data, result: .failure(.unknown(error)))
                completion(networkingResponse)
                return
            }
            /// If it's VoidPlaceholder, handle it with a special check and return the NetworkingResponse without decoding the data.
            if T.self == VoidPlaceholder.self {
                guard let voidPlaceholder = VoidPlaceholder() as? T else {
                    let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: response, data: data, result: .failure(.noData))
                    completion(networkingResponse)
                    return
                }
                queue.async {
                    let successResponse: NetworkingResponse<T> = NetworkingResponse(
                        request: request,
                        response: response,
                        data: data,
                        result: .success(voidPlaceholder)
                    )
                    completion(successResponse)
                }
                return
            }
            /// Attempt to decode the response data; return an error if decoding fails.
            do {
                let decoded: T = try self.decodeData(data, with: decoder)
                queue.async {
                    let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: response, data: data, result: .success(decoded))
                    completion(networkingResponse)
                }
            } catch {
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: response, data: data, result: .failure(.decodingError(error)))
                completion(networkingResponse)
            }
        }
        /// Resume the task to start execution.
        task.resume()
    }
    
    /// Handles request retries based on the provided `RequestInterceptor`, retry count, and network error, using a completion handler.
    ///
    /// - This method determines whether a failed network request should be retried based on the interceptor's strategy.
    /// - It supports various retry mechanisms, including:
    ///   - **Immediate Retry**: Instantly resends the request.
    ///   - **Retry with Delay**: Waits for a fixed delay before retrying.
    ///   - **Exponential Backoff**: Gradually increases the delay between retries to prevent server overload.
    /// - If the retry count exceeds the allowed limit, the original `networkError` is returned in the completion handler.
    ///
    /// - Parameters:
    ///   - interceptor: A `RequestInterceptor` responsible for deciding whether the request should be retried.
    ///   - urlRequest: The `URLRequest` that previously failed.
    ///   - config: The original `RequestConfig` used for the request.
    ///   - retryCount: The current retry attempt number.
    ///   - cachePolicy: An optional `CachePolicy` to determine if a cached response can be used instead of retrying.
    ///   - response: The last `URLResponse` received from the server, if any.
    ///   - data: The last body `Data` received from the server, if any.
    ///   - queue: The dispatch queue on which the completion handler is executed (default: `.main`).
    ///   - decoder: A `JSONDecoder` used to decode the response data.
    ///   - networkError: The `NetworkError` that triggered the retry attempt.
    ///   - completion: A closure that receives a `NetworkingResponse<T>` with either the decoded value or the final error result.
    ///                 - `.success(T)`: The successfully decoded response object.
    ///                 - `.failure(NetworkError)`: An error indicating why the retry attempt failed.
    ///
    /// - Note:
    ///   - **Non-blocking Delays**: Uses `Task.sleep(nanoseconds:)` to implement retry delays without blocking the main thread.
    ///   - **Asynchronous Execution**: Runs the retry logic inside a `Task {}` to ensure it doesn't block the current thread.
    ///   - **Adaptive Retries**: The retry delay may increase based on the number of previous failures.
    ///   - **Completion-Based API**: This method is useful in **non-async contexts**, such as UIKit-based applications.
    ///
    /// - Thread Safety:
    ///   - This method is executed asynchronously and should be called from a **safe thread context**.
    ///   - If UI updates are needed after the retry, ensure they are performed on the **main thread**.
    private func handleRetry<T: Decodable>(interceptor: RequestInterceptor, urlRequest: URLRequest, config: RequestConfig, retryCount: Int, cachePolicy: CachePolicy? = nil, response: URLResponse?, data: Data?, queue: DispatchQueue, decoder: JSONDecoder, networkError: NetworkError, completion: @escaping (NetworkingResponse<T>) -> Void) {
        Task {
            logger?.logMessage(message: "handleRetry (completion) called. Current retryCount = \(retryCount)", level: .debug, logPrivacy: .public)
            /// 1 second = 1_000_000_000 nanoseconds
            let second: TimeInterval = 1_000_000_000
            /// Ask the interceptor whether the request should be retried.
            let retryResult = try await interceptor.retry(urlRequest, dueTo: networkError, currentRetryCount: retryCount)
            switch retryResult {
            case .doNotRetry:
                /// No retry attempt; return failure immediately.
                logger?.logMessage(message: "Interceptor decided: doNotRetry (completion)", level: .info, logPrivacy: .public)
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: urlRequest, response: response, data: data, result: .failure(networkError))
                completion(networkingResponse)
            case .retry:
                /// Retry immediately without delay.
                logger?.logMessage(message: "Interceptor decided: retry immediately (completion)", level: .info, logPrivacy: .public)
                self.performRequest(urlRequest, config: config, retryCount: retryCount + 1, cachePolicy: cachePolicy, queue: queue, decoder: decoder, completion: completion)
            case .retryWithDelay(let delay):
                /// Wait for the specified delay before retrying.
                logger?.logMessage(message: "Interceptor decided: retryWithDelay (\(delay) sec) (completion)", level: .info, logPrivacy: .public)
                try await Task.sleep(nanoseconds: UInt64(delay * second))
                self.performRequest(urlRequest, config: config, retryCount: retryCount + 1, cachePolicy: cachePolicy, queue: queue, decoder: decoder, completion: completion)
            case .retryWithExponentialBackoff(let backOff):
                /// Calculate the exponential backoff delay based on the retry count.
                let computedDelay = backOff.delay(for: retryCount)
                logger?.logMessage(message: "Interceptor decided: retryWithExponentialBackoff => \(computedDelay) sec (completion)", level: .info, logPrivacy: .public)
                try await Task.sleep(nanoseconds: UInt64(computedDelay * second))
                self.performRequest(urlRequest, config: config, retryCount: retryCount + 1, cachePolicy: cachePolicy, queue: queue, decoder: decoder, completion: completion)
            }
        }
    }
    
}

// MARK: - Request Helper Functions
extension Request {
    
    /// Constructs a `URLRequest` from the given `RequestConfig`.
    ///
    /// - This method builds a `URLRequest` by:
    ///   - Appending query parameters to the URL if provided.
    ///   - Setting HTTP headers specified in the `RequestConfig`.
    ///   - Encoding and attaching body parameters based on the request method.
    ///
    /// - Parameters:
    ///   - config: The `RequestConfig` containing:
    ///       - `url`: The base URL for the request.
    ///       - `method`: The HTTP method (e.g., `.get`, `.post`).
    ///       - `parameters`: The request parameters, either as query items or in the body.
    ///       - `headers`: Custom headers to include in the request.
    ///
    /// - Returns: A properly constructed `URLRequest` ready for execution.
    ///
    /// - Throws: Throws an error if the request cannot be created.
    ///
    /// - Note:
    ///   - **Query Parameters**: If the request method is `.get`, parameters are added as URL query items.
    ///   - **Body Encoding**:
    ///     - For `.post`, `.put`, `.patch`, parameters are JSON-encoded in the request body.
    ///     - The `"Content-Type"` header is set to `"application/json"` by default.
    ///   - **Headers**:
    ///     - Custom headers specified in `RequestConfig.headers` are applied.
    ///     - If no `"Content-Type"` is specified, `"application/json"` is used.
    ///
    /// - Thread Safety:
    ///   - This method should be called from a **safe thread context** since it involves encoding operations.
    ///   - If modifying shared state (e.g., logging), ensure it is handled safely.
    private func buildURLRequest(config: RequestConfig) throws -> URLRequest {
        logger?.logMessage(message: "buildURLRequest start", level: .debug, logPrivacy: .public)
        guard let url = URL(string: config.url) else {
            throw NetworkError.invalidURL
        }
        /// Initialize `URLComponents` to modify query parameters safely.
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        /// Append query parameters to the URL if they exist.
        if let queryParameters = config.queryParameters, !queryParameters.isEmpty {
            urlComponents?.queryItems = queryParameters.map {
                URLQueryItem(name: $0.key, value: String(describing: $0.value))
            }
        }
        /// Ensure the final URL is valid; otherwise, throw an error.
        guard let finalURL = urlComponents?.url else {
            logger?.logMessage(message: "buildURLRequest -> invalidURL", level: .error, logPrivacy: .public)
            throw NetworkError.invalidURL
        }
        /// Create the `URLRequest` using the final URL.
        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = config.method.rawValue
        /// Set HTTP headers if provided.
        if let headers = config.headers?.dictionary {
            headers.forEach { key, value in
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        /// Set body parameters if provided.
        if let body = config.bodyParameters {
            /// Encode the body as JSON.
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            /// Set the appropriate `Content-Type` header.
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        /// Return the constructed `URLRequest`.
        return urlRequest
    }
    
    /// Validates the HTTP response and checks for potential errors.
    ///
    /// - This method performs validation on an `HTTPURLResponse` to determine if the request was successful.
    /// - It checks the response status code and, if an error occurs, includes the response data in the thrown error for debugging.
    ///
    /// - Parameters:
    ///   - response: The `URLResponse` received from the server.
    ///   - data: The raw `Data` received in the response body.
    ///
    /// - Returns: This method does not return a value but throws an error if validation fails.
    ///
    /// - Throws:
    ///   - `NetworkError.requestFailed(statusCode:data:)` if the status code indicates failure (non-2xx).
    ///
    /// - Note:
    ///   - **Success Criteria**:
    ///     - The response must be of type `HTTPURLResponse`.
    ///     - The status code must be in the **2xx range** (e.g., `200 OK`, `201 Created`).
    ///   - **Error Handling**:
    ///     - If the request fails, the response data (if available) is included in the error for debugging.
    ///   - **Common Failure Cases**:
    ///     - `400 Bad Request`: The request was malformed.
    ///     - `401 Unauthorized`: Authentication failed.
    ///     - `403 Forbidden`: The client does not have permission.
    ///     - `404 Not Found`: The requested resource was not found.
    ///     - `500 Internal Server Error`: A server-side error occurred.
    ///
    /// - Thread Safety:
    ///   - This method should be **called on a background thread** since it is part of a network request handling process.
    private func validate(response: URLResponse, data: Data) throws {
        logger?.logMessage(message: "validate start", level: .debug, logPrivacy: .public)
        /// Ensure the response is an `HTTPURLResponse`; otherwise, return a failure error.
        guard let httpResponse = response as? HTTPURLResponse else {
            logger?.logMessage(message: "validate -> Non-HTTP response", level: .error, logPrivacy: .public)
            throw NetworkError.requestFailed(statusCode: -1, data: data)
        }
        /// Extract the HTTP status code.
        let statusCode = httpResponse.statusCode
        /// Check if the status code indicates a successful response (2xx).
        guard statusCode.statusCodeType == .successful else {
            logger?.logMessage(message: "validate -> Request failed. Status code: \(statusCode)", level: .error, logPrivacy: .public)
            /// If the status code is not in the 2xx range, throw a request failure error.
            throw NetworkError.requestFailed(statusCode: statusCode, data: data)
        }
    }
    
    /// Decodes the given `Data` into a specified `Decodable` type (`T`).
    ///
    /// - This method utilizes Swift's `JSONDecoder` to deserialize raw JSON data into a strongly typed object.
    /// - If decoding fails, an error is thrown, which should be caught and handled appropriately.
    ///
    /// - Parameters:
    ///   - data: The `Data` received from the network response.
    ///   - decoder: The `JSONDecoder` instance used for decoding the response.
    ///
    /// - Returns: A successfully decoded object of type `T`.
    ///
    /// - Throws:
    ///   - `NetworkError.noData` if the JSON decoding process fails.
    ///
    /// - Note:
    ///   - **Decoding Strategy**:
    ///     - The provided `JSONDecoder` is used to deserialize the JSON response.
    ///     - Custom decoding strategies for **dates** or **key decoding** can be configured in `decoder`.
    ///   - **Error Handling**:
    ///     - If the response is **empty**, decoding will fail.
    ///     - If the data does not match the expected model structure, an error will be thrown.
    ///   - **Performance**:
    ///     - This method is efficient for structured JSON but might not be suitable for very large datasets.
    ///
    /// - Thread Safety:
    ///   - This method should be **executed in a background thread**, as decoding large datasets can be CPU-intensive.
    ///   - If UI updates are needed after decoding, ensure they are performed on the **main thread**.
    private func decodeData<T: Decodable>(_ data: Data, with decoder: JSONDecoder) throws -> T {
        guard !data.isEmpty else {
            logger?.logMessage(message: "decodeData -> Received empty data", level: .error, logPrivacy: .public)
            throw NetworkError.noData
        }
        /// Attempt to decode the data into the expected `Decodable` type `T`.
        /// If decoding fails, it will throw a `decodingError`, which should be handled by the caller.
        return try decoder.decode(T.self, from: data)
    }
    
    /// Converts a generic `Error` into a `NetworkError` for better error handling.
    ///
    /// - This method standardizes error handling by converting unknown or system-generated errors
    ///   into a structured `NetworkError` type, making debugging and error management easier.
    ///
    /// - Parameters:
    ///   - error: The `Error` instance to be converted.
    ///
    /// - Returns: A `NetworkError` instance representing the original error.
    ///
    /// - Note:
    ///   - If the error is **already** a `NetworkError`, it is returned **as-is**.
    ///   - If the error is of type `URLError`, it is converted to an appropriate `NetworkError` case.
    ///   - If the error is **unknown**, it is wrapped as `NetworkError.unknown`, preserving the original error details.
    ///   - Helps in categorizing errors into meaningful network-related cases, such as:
    ///     - `NetworkError.invalidURL`
    ///     - `NetworkError.noInternetConnection`
    ///     - `NetworkError.requestTimeout`
    ///     - `NetworkError.unknown(error)`
    ///
    /// - Thread Safety:
    ///   - This method is lightweight and can be **safely called from any thread**.
    private func convertToNetworkError(error: Error) -> NetworkError {
        /// If the error is already a `NetworkError`, return it directly.
        if let networkError = error as? NetworkError {
            return networkError
        }
        /// Otherwise, wrap it in `NetworkError.unknown` to retain the original error details.
        return .unknown(error)
    }
    
}
