//
//  Uploader.swift
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

// MARK: - Uploader

/// This protocol outlines all essential methods for file uploads in an HTTP context, covering various data formats and use cases.
/// It includes functionalities for uploading raw data, multipart form-data, and `x-www-form-urlencoded` content, as well as managing upload tasks.
///
/// - Purpose:
///   - Define a standardized interface for uploading files or data to remote servers.
///   - Provide methods to handle large file uploads, track progress, and manage the lifecycle of each upload task.
///   - Encourage consistent design patterns and improve maintainability across different modules.
///
/// - Key Responsibilities:
///   1. **Multipart Upload**: Send multiple files (and optional additional parameters) via `uploadMultipart(...)`.
///   2. **Raw Data Upload**: Transfer binary data (e.g., images, videos) in a single HTTP request using `uploadRawData(...)`.
///   3. **Local File Upload**: Upload a file directly from local disk via `uploadFile(from:to:...)`, optimizing memory usage.
///   4. **Form-URLEncoded Upload**: Send simple key-value pairs (e.g., for form submissions) via `uploadFormURLEncoded(...)`.
///   5. **Cancellation**: Cancel or abort any ongoing upload with `cancelUpload(task:)` or all uploads with `cancelAllUploads()`.
///
/// - Usage Examples:
///   - **Background Uploads**: Implementations can leverage `URLSessionConfiguration.background` to allow uploads to continue when the app is suspended.
///   - **Progress Tracking**: Provide a closure to monitor how much of the data has been sent, enabling UI updates (e.g., progress bars).
///   - **Error Handling**: Return consistent error types (`NetworkError`) for robust error reporting and recovery mechanisms.
///
/// - Thread Safety:
///   - Implementations should ensure thread-safe operations, particularly when managing upload tasks or shared data structures.
///   - Many operations may occur on background threads. UI updates (e.g., progress indicators) should dispatch back to the main thread.
///
/// - Note:
///   - Large uploads should consider network constraints and may require features like pause/resume or background sessions.
///   - Comprehensive logging and connection checks (e.g., via a `ConnectionMonitor`) can be integrated to handle offline or metered networks.
public protocol UploaderProtocol: AnyObject {
    
    /// Uploads multipart form data to the specified URL.
    ///
    /// - Parameters:
    ///   - url: The target URL for the multipart upload.
    ///   - method: HTTP method to use (e.g., `.post`, `.put`).
    ///   - headers: Optional request headers.
    ///   - progress: Closure for tracking upload progress.
    ///   - multipartFormData: Builder closure for multipart data.
    ///   - completion: Completion handler with decoded response.
    ///
    /// - Returns: `nil`, as the task is internally managed.
    ///
    /// 
    @discardableResult func uploadMultipart<T: Decodable>(to url: URL, method: HTTPMethod, headers: HTTPHeaders?, progress: ((Double) -> Void)?, multipartFormData: @escaping (MultipartFormDataBuilder) throws -> Void, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionUploadTask?
    
    /// Asynchronously uploads multipart form data using `async/await`.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - method: HTTP method (default: `.post`).
    ///   - headers: Optional request headers.
    ///   - progress: Progress callback.
    ///   - multipartFormData: Closure for constructing multipart content.
    ///   - completion: Completion handler with decoded result.
    ///
    /// - Returns: The created upload task or `nil`.
    /// - Throws: Errors during multipart building or request creation.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    @discardableResult func uploadMultipart<T: Decodable>(to url: URL, method: HTTPMethod, headers: HTTPHeaders?, progress: ((Double) -> Void)?, multipartFormData: (MultipartFormDataBuilder) throws -> Void, completion: @escaping (NetworkingResponse<T>) -> Void) async rethrows -> URLSessionUploadTask?
    
    /// Uploads binary data without `async/await`, using a completion-based API.
    ///
    /// - Parameters:
    ///   - url: Upload destination.
    ///   - method: HTTP method to use.
    ///   - data: Raw data to upload.
    ///   - headers: Optional headers.
    ///   - progress: Progress handler.
    ///   - completion: Result callback.
    ///
    /// - Returns: `nil`, since the task is managed internally.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    @discardableResult func uploadRawData<T: Decodable>(to url: URL, method: HTTPMethod, data: Data, headers: HTTPHeaders?, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionUploadTask?

    /// Asynchronously uploads `raw binary data`.
    ///
    /// - Parameters:
    ///   - url: Upload endpoint.
    ///   - method: HTTP method (e.g., `.post`).
    ///   - data: Binary data to send.
    ///   - headers: Optional request headers.
    ///   - progress: Upload progress callback.
    ///   - completion: Completion handler with response.
    ///
    /// - Returns: Upload task or `nil`.
    /// - Throws: If request building or sending fails.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    @discardableResult func uploadRawData<T: Decodable>(to url: URL, method: HTTPMethod, data: Data, headers: HTTPHeaders?, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) async throws -> URLSessionUploadTask?
    
    /// Uploads a local file using a closure-based interface.
    ///
    /// - Parameters:
    ///   - localFileURL: File URL to upload.
    ///   - remoteURL: Target server URL.
    ///   - method: HTTP method to use.
    ///   - headers: Optional headers.
    ///   - progress: Upload progress callback.
    ///   - completion: Upload result.
    ///
    /// - Returns: Always returns `nil`.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    @discardableResult func uploadFile<T: Decodable>(from localFileURL: URL, to remoteURL: URL, method: HTTPMethod, headers: HTTPHeaders?, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionUploadTask?
    
    /// Uploads a file asynchronously from disk.
    ///
    /// - Parameters:
    ///   - localFileURL: File path to upload.
    ///   - remoteURL: Target server.
    ///   - method: HTTP method (default: `.post`).
    ///   - headers: Optional request headers.
    ///   - progress: Upload progress callback.
    ///   - completion: Result handler.
    ///
    /// - Returns: An upload task or `nil`.
    /// - Throws: If request creation or upload fails.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    @discardableResult func uploadFile<T: Decodable>(from localFileURL: URL, to remoteURL: URL, method: HTTPMethod, headers: HTTPHeaders?, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) async throws -> URLSessionUploadTask?
    
    /// Uploads `form-urlencoded` data using closures.
    ///
    /// - Parameters:
    ///   - url: Upload endpoint.
    ///   - method: HTTP method.
    ///   - parameters: Form data key-values.
    ///   - headers: Optional headers.
    ///   - progress: Progress tracker.
    ///   - completion: Completion callback.
    ///
    /// - Returns: Upload task or `nil`.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    @discardableResult func uploadFormURLEncoded<T: Decodable>(to url: URL, method: HTTPMethod, parameters: Parameters, headers: HTTPHeaders?, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionUploadTask?
    
    /// Uploads `form-urlencoded` data asynchronously.
    ///
    /// - Parameters:
    ///   - url: Target server URL.
    ///   - method: HTTP method to use.
    ///   - parameters: Dictionary to be URL-encoded.
    ///   - headers: Optional headers.
    ///   - progress: Upload progress reporter.
    ///   - completion: Result handler.
    ///
    /// - Returns: Upload task or `nil`.
    /// - Throws: On failure during request creation or upload.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    @discardableResult func uploadFormURLEncoded<T: Decodable>(to url: URL, method: HTTPMethod, parameters: Parameters, headers: HTTPHeaders?, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) async throws -> URLSessionUploadTask?
    
    /// Cancels a given upload task.
    ///
    /// - Parameter task: The upload task to cancel.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    func cancelUpload(task: URLSessionTask)
    
    /// Cancels all ongoing uploads.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    func cancelAllUploads()
}

/// `Uploader` is a utility class for managing file uploads using `URLSessionUploadTask`.
///
/// - It supports multiple upload methods, including:
///   - **Raw Data Uploads**: Sending binary data directly.
///   - **Multipart Form-Data**: Uploading multiple files with additional parameters.
///   - **Form-URLEncoded**: Sending key-value pairs in the request body.
///   - **File Uploads**: Uploading large files from disk efficiently.
///
/// - Features:
///   - **Asynchronous Uploads**: Supports **large file uploads** without blocking the main thread.
///   - **Progress Tracking**: Provides real-time progress updates.
///   - **Pause & Resume Support**: Uploads can be paused and resumed when needed.
///   - **Thread Safety**: Uses a dedicated `DispatchQueue` to avoid race conditions.
///   - **Network Awareness**: Prevents uploads when offline using `ConnectionMonitor`.
///
/// - Example Usage:
///   ```swift
///   let sessionConfig = URLSessionConfiguration.default
///   let session = URLSession(configuration: sessionConfig)
///   let logger = NetworkLogger()
///   let connectionMonitor = ConnectionMonitor()
///
///   let uploader = Uploader(session: session, logger: logger, connectionMonitor: connectionMonitor)
///   ```
public class Uploader: NSObject, UploaderProtocol {
        
    /// A dictionary mapping task identifiers to their respective `UploadTaskData`.
    ///
    /// - Key: `task.taskIdentifier` (Unique identifier of the upload task).
    /// - Value: `AnyUploadTaskHandler` containing progress and completion handlers.
    ///
    /// - Thread Safety:
    ///   - Access to this dictionary should always be synchronized using `lockQueue` to avoid race conditions.
    private var activeUploads: [Int: AnyUploadTaskHandler] = [:]
    
    /// A dedicated serial queue used to synchronize access to `activeUploads`.
    ///
    /// This queue ensures all reads and writes to `activeUploads` are thread-safe and serialized,
    /// avoiding concurrent modification issues in multi-threaded environments.
    ///
    /// - Note:
    ///   - Always use `lockQueue.sync` or `lockQueue.async` to access or mutate `activeUploads`.
    ///   - Recommended when updating shared task state (e.g., during upload progress or cleanup).
    private let lockQueue = DispatchQueue(label: "networking.uploader.lock")
    
    /// The internal `URLSession` responsible for managing all upload tasks.
    ///
    /// This session is used to initiate and track `URLSessionUploadTask` instances.
    /// It can be customized at initialization for timeouts, caching policies, or background support.
    ///
    /// - Note:
    ///   - For background uploads, use a `URLSessionConfiguration` with `.background` mode.
    ///   - Should be retained and reused to support session-based behaviors like authentication or task resumption.
    private var urlSession: URLSession?
    
    /// An optional request interceptor used to adapt or retry requests before execution.
    ///
    /// This allows modification of requests before they are sent, such as injecting authentication tokens,
    /// adding query parameters, or implementing custom retry logic.
    ///
    /// - Note:
    ///   - The interceptor must conform to `RequestInterceptor`.
    ///   - Typically used for auth token refresh, logging, or conditional retry behavior.
    private var interceptor: RequestInterceptor?
    
    /// An optional logger instance for capturing detailed information about network traffic.
    ///
    /// Used for logging request lifecycle events including creation, progress, success, and failure.
    /// Can also be used to emit debug or analytics logs throughout the upload process.
    ///
    /// - Note:
    ///   - Logging is useful for debugging, performance analysis, or auditing API interactions.
    ///   - The logger should conform to `NetworkLoggerProtocol`.
    private var logger: NetworkLoggerProtocol?
    
    /// A connection monitor used to observe real-time network availability.
    ///
    /// This is used to check internet connectivity status before initiating uploads,
    /// and may be extended to pause/resume uploads based on network changes.
    ///
    /// - Note:
    ///   - Prevents starting uploads when offline, saving resources and avoiding failed requests.
    ///   - Can integrate with system-level reachability checks or NWPathMonitor.
    private var connectionMonitor: ConnectionMonitor = ConnectionMonitor()
    
    /// Initializes a new `Uploader` instance with custom dependencies for performing upload tasks.
    ///
    /// This initializer configures the uploader with a provided `URLSession`, optional SSL pinning delegate,
    /// request interceptor, logger, and connection monitor. It enables full control over upload behavior,
    /// security, connectivity handling, and diagnostics.
    ///
    /// - Parameters:
    ///   - session: A configured `URLSession` used to execute upload tasks.
    ///              - For background uploads, use `URLSessionConfiguration.background(...)`.
    ///              - The session should be appropriately configured for timeouts, caching, and storage.
    ///
    ///   - pinningDelegate: An optional `PinningURLSessionDelegate` for SSL certificate pinning.
    ///                      - Assign this to enable certificate-based trust validation.
    ///                      - If `nil`, uploads will proceed without additional SSL pinning checks.
    ///
    ///   - interceptor: A `RequestInterceptor` used to modify or adapt requests before uploading.
    ///                  - Useful for authentication, header injection, or retry logic.
    ///
    ///   - logger: An optional `NetworkLogger` to log upload activity, request payloads, responses, and errors.
    ///             - If `nil`, logging is disabled.
    ///
    ///   - connectionMonitor: A `ConnectionMonitor` used to track internet availability.
    ///                        - Prevents initiating uploads when offline.
    ///                        - Can be used to defer or retry uploads intelligently.
    ///
    /// - Note:
    ///   - Uploads executed with a background `URLSession` will continue even when the app is suspended or terminated (if supported).
    ///   - Logging can help debug upload failures or observe request lifecycle events.
    ///   - It is recommended to call this initializer before starting any uploads.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let session = URLSession(configuration: .default)
    ///   let logger = NetworkLogger()
    ///   let monitor = ConnectionMonitor()
    ///
    ///   let uploader = Uploader(
    ///       session: session,
    ///       pinningDelegate: nil,
    ///       interceptor: AuthInterceptor(),
    ///       logger: logger,
    ///       connectionMonitor: monitor
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This initializer is thread-safe but should be invoked on a setup thread (e.g., application launch).
    ///   - The `URLSession` instance should not be shared across unrelated uploaders unless explicitly intended.
    ///   - Ensure consistent configuration of delegates and logger to avoid upload task misbehavior.
    public init(session: URLSession, pinningDelegate: PinningURLSessionDelegate? = nil, interceptor: RequestInterceptor?, logger: NetworkLogger?, connectionMonitor: ConnectionMonitor) {
        /// Initializes the superclass before performing any subclass setup.
        super.init()
        /// Sets the uploader instance as the upload delegate if SSL pinning is enabled.
        pinningDelegate?.uploadDelegate = self
        /// Creates and assigns a `URLSession` configured with the provided session's configuration and delegate.
        self.urlSession = URLSession(configuration: session.configuration, delegate: pinningDelegate, delegateQueue: session.delegateQueue)
        /// Stores the request interceptor to allow request adaptation before upload.
        self.interceptor = interceptor
        /// Assigns the provided `NetworkLogger` for tracking network activity.
        /// This helps with debugging and monitoring upload progress.
        self.logger = logger
        /// Assigns the provided `ConnectionMonitor` to track network connectivity.
        /// Prevents uploads from starting when there is no internet connection.
        self.connectionMonitor = connectionMonitor
    }
    
}

// MARK: - Multipart Upload
extension Uploader {
    
    /// Uploads multipart form data using a synchronous-style API that internally dispatches to an async context.
    ///
    /// This method serves as a bridge between legacy synchronous APIs and Swift's modern concurrency system (`async/await`).
    /// Internally, it launches a new asynchronous `Task` to handle the upload logic, making it suitable for use in non-async contexts
    /// such as delegate methods or UIKit actions.
    ///
    /// - Parameters:
    ///   - url: The `URL` to which the multipart form data will be uploaded.
    ///          - This is typically an API endpoint that accepts file or form uploads (e.g., `https://api.example.com/upload`).
    ///
    ///   - method: The `HTTPMethod` to use for the request (default: `.post`).
    ///             - Common values include `.post` and `.put`, depending on your backend's API specification.
    ///             - Some APIs may reject uploads that do not use the expected method.
    ///
    ///   - headers: Optional `HTTPHeaders` to include in the request, such as authentication tokens or content-type overrides.
    ///              - These headers will be merged with those generated by the multipart form data builder.
    ///              - For example, you might pass `["Authorization": "Bearer <token>"]`.
    ///
    ///   - progress: An optional closure providing **real-time upload progress updates** as a `Double` in the range `0.0...1.0`.
    ///               - Called periodically as data is transferred to the server.
    ///               - Useful for displaying a progress bar or updating UI status.
    ///
    ///   - multipartFormData: A throwing closure that uses `MultipartFormDataBuilder` to construct the multipart payload.
    ///                        - You can append files, text values, and binary data to the form.
    ///                        - If an error is thrown during this phase (e.g., invalid file URL), it will be caught and handled.
    ///
    ///   - completion: A closure that is called after the upload finishes, with a `NetworkingResponse<T>`:
    ///                 - `.success(T)`: Upload succeeded and response data was decoded into type `T`.
    ///                 - `.failure(NetworkError)`: Upload failed due to a network or decoding error.
    ///                 - Called on the main thread by default for safe UI updates.
    ///
    /// - Returns:
    ///   - Always returns `nil`, as the caller is not expected to manage the underlying `URLSessionUploadTask`.
    ///     Upload progress and result are delivered exclusively via the `progress` and `completion` handlers.
    ///
    /// - Note:
    ///   - This method is **not cancelable** since it does not expose the underlying `URLSessionUploadTask`.
    ///     For cancellation or finer control, use the `async` variant of `uploadMultipart(...)`.
    ///   - Errors thrown inside the `multipartFormData` builder or during the async operation will be captured
    ///     and forwarded as a `.failure(.unknown(error))` in the `completion` callback.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   uploader.uploadMultipart(
    ///       to: URL(string: "https://api.example.com/upload")!,
    ///       headers: ["Authorization": "Bearer token"],
    ///       progress: { progress in
    ///           print("Upload progress: \(progress * 100)%")
    ///       },
    ///       multipartFormData: { builder in
    ///           try builder.append(fileURL, withName: "image", fileName: "photo.jpg", mimeType: "image/jpeg")
    ///           try builder.append("john_doe", withName: "username")
    ///       },
    ///       completion: { (response: NetworkingResponse<UploadResultModel>) in
    ///           switch response.result {
    ///           case .success(let value):
    ///               print("Upload successful:", value)
    ///           case .failure(let error):
    ///               print("Upload failed:", error)
    ///           }
    ///       }
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This method is thread-safe and can be invoked from any thread.
    ///   - The internal upload operation is executed asynchronously within a separate `Task`, ensuring that the main thread remains responsive.
    ///   - The `completion` and `progress` callbacks are dispatched on the main thread for UI safety.
    @discardableResult
    public func uploadMultipart<T: Decodable>(to url: URL, method: HTTPMethod = .post, headers: HTTPHeaders? = nil,  progress: ((Double) -> Void)? = nil, multipartFormData: @escaping (MultipartFormDataBuilder) throws -> Void, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionUploadTask? {
        /// Launch an async task immediately to handle the upload operation.
        Task {
            do {
                _ = try await uploadMultipart(
                    to: url,
                    method: method,
                    headers: headers,
                    progress: progress,
                    multipartFormData: multipartFormData,
                    completion: completion
                )
            } catch {
                /// Return a failure response if an error occurs during async upload.
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(
                    request: nil,
                    response: nil,
                    data: nil,
                    result: .failure(.uploadFailed(error))
                )
                completion(networkingResponse)
            }
        }
        /// Caller does not manage the upload task directly.
        return nil
    }
    
    /// Uploads multipart form data as an asynchronous request using Swift concurrency (`async/await`).
    ///
    /// This method constructs a `multipart/form-data` HTTP request that can include both binary files and text fields,
    /// and uploads it to the specified server endpoint. It is suited for submitting files with metadata, form values,
    /// or other structured content using a single HTTP request.
    ///
    /// Internally, the request is executed via `URLSessionUploadTask` and provides closure-based upload progress
    /// and a strongly-typed response model upon completion.
    ///
    /// - Parameters:
    ///   - url: The `URL` to which the multipart form data will be uploaded.
    ///          - Typically a file or media upload endpoint, e.g., `https://api.example.com/upload`.
    ///
    ///   - method: The HTTP method to use (default: `.post`).
    ///             - Acceptable values include `.post` and `.put`, depending on backend API requirements.
    ///
    ///   - headers: Optional headers to include with the request.
    ///              - For example: `Authorization`, `Content-Type`, or any custom backend-specific headers.
    ///              - If provided, these headers will override default values set internally.
    ///
    ///   - progress: A closure called periodically with upload progress as a `Double` from `0.0` to `1.0`.
    ///               - Useful for showing upload progress in UI.
    ///
    ///   - multipartFormData: A throwing closure that configures the multipart form body via `MultipartFormDataBuilder`.
    ///                        - You can append files, key-value fields, binary blobs, and form data.
    ///                        - If an error is thrown, the upload is canceled and the error is passed to `completion`.
    ///
    ///   - completion: A closure invoked after the upload is completed.
    ///                 - Returns a `NetworkingResponse<T>`:
    ///                   - `.success(T)`: If the server returns valid data and decoding succeeds.
    ///                   - `.failure(NetworkError)`: For upload, decoding, or connectivity failures.
    ///
    /// - Returns:
    ///   - A `URLSessionUploadTask?` instance if the upload was successfully initiated; otherwise `nil`.
    ///     - The task begins immediately via `resume()`.
    ///
    /// - Throws:
    ///   - Rethrows any error that occurs while building the multipart form body in `multipartFormData`.
    ///   - Common errors include invalid file paths, data encoding issues, or form construction problems.
    ///
    /// - Note:
    ///   - The request content type is automatically set to `multipart/form-data` with a unique boundary string.
    ///   - Each file must have a valid MIME type (`image/png`, `application/pdf`, etc.) and a proper `fieldName`.
    ///   - This method does not support task cancellation directly; retain and cancel the returned task manually if needed.
    ///   - Always consider backend constraints such as maximum allowed upload size, authentication, and timeout settings.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let task = try await uploader.uploadMultipart(
    ///       to: URL(string: "https://api.example.com/upload")!,
    ///       headers: ["Authorization": "Bearer token"],
    ///       progress: { progress in
    ///           print("Upload progress: \(progress * 100)%")
    ///       },
    ///       multipartFormData: { builder in
    ///           try builder.append(fileURL, withName: "image", fileName: "photo.jpg", mimeType: "image/jpeg")
    ///           try builder.append("john_doe", withName: "username")
    ///       },
    ///       completion: { (response: NetworkingResponse<UploadResponseModel>) in
    ///           switch response.result {
    ///           case .success(let result):
    ///               print("Upload succeeded:", result)
    ///           case .failure(let error):
    ///               print("Upload failed:", error)
    ///           }
    ///       }
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Thread-safe. Internal state (`activeUploads`) is protected using a dedicated `DispatchQueue`.
    ///   - The `progress` and `completion` closures may be called on a background thread. Ensure UI updates happen on the main thread.
    ///   - This function can safely be called from any thread; the upload itself is handled asynchronously.
    @discardableResult
    public func uploadMultipart<T: Decodable>(to url: URL, method: HTTPMethod = .post, headers: HTTPHeaders? = nil, progress: ((Double) -> Void)?, multipartFormData: (MultipartFormDataBuilder) throws -> Void, completion: @escaping (NetworkingResponse<T>) -> Void) async rethrows -> URLSessionUploadTask? {
        /// Log starting multipart upload
        logger?.logMessage(message: "Starting multipart upload to: \(url.absoluteString)", level: .info, logPrivacy: .public)
        /// Check if the device has an active internet connection before proceeding with the network request.
        if !connectionMonitor.isReachable {
            logger?.logMessage(message: "No internet connection — multipart upload aborted.", level: .error, logPrivacy: .public)
            /// If the device is offline, throw a `NetworkError.noInternetConnection` error.
            /// This prevents unnecessary network calls and allows the caller to handle offline scenarios gracefully.
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.noInternetConnection))
            completion(networkingResponse)
            return nil
        }
        /// Generate the request body
        let builder = MultipartFormDataBuilder()
        try multipartFormData(builder)
        let (bodyData, boundary) = builder.finalize()
        /// Create an HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        /// Set custom headers if provided
        if let headers = headers?.dictionary {
            headers.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        /// If an interceptor is available, adapt the request before execution.
        if let interceptor {
            do   {
                request = try await interceptor.adapt(request)
            } catch {
                let response = NetworkingResponse<T>(request: request,
                                                     response: nil,
                                                     data: nil,
                                                     result: .failure(.uploadFailed(error)))
                completion(response)
                return nil
            }
        }
        /// Create an upload task with the generated request and body
        guard let task = urlSession?.uploadTask(with: request, from: bodyData) else {
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: nil, data: nil, result: .failure(.uploadFailed(nil)))
            completion(networkingResponse)
            return nil
        }
        /// Store task data for tracking progress and completion
        let taskHandler = UploadTaskHandler<T>(progress: progress, completion: completion)
        /// Ensure thread safety while modifying `activeUploads`
        lockQueue.sync {
            activeUploads[task.taskIdentifier] = taskHandler
        }
        /// Log created upload task
        logger?.logMessage(message: "Multipart upload task created (ID: \(task.taskIdentifier))", level: .debug, logPrivacy: .public)
        /// Start the upload task
        task.resume()
        logger?.logMessage(message: "Multipart upload task (ID: \(task.taskIdentifier)) started.", level: .debug, logPrivacy: .public)
        return task
    }
    
}

// MARK: - Raw Data Upload
extension Uploader {
    
    /// Uploads raw binary data using a synchronous-style API that internally dispatches to an async context.
    ///
    /// This method acts as a compatibility layer for codebases that cannot use Swift's `async/await` syntax directly.
    /// Internally, it starts an asynchronous task to perform the upload using `uploadRawData(...)`.
    /// The upload progress and result are reported through closure-based handlers, making it ideal for UIKit delegates and legacy code.
    ///
    /// - Parameters:
    ///   - url: The `URL` to which the binary data will be uploaded.
    ///          - Should point to a valid server endpoint accepting raw uploads.
    ///
    ///   - method: The HTTP method to use (default: `.post`).
    ///             - Usually `.post` or `.put`, depending on backend API requirements.
    ///
    ///   - data: The raw binary `Data` to be uploaded.
    ///           - Typically read from disk (e.g., file contents) or generated in memory.
    ///
    ///   - headers: Optional `HTTPHeaders` to include in the request.
    ///              - Useful for setting authentication, content type overrides, etc.
    ///
    ///   - progress: An optional closure reporting upload progress as a `Double` (0.0...1.0).
    ///               - Called periodically throughout the upload.
    ///
    ///   - completion: A closure called upon completion, returning a `NetworkingResponse<T>`:
    ///                 - `.success(T)`: The decoded server response.
    ///                 - `.failure(NetworkError)`: Indicates a transport, decoding, or adaptation error.
    ///
    /// - Returns:
    ///   - Always returns `nil`, as the internal task is handled asynchronously within a `Task`.
    ///     Use the `completion` and `progress` closures to observe status and result.
    ///
    /// - Note:
    ///   - This method is intended for use in environments that do not support `async/await` directly.
    ///     For full control and task cancellation, use the `async` variant instead.
    ///   - Errors thrown during async execution will be caught and transformed into a `.failure(.uploadFailed(...))` result.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   uploader.uploadRawData(
    ///       to: URL(string: "https://api.example.com/file")!,
    ///       data: myData,
    ///       headers: ["Authorization": "Bearer token"],
    ///       progress: { progress in
    ///           print("Progress: \(progress * 100)%")
    ///       },
    ///       completion: { (response: NetworkingResponse<MyModel>) in
    ///           switch response.result {
    ///           case .success(let model):
    ///               print("Upload succeeded:", model)
    ///           case .failure(let error):
    ///               print("Upload failed:", error)
    ///           }
    ///       }
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Safe to call from any thread.
    ///   - The internal `Task` runs asynchronously; progress and completion closures may be called from background threads.
    ///     Dispatch back to the main thread for any UI updates.
    @discardableResult
    public func uploadRawData<T: Decodable>(to url: URL, method: HTTPMethod = .post, data: Data, headers: HTTPHeaders? = nil, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionUploadTask? {
        /// Launch an async task immediately to handle the upload operation.
        Task {
            do {
                _ = try await uploadRawData(
                    to: url,
                    method: method,
                    data: data,
                    headers: headers,
                    progress: progress,
                    completion: completion
                )
            } catch {
                /// Return a failure response if an error occurs during async upload.
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(
                    request: nil,
                    response: nil,
                    data: nil,
                    result: .failure(.uploadFailed(error))
                )
                completion(networkingResponse)
            }
        }
        /// Caller does not manage the upload task directly.
        return nil
    }
    
    /// Asynchronously uploads raw binary data to a specified server endpoint.
    ///
    /// This method is ideal for uploading a single binary file (e.g., image, video, PDF) without any additional form fields.
    /// It sends the data directly using the `application/octet-stream` content type, and manages the request through a `URLSessionUploadTask`.
    /// Suitable for modern Swift concurrency usage via `async/await`.
    ///
    /// - Parameters:
    ///   - url: The `URL` to which the binary data will be uploaded.
    ///          - This should point to a server endpoint capable of handling raw uploads.
    ///
    ///   - method: The HTTP method to use for the upload (default: `.post`).
    ///             - Common values include `.post` and `.put`, depending on API design.
    ///
    ///   - data: The raw binary `Data` to upload.
    ///           - Typically read from disk or generated in-memory (e.g., image compression output).
    ///
    ///   - headers: Optional `HTTPHeaders` dictionary for authentication, custom content-type, etc.
    ///              - These headers will override the default `Content-Type` if provided explicitly.
    ///
    ///   - progress: An optional closure that reports upload progress as a `Double` in the range `0.0...1.0`.
    ///               - Use this to drive progress bars or background activity indicators.
    ///
    ///   - completion: A closure called when the upload completes, returning a `NetworkingResponse<T>`:
    ///                 - `.success(T)`: If the server returns a valid response and it is successfully decoded.
    ///                 - `.failure(NetworkError)`: If a network, decoding, or connection error occurs.
    ///
    /// - Returns:
    ///   - A `URLSessionUploadTask?` representing the upload task if it was successfully started.
    ///     Returns `nil` if the request could not be constructed or network prerequisites failed.
    ///
    /// - Note:
    ///   - The `Content-Type` is set to `application/octet-stream` by default.
    ///     This is suitable for binary payloads such as:
    ///     - `.jpg`, `.png`, `.gif` (images)
    ///     - `.pdf`, `.docx`, `.zip` (documents)
    ///     - `.mp4`, `.mov` (videos)
    ///   - This method does **not** support sending additional form fields. Use `uploadMultipart(...)` for that case.
    ///   - Uploads cannot be resumed if interrupted (`resumeData` is not available for raw uploads).
    ///   - The `@discardableResult` annotation allows the task to be ignored if return value is not needed.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let fileData = try Data(contentsOf: imageURL)
    ///
    ///   let task = try await uploader.uploadRawData(
    ///       to: URL(string: "https://api.example.com/upload")!,
    ///       method: .put,
    ///       data: fileData,
    ///       headers: ["Authorization": "Bearer token"],
    ///       progress: { progress in
    ///           print("Upload progress: \(progress * 100)%")
    ///       },
    ///       completion: { (response: NetworkingResponse<UploadResult>) in
    ///           switch response.result {
    ///           case .success(let result):
    ///               print("Upload successful: \(result)")
    ///           case .failure(let error):
    ///               print("Upload failed: \(error)")
    ///           }
    ///       }
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Safe to call from any async context (e.g., view models, background tasks).
    ///   - Internal state (such as `activeUploads`) is protected via locking mechanisms.
    ///   - `progress` and `completion` closures may be called on background threads; dispatch to main thread for UI updates.
    @discardableResult
    public func uploadRawData<T: Decodable>(to url: URL, method: HTTPMethod = .post, data: Data, headers: HTTPHeaders? = nil, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) async throws -> URLSessionUploadTask? {
        logger?.logMessage(message: "Starting raw data upload to: \(url.absoluteString)", level: .info, logPrivacy: .public)
        /// Check if the device has an active internet connection before proceeding with the network request.
        if !connectionMonitor.isReachable {
            logger?.logMessage(message: "No internet connection — raw data upload aborted.", level: .error, logPrivacy: .public)
            /// If the device is offline, throw a `NetworkError.noInternetConnection` error.
            /// This prevents unnecessary network calls and allows the caller to handle offline scenarios gracefully.
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.noInternetConnection))
            completion(networkingResponse)
            return nil
        }
        /// Create an HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        /// Set custom headers if provided
        if let headers = headers?.dictionary {
            headers.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        /// If an interceptor is available, adapt the request before execution.
        if let interceptor {
            do   {
                request = try await interceptor.adapt(request)
            } catch {
                let response = NetworkingResponse<T>(request: request,
                                                     response: nil,
                                                     data: nil,
                                                     result: .failure(.uploadFailed(error)))
                completion(response)
                return nil
            }
        }
        /// Create an upload task with the request and raw data
        guard let task = urlSession?.uploadTask(with: request, from: data) else {
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: nil, data: nil, result: .failure(.uploadFailed(nil)))
            completion(networkingResponse)
            return nil
        }
        /// Store task data for tracking progress and completion
        let taskHandler = UploadTaskHandler<T>(progress: progress, completion: completion)
        /// Ensure thread safety while modifying `activeUploads`
        lockQueue.sync {
            activeUploads[task.taskIdentifier] = taskHandler
        }
        logger?.logMessage(message: "Raw data upload task created (ID: \(task.taskIdentifier))", level: .debug, logPrivacy: .public)
        /// Start the upload task
        task.resume()
        logger?.logMessage(message: "Raw data upload task (ID: \(task.taskIdentifier)) started.", level: .debug, logPrivacy: .public)
        return task
    }
    
}

// MARK: - File (Local URL) Upload
extension Uploader {
    
    /// Uploads a file from disk using a synchronous-style API that internally performs the operation asynchronously.
    ///
    /// This method wraps the async version of `uploadFile(...)` inside a `Task`, allowing use in contexts that do not support `async/await`.
    /// It streams the file directly from a local URL to the server using a `URLSessionUploadTask`, making it ideal for large files that should not be loaded into memory.
    /// Result and progress updates are delivered via closure-based callbacks.
    ///
    /// - Parameters:
    ///   - localFileURL: The `URL` of the file on disk to be uploaded.
    ///                   - The file must exist at this location and be accessible.
    ///
    ///   - remoteURL: The server endpoint to which the file will be uploaded.
    ///                - Typically a REST API endpoint designed to receive media, documents, or assets.
    ///
    ///   - method: The HTTP method to use (default: `.post`).
    ///             - `.post` or `.put` are generally used for file uploads.
    ///
    ///   - headers: Optional HTTP headers to include in the request.
    ///              - Useful for authorization, content type overrides, or custom backend requirements.
    ///
    ///   - progress: An optional closure reporting upload progress as a `Double` between `0.0` and `1.0`.
    ///               - Can be used to update progress bars or track network activity.
    ///
    ///   - completion: A closure returning a `NetworkingResponse<T>`:
    ///                 - `.success(T)`: Upload completed and response decoded successfully.
    ///                 - `.failure(NetworkError)`: Upload failed or the server response could not be decoded.
    ///
    /// - Returns:
    ///   - Always returns `nil`, as the underlying task is managed internally by an `async` `Task`.
    ///     - The result must be handled through the `completion` closure.
    ///
    /// - Note:
    ///   - This method is useful in UIKit or Combine-based systems that are not yet fully `async/await`-enabled.
    ///   - Errors thrown during the upload will be caught and returned via the `completion` closure as `.failure(.uploadFailed(error))`.
    ///   - This is a memory-efficient approach since it streams the file directly from disk.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   uploader.uploadFile(
    ///       from: fileURL,
    ///       to: URL(string: "https://api.example.com/upload")!,
    ///       headers: ["Authorization": "Bearer token"],
    ///       progress: { progress in
    ///           print("Upload progress: \(progress * 100)%")
    ///       },
    ///       completion: { (response: NetworkingResponse<MyResponseModel>) in
    ///           switch response.result {
    ///           case .success(let result):
    ///               print("Upload succeeded:", result)
    ///           case .failure(let error):
    ///               print("Upload failed:", error)
    ///           }
    ///       }
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Safe to invoke from any thread.
    ///   - Underlying `Task` executes asynchronously in the background.
    ///   - Ensure UI updates in `progress` and `completion` closures are dispatched to the main thread when needed.
    @discardableResult
    public func uploadFile<T: Decodable>(from localFileURL: URL, to remoteURL: URL, method: HTTPMethod = .post, headers: HTTPHeaders? = nil, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionUploadTask? {
        /// Launch an async task immediately to handle the upload operation.
        Task {
            do {
                _ = try await uploadFile(
                    from: localFileURL,
                    to: remoteURL,
                    method: method,
                    headers: headers,
                    progress: progress,
                    completion: completion
                )
            } catch {
                /// Return a failure response if an error occurs during async upload.
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(
                    request: nil,
                    response: nil,
                    data: nil,
                    result: .failure(.uploadFailed(error))
                )
                completion(networkingResponse)
            }
        }
        /// Caller does not manage the upload task directly.
        return nil
    }
    
    /// Uploads a file directly from a local file URL to a remote server using an asynchronous API.
    ///
    /// This method streams the file directly from disk using `URLSessionUploadTask`, allowing you to upload large files efficiently without loading them into memory.
    /// It is well-suited for file uploads in high-performance or memory-sensitive applications, such as sending videos, documents, or images.
    ///
    /// - Parameters:
    ///   - localFileURL: The local file system `URL` of the file to be uploaded.
    ///                   - The file must exist and be readable at this path.
    ///
    ///   - remoteURL: The server-side endpoint (`URL`) to which the file should be uploaded.
    ///                - Typically a REST API URL accepting PUT or POST uploads.
    ///
    ///   - method: The `HTTPMethod` used for the upload (default: `.post`).
    ///             - Accepted values typically include `.post` and `.put`.
    ///
    ///   - headers: Optional HTTP headers to include with the request.
    ///              - These can override default values like `Content-Type`.
    ///              - Common headers include `Authorization`, `Content-Length`, or `X-API-Key`.
    ///
    ///   - progress: An optional closure reporting upload progress as a `Double` (0.0...1.0).
    ///               - This can be used to drive progress bars or display transfer stats.
    ///
    ///   - completion: A closure called when the upload finishes, returning a `NetworkingResponse<T>`:
    ///                 - `.success(T)`: Indicates the response was decoded successfully.
    ///                 - `.failure(NetworkError)`: Indicates that the upload failed or the response was invalid.
    ///
    /// - Returns:
    ///   - A `URLSessionUploadTask?` instance if the upload is successfully started; otherwise `nil`.
    ///     - You may store the returned task for potential cancellation.
    ///
    /// - Note:
    ///   - The file is streamed directly from disk, making this more memory-efficient than converting to `Data`.
    ///   - If the upload is interrupted, it **cannot be resumed** (no `resumeData` support for `fromFile:` API).
    ///   - MIME type can be inferred or set manually via headers (e.g., `video/mp4`, `application/pdf`).
    ///   - Suitable for:
    ///     - Large media files: `.mp4`, `.mov`, `.avi`
    ///     - High-res images: `.png`, `.jpg`
    ///     - Documents: `.pdf`, `.docx`, `.zip`
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let task = try await uploader.uploadFile(
    ///       from: fileURL,
    ///       to: URL(string: "https://api.example.com/upload")!,
    ///       headers: ["Authorization": "Bearer token"],
    ///       progress: { percent in
    ///           print("Progress: \(percent * 100)%")
    ///       },
    ///       completion: { (response: NetworkingResponse<UploadResult>) in
    ///           switch response.result {
    ///           case .success(let result):
    ///               print("Upload successful:", result)
    ///           case .failure(let error):
    ///               print("Upload failed:", error)
    ///           }
    ///       }
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Can be safely invoked from any thread.
    ///   - The `activeUploads` dictionary is accessed within a locked `DispatchQueue`.
    ///   - `progress` and `completion` closures may be called on a background thread; dispatch to the main thread if needed for UI updates.
    @discardableResult
    public func uploadFile<T: Decodable>(from localFileURL: URL, to remoteURL: URL, method: HTTPMethod = .post, headers: HTTPHeaders? = nil, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) async throws -> URLSessionUploadTask? {
        logger?.logMessage(message: "Starting file upload from: \(localFileURL.path) to: \(remoteURL.absoluteString)", level: .info, logPrivacy: .public)
        /// Check if the device has an active internet connection before proceeding with the network request.
        if !connectionMonitor.isReachable {
            logger?.logMessage(message: "No internet connection — file upload aborted.", level: .error, logPrivacy: .public)
            /// If the device is offline, throw a `NetworkError.noInternetConnection` error.
            /// This prevents unnecessary network calls and allows the caller to handle offline scenarios gracefully.
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.noInternetConnection))
            completion(networkingResponse)
            return nil
        }
        /// Create an HTTP request
        var request = URLRequest(url: remoteURL)
        request.httpMethod = method.rawValue
        /// Content type (e.g., video/mp4, image/png, etc.) or custom
        /// You can set it as a constant or pass it as a parameter
        /// request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        /// Set custom headers if provided
        if let headers = headers?.dictionary {
            headers.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        /// If an interceptor is available, adapt the request before execution.
        if let interceptor {
            do   {
                request = try await interceptor.adapt(request)
            } catch {
                let response = NetworkingResponse<T>(request: request,
                                                     response: nil,
                                                     data: nil,
                                                     result: .failure(.uploadFailed(error)))
                completion(response)
                return nil
            }
        }
        /// Create an upload task with the file URL
        guard let task = urlSession?.uploadTask(with: request, fromFile: localFileURL) else {
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: nil, data: nil, result: .failure(.uploadFailed(nil)))
            completion(networkingResponse)
            return nil
        }
        /// Store task data for tracking progress and completion
        let taskHandler = UploadTaskHandler<T>(progress: progress, completion: completion)
        /// Ensure thread safety while modifying `activeUploads`
        lockQueue.sync {
            activeUploads[task.taskIdentifier] = taskHandler
        }
        logger?.logMessage(message: "File upload task created (ID: \(task.taskIdentifier))", level: .debug, logPrivacy: .public)
        /// Start the upload task
        task.resume()
        logger?.logMessage(message: "File upload task (ID: \(task.taskIdentifier)) started.", level: .debug, logPrivacy: .public)
        return task
    }
    
}

// MARK: - Upload with `x-www-form-urlencoded Upload`
extension Uploader {
    
    /// Uploads form-encoded data using a synchronous-style interface that internally performs an async upload.
    ///
    /// This method wraps the async `uploadFormURLEncoded(...)` function in a `Task`, allowing compatibility with non-async code.
    /// It encodes the given parameters as `application/x-www-form-urlencoded` and sends them in the body of an HTTP request.
    /// Result and progress are reported through closures, making this ideal for UIKit-based apps or legacy codebases.
    ///
    /// - Parameters:
    ///   - url: The endpoint `URL` to which the form data will be submitted.
    ///          - Typically used for login, search, filtering, or simple form submissions.
    ///
    ///   - method: The HTTP method to use for the request (default: `.post`).
    ///             - Common values include `.post` and `.put`.
    ///
    ///   - parameters: A dictionary of form fields to be encoded in the HTTP body.
    ///                 - Values will be stringified and percent-encoded for compatibility with URL encoding standards.
    ///
    ///   - headers: Optional HTTP headers to include in the request.
    ///              - Examples: `Authorization`, `Accept-Language`, `X-Client-Version`.
    ///
    ///   - progress: An optional closure called periodically with upload progress as a `Double` from `0.0` to `1.0`.
    ///               - Use this to reflect progress in UI elements.
    ///
    ///   - completion: A closure that is invoked when the upload finishes.
    ///                 - Returns a `NetworkingResponse<T>`:
    ///                   - `.success(T)`: The server response was successfully decoded.
    ///                   - `.failure(NetworkError)`: An error occurred during the request or decoding.
    ///
    /// - Returns:
    ///   - Always returns `nil`, as the actual `URLSessionUploadTask` is encapsulated inside an async `Task`.
    ///     - Use `completion` and `progress` to monitor the result and status.
    ///
    /// - Note:
    ///   - This is a memory-efficient alternative to multipart form uploads, ideal for small payloads and form-style data.
    ///   - Parameters are serialized to `key=value&key2=value2` and percent-encoded automatically.
    ///   - Use this method in situations where `async/await` is not yet supported or not ideal (e.g., UIKit actions, delegates).
    ///
    /// - Example Usage:
    ///   ```swift
    ///   uploader.uploadFormURLEncoded(
    ///       to: URL(string: "https://api.example.com/auth")!,
    ///       parameters: [
    ///           "email": "user@example.com",
    ///           "password": "securepass123"
    ///       ],
    ///       headers: ["Authorization": "Bearer token"],
    ///       progress: { progress in
    ///           print("Progress: \(progress * 100)%")
    ///       },
    ///       completion: { (response: NetworkingResponse<LoginResponse>) in
    ///           switch response.result {
    ///           case .success(let token):
    ///               print("Authenticated:", token)
    ///           case .failure(let error):
    ///               print("Auth failed:", error)
    ///           }
    ///       }
    ///   )
    ///   ```
    @discardableResult
    public func uploadFormURLEncoded<T: Decodable>(to url: URL, method: HTTPMethod = .post, parameters: Parameters, headers: HTTPHeaders? = nil, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionUploadTask? {
        /// Launch an async task immediately to handle the upload operation.
        Task {
            do {
                _ = try await uploadFormURLEncoded(
                    to: url,
                    method: method,
                    parameters: parameters,
                    headers: headers,
                    progress: progress,
                    completion: completion
                )
            } catch {
                /// Return a failure response if an error occurs during async upload.
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(
                    request: nil,
                    response: nil,
                    data: nil,
                    result: .failure(.uploadFailed(error))
                )
                completion(networkingResponse)
            }
        }
        /// Caller does not manage the upload task directly.
        return nil
    }
    
    /// Uploads URL-encoded form parameters using an asynchronous HTTP request.
    ///
    /// This method encodes key-value pairs as `application/x-www-form-urlencoded` content
    /// and sends them in the HTTP body. It is ideal for submitting form-like data to APIs,
    /// especially in situations where the payload does not include files or binary content.
    ///
    /// - Parameters:
    ///   - url: The server `URL` to which the form data will be submitted.
    ///          - Typically a login, registration, or API submission endpoint.
    ///
    ///   - method: The HTTP method used to send the form data (default: `.post`).
    ///             - Common values include `.post` and `.put`, depending on the API’s expectations.
    ///
    ///   - parameters: A dictionary of form fields to be encoded as a query string.
    ///                 - Values are automatically converted to their string representations and percent-encoded.
    ///
    ///   - headers: Optional `HTTPHeaders` to include with the request.
    ///              - Can be used for authentication or other custom headers.
    ///              - Any provided `Content-Type` here will override the default form encoding.
    ///
    ///   - progress: An optional closure reporting upload progress as a `Double` between `0.0` and `1.0`.
    ///               - Suitable for updating progress indicators in UI.
    ///
    ///   - completion: A closure called when the request finishes.
    ///                 - Returns a `NetworkingResponse<T>` where:
    ///                   - `.success(T)`: The response was successfully decoded into the target type.
    ///                   - `.failure(NetworkError)`: An error occurred during the request or decoding.
    ///
    /// - Returns:
    ///   - A `URLSessionUploadTask?` instance representing the underlying upload request, or `nil` if the task could not be created.
    ///
    /// - Note:
    ///   - This method is designed for simple key-value submission and **does not support file uploads**.
    ///   - All parameters are percent-encoded and concatenated into the request body (`key1=value1&key2=value2`).
    ///   - Special characters such as `=`, `&`, and spaces will be properly encoded to avoid server-side parsing issues.
    ///   - The default `Content-Type` is `application/x-www-form-urlencoded`, but you may override it via `headers`.
    ///   - The request is sent using `URLSessionUploadTask` and begins immediately after creation via `resume()`.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let task = try await uploader.uploadFormURLEncoded(
    ///       to: URL(string: "https://api.example.com/login")!,
    ///       parameters: [
    ///           "username": "john.doe",
    ///           "password": "s3cr3t"
    ///       ],
    ///       headers: ["Authorization": "Bearer token"],
    ///       progress: { percent in
    ///           print("Progress: \(percent * 100)%")
    ///       },
    ///       completion: { (response: NetworkingResponse<AuthToken>) in
    ///           switch response.result {
    ///           case .success(let token):
    ///               print("Login successful:", token)
    ///           case .failure(let error):
    ///               print("Login failed:", error)
    ///           }
    ///       }
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This method is safe to invoke from any thread.
    ///   - Shared state (such as `activeUploads`) is accessed via a synchronization queue.
    ///   - The `progress` and `completion` closures may be called on background threads; dispatch to the main thread when updating UI.
    @discardableResult
    public func uploadFormURLEncoded<T: Decodable>(to url: URL, method: HTTPMethod = .post, parameters: Parameters, headers: HTTPHeaders? = nil, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) async throws -> URLSessionUploadTask? {
        logger?.logMessage(message: "Starting form-urlencoded upload to: \(url.absoluteString)", level: .info, logPrivacy: .public)
        /// Check if the device has an active internet connection before proceeding with the network request.
        if !connectionMonitor.isReachable {
            logger?.logMessage(message: "No internet connection — form-urlencoded upload aborted.", level: .error, logPrivacy: .public)
            /// If the device is offline, throw a `NetworkError.noInternetConnection` error.
            /// This prevents unnecessary network calls and allows the caller to handle offline scenarios gracefully.
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.noInternetConnection))
            completion(networkingResponse)
            return nil
        }
        /// Create an HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        /// Set custom headers if provided
        if let headers = headers?.dictionary {
            headers.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        /// If an interceptor is available, adapt the request before execution.
        if let interceptor {
            do   {
                request = try await interceptor.adapt(request)
            } catch {
                let response = NetworkingResponse<T>(request: request,
                                                     response: nil,
                                                     data: nil,
                                                     result: .failure(.uploadFailed(error)))
                completion(response)
                return nil
            }
        }
        /// Encode parameters into a URL-encoded string
        let encodedString = parameters.map { "\($0)=\($1)" }.joined(separator: "&")
        let data = encodedString.data(using: .utf8) ?? Data()
        /// Create an upload task with the request and encoded data
        guard let task = urlSession?.uploadTask(with: request, from: data) else {
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: nil, data: nil, result: .failure(.uploadFailed(nil)))
            completion(networkingResponse)
            return nil
        }
        /// Store task data for tracking progress and completion
        let taskHandler = UploadTaskHandler<T>(progress: progress, completion: completion)
        /// Ensure thread safety while modifying `activeUploads`
        lockQueue.sync {
            activeUploads[task.taskIdentifier] = taskHandler
        }
        logger?.logMessage(message: "Form-urlencoded upload task created (ID: \(task.taskIdentifier))", level: .debug, logPrivacy: .public)
        /// Start the upload task
        task.resume()
        logger?.logMessage(message: "Form-urlencoded upload task (ID: \(task.taskIdentifier)) started.", level: .debug, logPrivacy: .public)
        return task
    }
    
}

// MARK: - Cancel
extension Uploader {
    
    /// Cancels an ongoing upload task.
    ///
    /// - This method stops an active `URLSessionUploadTask` that is currently in progress.
    /// - If the task supports **resume data**, it may be possible to restart the upload from where it left off.
    /// - The upload task is removed from `activeUploads` once canceled.
    ///
    /// - Parameter task: The `URLSessionTask` representing the upload task to be canceled.
    ///
    /// - Note:
    ///   - If the server supports **resume data**, canceling the task **may** generate `resumeData`,
    ///     which can be used to restart the upload later.
    ///   - If **resuming is needed**, consider using `pauseUpload(task:completion:)` instead of canceling.
    ///   - Tasks that do **not** support resumable uploads will be **completely stopped** and must restart from scratch.
    ///   - This method ensures **thread-safe access** to `activeUploads` using `lockQueue`.
    ///
    /// - Thread Safety:
    ///   - The method locks `activeUploads` using `lockQueue.sync` to prevent race conditions.
    public func cancelUpload(task: URLSessionTask) {
        logger?.logMessage(message: "Canceling upload task (ID: \(task.taskIdentifier))", level: .info, logPrivacy: .public)
        task.cancel()
        /// Ensures thread-safe access to `activeUploads` using `lockQueue`.
        lockQueue.sync {
            _ = activeUploads.removeValue(forKey: task.taskIdentifier)
        }
    }
    
    /// Cancels all ongoing upload tasks.
    ///
    /// - This method stops all active uploads managed by the `Uploader`.
    /// - If the upload tasks support **resume data**, consider using `pauseUpload()` instead of canceling them.
    /// - Any in-progress uploads will be removed from `activeUploads`.
    ///
    /// - Note:
    ///   - If the server supports **resume data**, canceling an upload **may** generate `resumeData`,
    ///     which can be used to restart the upload later.
    ///   - Uploads that do **not** support resumable transfers will be **completely lost**, requiring a full restart.
    ///   - Progress handlers for ongoing uploads will no longer receive updates.
    ///   - This method ensures **thread-safe access** to `activeUploads` using `lockQueue`.
    ///
    /// - Thread Safety:
    ///   - The method locks `activeUploads` using `lockQueue.sync` to prevent race conditions.
    public func cancelAllUploads() {
        logger?.logMessage(message: "Canceling ALL ongoing uploads.", level: .info, logPrivacy: .public)
        lockQueue.sync {
            /// Fetch all tasks currently running in the session.
            urlSession?.getAllTasks(completionHandler: { tasks in
                /// Filters tasks that match `activeUploads`.
                let results = zip(tasks, self.activeUploads).enumerated().filter() {
                    $1.0.taskIdentifier == $1.1.key
                }
                /// Cancels each matched task.
                results.forEach { result in
                    let task = result.element.0
                    task.cancel()
                    self.logger?.logMessage(message: "Canceled upload task (ID: \(task.taskIdentifier))", level: .debug, logPrivacy: .public)
                }
            })
            /// Clears all stored active uploads.
            activeUploads.removeAll()
        }
    }
    
}

// MARK: - URLSessionTaskDelegate & URLSessionDataDelegate
extension Uploader: URLSessionTaskDelegate, URLSessionDataDelegate {
    
    /// Reports the progress of an upload task as data is being sent.
    ///
    /// - This method is called periodically while an upload task is in progress.
    /// - It calculates the percentage of data uploaded and logs the progress.
    /// - If a progress handler exists for the task, it is invoked with the current progress value.
    ///
    /// - Parameters:
    ///   - session: The `URLSession` handling the upload task.
    ///   - task: The `URLSessionTask` that is currently uploading data.
    ///   - bytesSent: The number of bytes sent since the last progress update.
    ///   - totalBytesSent: The total number of bytes sent so far.
    ///   - totalBytesExpectedToSend: The expected total size of the file being uploaded.
    ///
    /// - Note:
    ///   - This method only tracks progress if `totalBytesExpectedToSend > 0`, meaning the server has provided the content length.
    ///   - The progress value is a fraction between `0.0` and `1.0`, representing the percentage uploaded.
    ///   - The progress is logged and, if available, passed to the registered `progressHandler` for UI updates.
    ///
    /// - Thread Safety:
    ///   - The `lockQueue.sync` block ensures **thread-safe access** to `activeUploads`.
    ///   - This prevents race conditions when updating progress.
    ///
    /// - UI Considerations:
    ///   - This method may be called from a background thread.
    ///   - Ensure that UI updates (e.g., updating a progress bar) are dispatched to the main thread.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        /// Ensure this session is valid and totalBytesExpectedToSend is available.
        guard
            session == urlSession,
            totalBytesExpectedToSend > 0
        else {
            return
        }
        /// Calculate progress percentage.
        let progressValue = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        /// Log progress
        logger?.logMessage(message: "Upload progress for task (ID: \(task.taskIdentifier)): \(progressValue * 100)%", level: .debug, logPrivacy: .public)
        /// Call the associated `progressHandler` from `activeUploads`.
        lockQueue.sync {
            if let info = activeUploads[task.taskIdentifier] {
                info.progressHandler?(progressValue)
            }
        }
    }
    
    /// Called when new data is received for a data task.
    ///
    /// - This method is invoked multiple times as data is received from the server in chunks.
    /// - The received data is typically accumulated until the full response is available.
    /// - If the corresponding task has an associated completion handler, the accumulated data is passed to it.
    ///
    /// - Parameters:
    ///   - session: The `URLSession` handling the data task.
    ///   - dataTask: The `URLSessionDataTask` that received the data.
    ///   - data: A `Data` object containing the newly received chunk of data.
    ///
    /// - Note:
    ///   - This method is **not** called for `URLSessionDownloadTask` (which writes data to a file instead).
    ///   - The data received here should be **appended** to a buffer if a complete response is expected.
    ///   - If handling large responses, consider **streaming** data instead of storing it in memory.
    ///
    /// - Thread Safety:
    ///   - The method should be called in a **thread-safe manner**, especially when modifying shared state.
    ///   - If updating a shared dictionary (e.g., `activeUploads`), ensure **synchronized access**.
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        /// Ensure this session is valid.
        guard session == urlSession else {
            return
        }
        /// Append received data to the corresponding upload task.
        lockQueue.sync {
            activeUploads[dataTask.taskIdentifier]?.append(data)
        }
    }
    
    /// Called when a task completes, either successfully or with an error.
    ///
    /// - This method is triggered when a `URLSessionTask` finishes execution.
    /// - It determines if the task completed successfully or failed due to an error.
    /// - If an error occurred, it logs the error and invokes the associated completion handler with a failure result.
    ///
    /// - Parameters:
    ///   - session: The `URLSession` handling the task.
    ///   - task: The `URLSessionTask` that has completed execution.
    ///   - error: An optional `Error` object containing details of the failure, or `nil` if the task completed successfully.
    ///
    /// - Note:
    ///   - This method is called **for all types of tasks** (`URLSessionDataTask`, `URLSessionUploadTask`, `URLSessionDownloadTask`).
    ///   - If an error is present, the task has **failed**, and appropriate recovery actions should be considered.
    ///   - If the task was **successful**, the method typically finalizes any processing (e.g., passing data to a completion handler).
    ///   - For `URLSessionDownloadTask`, the downloaded file is stored **temporarily** and must be moved before this method completes.
    ///
    /// - Error Handling:
    ///   - If `error` is `nil`, the task completed successfully.
    ///   - If `error` is **not nil**, check the **error type** (e.g., network failure, timeout, authentication failure).
    ///   - If **resume data** is available for a failed download task, it may be possible to **resume the download**.
    ///
    /// - Thread Safety:
    ///   - This method should be called in a **thread-safe manner**, especially if modifying shared state.
    ///   - If updating UI elements, ensure that **UI updates are dispatched to the main thread**.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        /// Ensure this session is valid.
        guard session == urlSession else {
            return
        }
        var localTaskHandler: AnyUploadTaskHandler?
        /// Remove from `activeUploads` in a thread-safe manner.
        lockQueue.sync {
            localTaskHandler = activeUploads[task.taskIdentifier]
            activeUploads.removeValue(forKey: task.taskIdentifier)
        }
        /// Ensure `localTaskData` exists before proceeding.
        guard let taskHandler = localTaskHandler else {
            return
        }
        /// Return success or failure based on the error state.
        if let error = error {
            /// Error
            taskHandler.finish(request: task.originalRequest,
                           response: task.response,
                           error: .unknown(error))
            logger?.logMessage(message: "Upload task (ID: \(task.taskIdentifier)) completed with error: \(error.localizedDescription)", level: .error, logPrivacy: .public)
        } else {
            /// Ensure HTTP response is valid.
            if
                let httpResponse = task.response as? HTTPURLResponse,
                httpResponse.statusCode.statusCodeType != .successful {
                let statusCode = httpResponse.statusCode
                let error = NSError(domain: "Uploader", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Invalid status code \(statusCode)"])
                taskHandler.finish(request: task.originalRequest,
                               response: task.response,
                               error: .uploadFailed(error))
                logger?.logMessage(message: "Upload completed with error: \(error.localizedDescription). Task ID: \(task.taskIdentifier)", level: .error, logPrivacy: .public)
            } else {
                /// Success
                taskHandler.finish(request: task.originalRequest,
                               response: task.response,
                               error: nil)
                logger?.logMessage(message: "Upload task (ID: \(task.taskIdentifier)) completed successfully.", level: .info, logPrivacy: .public)
            }
        }
    }
    
}
