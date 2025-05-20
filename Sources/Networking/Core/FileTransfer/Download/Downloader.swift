//
//  Downloader.swift
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

// MARK: - Downloader

/// This protocol defines the essential operations for downloading files over HTTP, including
/// initiating downloads, pausing, resuming, and canceling them. Conforming types should handle
/// common download scenarios such as background/foreground operations, progress tracking, and
/// network connectivity checks.
///
/// - Purpose:
///   - Standardize the approach for initiating, pausing, resuming, and canceling file downloads.
///   - Encapsulate download-related actions in a single contract, enabling modular and testable design.
///
/// - Key Responsibilities:
///   1. **Download Initialization** (`download(from:method:headers:destinationURL:progressHandler:completion:)`):
///      Start a download task, optionally with custom HTTP headers, and track progress.
///   2. **Pausing an Ongoing Download** (`pauseDownload(task:completion:)`):
///      Temporarily suspend the download, optionally retrieving `resumeData` for resuming later.
///   3. **Resuming a Paused Download** (`resumeDownload(with:destinationURL:progress:completion:)`):
///      Continue a previously paused download using `resumeData`.
///   4. **Canceling Download(s)**:
///      - **Single Task**: `cancelDownload(task:)` stops a specific download task.
///      - **All Tasks**: `cancelAllDownloads()` ends all active downloads at once.
///
/// - Usage Scenarios:
///   - **Foreground Downloads**: Download files while the app is active, providing real-time updates to the user.
///   - **Background Downloads**: Conforming implementations might support background tasks, allowing downloads to continue when the app is minimized or suspended.
///   - **Large File Handling**: Reliably download large content (videos, archives) with pause and resume capabilities.
///   - **Network Awareness**: Ensure downloads only start or resume when the network is available (e.g., via `ConnectionMonitor`).
///
/// - Thread Safety:
///   - Conforming types are expected to handle **thread-safe** access to internal states, often by using serial queues or other synchronization mechanisms.
///   - Methods dealing with the same download task should be called sequentially or from safe contexts to prevent race conditions.
///
/// - Note:
///   - Conforming classes can integrate logging, caching, and user prompts for large downloads.
///   - Resumable downloads depend on both server support (HTTP range requests) and correct handling of `resumeData`.
public protocol DownloaderProtocol: AnyObject {
    
    /// Downloads a file from the specified remote URL and reports progress via a closure.
    ///
    /// - Parameters:
    ///   - url: The file's remote location.
    ///   - method: The HTTP method to use (default: `.get`).
    ///   - headers: Optional headers for the request.
    ///   - destinationURL: Optional local file path to save the download.
    ///   - progressHandler: Closure reporting download progress (0.0...1.0).
    ///   - completion: Completion handler with download result.
    ///
    /// - Returns: Always returns `nil`; the task is managed internally.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    @discardableResult func download<T: Decodable>(from url: URL, method: HTTPMethod, headers: HTTPHeaders?, destinationURL: URL?, progressHandler: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionDownloadTask?
    
    /// Asynchronously downloads a file from a remote URL, optionally saving it to a specified location.
    ///
    /// - Parameters:
    ///   - url: The download source.
    ///   - method: HTTP method to use (default: `.get`).
    ///   - headers: Optional headers.
    ///   - destinationURL: Optional local path for the downloaded file.
    ///   - progressHandler: Closure providing progress updates.
    ///   - completion: Handler called upon completion with a `NetworkingResponse`.
    ///
    /// - Returns: The created `URLSessionDownloadTask?`, or `nil` if failed.
    ///
    /// - Throws: If the request cannot be built or sent.
    ///
    /// - Note: For full usage details and behavior, refer to the implementing class documentation.
    @discardableResult func download<T: Decodable>(from url: URL, method: HTTPMethod, headers: HTTPHeaders?, destinationURL: URL?, progressHandler: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) async throws -> URLSessionDownloadTask?
    
    /// Pauses an active `URLSessionDownloadTask`, retrieving optional `resumeData` if the server supports resuming.
    ///
    /// - Parameters:
    ///   - task: A `URLSessionDownloadTask` that is currently in progress.
    ///   - completion: A closure that provides the `Data?` used to resume the download later. If `nil`, the download may have to restart.
    ///
    /// - Note:
    ///   - The availability of `resumeData` depends on server support and the point of interruption.
    ///   - For tasks that don't support resuming, this method behaves like a normal cancellation.
    func pauseDownload(task: URLSessionDownloadTask, completion: @escaping (Data?) -> Void)
    
    /// Resumes a previously paused download using `resumeData`.
    ///
    /// - Parameters:
    ///   - resumeData: The `Data` object containing partial download progress information.
    ///   - destinationURL: An optional file URL where the downloaded file should be saved. If `nil`, a temporary location is used.
    ///   - progress: A closure receiving progress updates (`Double` between `0.0` and `1.0`).
    ///   - completion: A closure called upon completion, returning a `NetworkingResponse<T>`:
    ///                 - `.success(URL)`: Local file URL if the download completes successfully.
    ///                 - `.failure(NetworkError)`: Error describing the reason for failure.
    ///
    /// - Returns: An optional `URLSessionDownloadTask` if the resume request is successfully created; otherwise, `nil`.
    ///
    /// - Note:
    ///   - If the server does not support partial content requests, resuming will fail and the download will restart from scratch.
    @discardableResult func resumeDownload<T: Decodable>(with resumeData: Data, destinationURL: URL?, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionDownloadTask?
    
    /// Cancels a specific download task.
    ///
    /// - Parameter task: The `URLSessionTask` to cancel.
    ///
    /// - Note:
    ///   - If the server supports partial downloads, `resumeData` might be generated internally.
    ///   - Use `pauseDownload(task:completion:)` if you intend to resume later and need explicit `resumeData`.
    func cancelDownload(task: URLSessionTask)
    
    /// Cancels **all** ongoing downloads managed by the conforming type.
    ///
    /// - Note:
    ///   - This operation stops every active `URLSessionDownloadTask`, removing them from internal tracking.
    ///   - Any partially downloaded data may or may not be recoverable, depending on the server and `resumeData` support.
    func cancelAllDownloads()
}

/// `Downloader` is a utility class for managing file downloads using `URLSessionDownloadTask`.
///
/// - It supports **background and foreground** downloads.
/// - Tracks **progress updates** and **handles completion events**.
/// - Can **pause and resume** downloads if the server allows it.
/// - Uses **thread-safe mechanisms** to manage active downloads.
///
/// - Features:
///   - **Efficient File Downloading**: Supports large files and background downloads.
///   - **Progress Tracking**: Reports download progress as a percentage.
///   - **Resume Support**: If supported by the server, interrupted downloads can be resumed.
///   - **Thread Safety**: Uses a dedicated `DispatchQueue` to avoid race conditions.
///   - **Network Awareness**: Prevents downloads when offline using `ConnectionMonitor`.
///
/// - Example Usage:
///   ```swift
///   let sessionConfig = URLSessionConfiguration.default
///   let session = URLSession(configuration: sessionConfig)
///   let logger = NetworkLogger()
///   let connectionMonitor = ConnectionMonitor()
///
///   let downloader = Downloader(session: session, logger: logger, connectionMonitor: connectionMonitor)
///   ```
public class Downloader: NSObject, DownloaderProtocol {
    
    /// A dictionary mapping task identifiers to their respective `DownloadTaskHandler`.
    ///
    /// - Key: `task.taskIdentifier` — the unique identifier assigned to each download task.
    /// - Value: `AnyDownloadTaskHandler` — a type-erased wrapper that holds progress and completion closures
    ///   associated with the task.
    ///
    /// - Purpose:
    ///   - Used to keep track of active download tasks and associate them with callbacks.
    ///   - Ensures correct delivery of progress updates and completion results per task.
    private var activeDownloads: [Int: AnyDownloadTaskHandler] = [:]
    
    /// A serial dispatch queue used to synchronize access to `activeDownloads`.
    ///
    /// - Note:
    ///   - Prevents data races and ensures thread-safe access when adding, removing or reading from the `activeDownloads` dictionary.
    ///   - All modifications to `activeDownloads` should occur inside this queue.
    private let lockQueue = DispatchQueue(label: "networking.downloader.lock")
    
    /// The `URLSession` instance used for handling download tasks.
    ///
    /// - Note:
    ///   - This session is responsible for creating and managing `URLSessionDownloadTask` instances.
    ///   - To support background downloads, configure this session using `.background` mode.
    private var urlSession: URLSession?
    
    /// Optional interceptor to modify or adapt outgoing download requests.
    ///
    /// - Usage:
    ///   - Used for appending authentication tokens, modifying headers, or retrying requests.
    ///   - Must conform to `RequestInterceptor`, which defines an `adapt(_:)` method.
    private var interceptor: RequestInterceptor?
    
    /// Optional logger to track and debug download activity.
    ///
    /// - Note:
    ///   - Can log request metadata, response results, and errors.
    ///   - Especially useful during development and QA to trace failed downloads or monitor bandwidth.
    private var logger: NetworkLoggerProtocol?
    
    /// A connection monitor that tracks network availability.
    ///
    /// - Note:
    ///   - Prevents initiating downloads when there is no active internet connection.
    ///   - Can be used to pause or resume downloads dynamically based on network conditions.
    private var connectionMonitor: ConnectionMonitor = ConnectionMonitor()
    
    /// Initializes a new instance of `Downloader` with a given `URLSession`, `NetworkLogger`, and `ConnectionMonitor`.
    ///
    /// This initializer sets up the `Downloader` instance, ensuring it is ready to manage file downloads using `URLSessionDownloadTask`.
    /// It assigns the provided dependencies and prepares the delegate structure needed for monitoring, security, and logging.
    ///
    /// - Parameters:
    ///
    ///   - session: The `URLSession` instance responsible for managing download tasks.
    ///              - Should be configured appropriately for **foreground** or **background** download operations.
    ///              - If background support is needed, use `.background(withIdentifier:)` configuration.
    ///
    ///   - pinningDelegate: An optional `PinningURLSessionDelegate` used for **SSL certificate pinning**.
    ///                      - Assigns itself as the session delegate for enforcing secure connections.
    ///                      - If `nil`, certificate pinning is disabled.
    ///
    ///   - interceptor: A `RequestInterceptor` used to **adapt download requests** before they are executed.
    ///                  - Useful for adding authentication headers or retry logic.
    ///
    ///   - logger: A `NetworkLogger` instance used to log network activity related to downloads.
    ///             - Helps with debugging, performance monitoring, and failure tracing.
    ///             - If `nil`, no logs are recorded.
    ///
    ///   - connectionMonitor: A `ConnectionMonitor` instance that observes the network state.
    ///                        - Prevents downloads when offline.
    ///                        - Can be used to pause or resume based on real-time network changes.
    ///
    /// - Note:
    ///   - If the session uses a background configuration, downloads can **continue when the app is suspended or terminated**.
    ///   - This setup is recommended to be completed before initiating any download requests.
    ///   - All provided parameters are stored internally for use during download lifecycle management.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   let config = URLSessionConfiguration.default
    ///   let session = URLSession(configuration: config)
    ///   let monitor = ConnectionMonitor()
    ///   let logger = NetworkLogger()
    ///   let delegate = PinningURLSessionDelegate(pinnedCertificateNamesByHost: [...])
    ///
    ///   let downloader = Downloader(session: session,
    ///                               pinningDelegate: delegate,
    ///                               interceptor: nil,
    ///                               logger: logger,
    ///                               connectionMonitor: monitor)
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This initializer is thread-safe and should be invoked **prior to** any concurrent downloads.
    ///   - Internal state setup is safe as long as `Downloader` is initialized from a single thread.
    public init(session: URLSession, pinningDelegate: PinningURLSessionDelegate? = nil, interceptor: RequestInterceptor?, logger: NetworkLogger?, connectionMonitor: ConnectionMonitor) {
        super.init()
        /// Assigns the provided pinning delegate's download callback to this instance.
        /// Enables SSL pinning validation via `PinningURLSessionDelegate` during download tasks.
        pinningDelegate?.downloadDelegate = self
        /// Initializes a new `URLSession` using the given session's configuration and delegate setup.
        /// This ensures that all download requests in this instance are routed through the correct delegate.
        /// If a `pinningDelegate` is provided, it handles SSL pinning; otherwise, default validation is used.
        self.urlSession = URLSession(configuration: session.configuration, delegate: pinningDelegate, delegateQueue: session.delegateQueue)
        /// Stores the request interceptor, if provided.
        /// Interceptors allow modification of download requests (e.g., adding auth tokens or logging) before execution.
        self.interceptor = interceptor
        /// Stores the provided `NetworkLogger` instance used for logging download activity.
        /// This includes request URLs, progress, completion, and any encountered errors.
        self.logger = logger
        /// Stores the provided `ConnectionMonitor` for observing internet connectivity.
        /// Prevents downloads from being initiated if the device is currently offline.
        self.connectionMonitor = connectionMonitor
    }
    
}

// MARK: - Public API
extension Downloader {
    
    /// Downloads a file from a remote URL using a synchronous-style API that internally dispatches to an async task.
    ///
    /// This method is designed for use in non-async contexts (e.g., UIKit actions or delegate methods).
    /// It creates and launches an async `Task` under the hood, and delivers progress and result via provided closures.
    ///
    /// - Parameters:
    ///
    ///   - url: The remote `URL` of the file to be downloaded.
    ///          - Should point to a valid downloadable resource (e.g., `https://example.com/file.zip`).
    ///
    ///   - method: The HTTP method used for the request (default: `.get`).
    ///             - Usually `.get`, but may be overridden depending on server behavior.
    ///
    ///   - headers: Optional `HTTPHeaders` to attach to the request.
    ///              - Useful for adding authentication tokens or API-specific headers.
    ///
    ///   - destinationURL: An optional `URL` that determines where the file should be saved locally.
    ///                     - If `nil`, the system will store it in a temporary directory.
    ///
    ///   - progressHandler: An optional closure that receives progress updates as a `Double` between `0.0` and `1.0`.
    ///                      - Useful for updating UI components such as progress views.
    ///
    ///   - completion: A closure called after the download completes.
    ///                 - The `NetworkingResponse<T>` result may contain:
    ///                   - `.success(T)`: If the response was successfully decoded into type `T`.
    ///                   - `.failure(NetworkError)`: If the download failed or decoding encountered an error.
    ///
    /// - Returns:
    ///   - Always returns `nil`, as the internal async `Task` handles the download lifecycle.
    ///     - All communication happens through `progressHandler` and `completion`.
    ///
    /// - Note:
    ///   - This method is **not cancelable**, since the `URLSessionDownloadTask` is not returned to the caller.
    ///     - For better control, use the async variant of `download(...)`.
    ///   - Errors thrown during the download will be wrapped in `.failure(.downloadFailed(error))`.
    ///   - Ideal for legacy APIs, delegate methods, or ViewControllers where `async/await` is not directly usable.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   downloader.download(
    ///       from: URL(string: "https://example.com/report.pdf")!,
    ///       destinationURL: FileManager.default.temporaryDirectory.appendingPathComponent("report.pdf"),
    ///       progressHandler: { progress in
    ///           print("Download progress: \(progress * 100)%")
    ///       },
    ///       completion: { (response: NetworkingResponse<DownloadResponse>) in
    ///           switch response.result {
    ///           case .success(let result):
    ///               print("Downloaded successfully:", result)
    ///           case .failure(let error):
    ///               print("Download failed:", error)
    ///           }
    ///       }
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This method is thread-safe. It launches its logic in an isolated async `Task`.
    ///   - The `completion` and `progressHandler` callbacks may be invoked on background threads.
    ///     - Use `DispatchQueue.main.async` to update UI if needed.
    @discardableResult
    public func download<T: Decodable>(from url: URL, method: HTTPMethod = .get, headers: HTTPHeaders? = nil, destinationURL: URL? = nil, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionDownloadTask? {
        /// Launch an async task immediately to handle the upload operation.
        Task {
            do {
                _ = try await download(
                    from: url,
                    method: method,
                    headers: headers,
                    destinationURL: destinationURL,
                    progressHandler: progressHandler,
                    completion: completion
                )
            } catch {
                /// Return a failure response if an error occurs during async upload.
                let networkingResponse: NetworkingResponse<T> = NetworkingResponse(
                    request: nil,
                    response: nil,
                    data: nil,
                    result: .failure(.downloadFailed(error))
                )
                completion(networkingResponse)
            }
        }
        /// Caller does not manage the upload task directly.
        return nil
    }
    
    /// Downloads a file from a remote URL using `URLSessionDownloadTask` and optionally saves it to a specified destination.
    ///
    /// This method initiates a download request and provides progress updates and a completion callback.
    /// If a destination file path is provided, the file will be moved there after the download finishes.
    /// Otherwise, the system will store the downloaded file in a temporary directory.
    ///
    /// - Parameters:
    ///
    ///   - url: The remote `URL` of the file to be downloaded.
    ///          - Should be a valid and reachable resource endpoint (e.g., `https://example.com/file.zip`).
    ///
    ///   - method: The `HTTPMethod` to use for the request (default: `.get`).
    ///             - Downloads typically use `.get`, but some APIs may allow `.post` or others.
    ///
    ///   - headers: Optional `HTTPHeaders` for the request (e.g., authentication, user-agent).
    ///              - These headers override default headers and are included in the request.
    ///
    ///   - destinationURL: An optional file `URL` where the downloaded content should be saved.
    ///                     - If `nil`, the file will remain in the temporary system directory.
    ///                     - If provided, the downloaded file will be moved here after the download completes.
    ///
    ///   - progressHandler: A closure reporting download progress as a `Double` from `0.0` to `1.0`.
    ///                      - Called periodically while the download is active.
    ///                      - Use this to update progress indicators or logs.
    ///
    ///   - completion: A closure called after the download finishes.
    ///                 - Receives a `NetworkingResponse<T>`:
    ///                   - `.success(URL)`: If the file is successfully downloaded and moved.
    ///                   - `.failure(NetworkError)`: If the request failed, was interrupted, or the file could not be saved.
    ///
    /// - Returns:
    ///   - A `URLSessionDownloadTask?` representing the active download task.
    ///     - Returns `nil` if the request could not be built or the task could not be created.
    ///
    /// - Note:
    ///   - This method is marked with `@discardableResult`, so callers may ignore the returned task.
    ///   - Use `destinationURL` only if the app has write access to the target path.
    ///   - For interrupted downloads, `resumeData` may be available for future continuation.
    ///   - The request can be customized via `interceptor` if defined.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   try await downloader.download(
    ///       from: URL(string: "https://example.com/file.zip")!,
    ///       destinationURL: FileManager.default.temporaryDirectory.appendingPathComponent("file.zip"),
    ///       progressHandler: { progress in
    ///           print("Download progress: \(progress * 100)%")
    ///       },
    ///       completion: { (response: NetworkingResponse<DownloadResponseModel>) in
    ///           switch response.result {
    ///           case .success(let url):
    ///               print("Downloaded to:", url)
    ///           case .failure(let error):
    ///               print("Download failed:", error)
    ///           }
    ///       }
    ///   )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - This method is **thread-safe**. Shared resources like `activeDownloads` are synchronized using `lockQueue`.
    ///   - The `progressHandler` and `completion` closures may be called on background threads.
    ///     - Use `DispatchQueue.main.async` if UI updates are needed.
    @discardableResult
    public func download<T: Decodable>(from url: URL, method: HTTPMethod = .get, headers: HTTPHeaders? = nil, destinationURL: URL? = nil, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (NetworkingResponse<T>) -> Void) async throws -> URLSessionDownloadTask? {
        /// Log starting a download
        logger?.logMessage(message: "Starting download from URL: \(url.absoluteString)", level: .info, logPrivacy: .public)
        /// Check if the device has an active internet connection before proceeding with the network request.
        if !connectionMonitor.isReachable {
            logger?.logMessage(message: "Download canceled. No internet connection.", level: .error, logPrivacy: .public)
            /// If the device is offline, throw a `NetworkError.noInternetConnection` error.
            /// This prevents unnecessary network calls and allows the caller to handle offline scenarios gracefully.
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.noInternetConnection))
            completion(networkingResponse)
            return nil
        }
        /// Set request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        /// Set custom headers if provided.
        if let headers = headers?.dictionary {
            for (key, value) in headers {
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
                                                     result: .failure(.downloadFailed(error)))
                completion(response)
                return nil
            }
        }
        /// Create a download task with the generated request
        guard let task = urlSession?.downloadTask(with: request) else {
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: request, response: nil, data: nil, result: .failure(.downloadFailed(nil)))
            completion(networkingResponse)
            return nil
        }
        /// Create a `DownloadTaskHandler`
        let taskHandler = DownloadTaskHandler<T>(
            destinationURL: destinationURL,
            progress: progressHandler,
            completion: completion
        )
        /// Store the task metadata in `activeDownloads` dictionary (thread-safe access).
        lockQueue.sync {
            activeDownloads[task.taskIdentifier] = taskHandler
        }
        logger?.logMessage(message: "Download task created. Task ID: \(task.taskIdentifier)", level: .debug, logPrivacy: .public)
        /// Start the download.
        task.resume()
        logger?.logMessage(message: "Download task resumed. Task ID: \(task.taskIdentifier)", level: .debug, logPrivacy: .public)
        return task
    }
    
}

// MARK: - Pause & Resume
extension Downloader {
    
    /// Pauses an ongoing `URLSessionDownloadTask` and returns resume data if available.
    ///
    /// This method cancels a download task in a resumable manner, allowing the operation to be continued later.
    /// If supported by the server and network stack, the system provides `resumeData`, which can be used to resume
    /// the download from where it left off.
    ///
    /// - Parameters:
    ///   - task: The download task to be paused.
    ///           - Must be an active `URLSessionDownloadTask`.
    ///
    ///   - completion: A closure called with the resume data (`Data?`) from the canceled task.
    ///                 - If non-nil, this data can be used with `resumeDownload(...)`.
    ///                 - If `nil`, the download must restart from scratch.
    ///
    /// - Note:
    ///   - Resume data availability is **not guaranteed**; some servers do not support it.
    ///   - Save the resume data to a persistent location if downloads may continue after app relaunch.
    ///   - Use `resumeDownload(with:resumeData:)` to continue the download later.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   downloader.pauseDownload(task: downloadTask) { resumeData in
    ///       if let data = resumeData {
    ///           // Save this data to resume later
    ///           UserDefaults.standard.set(data, forKey: "resumeData")
    ///       }
    ///   }
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Thread-safe via internal locking (`lockQueue`).
    public func pauseDownload(task: URLSessionDownloadTask, completion: @escaping (Data?) -> Void) {
        logger?.logMessage(message: "Pausing download. Task ID: \(task.taskIdentifier)", level: .info, logPrivacy: .public)
        lockQueue.sync {
            task.cancel { resumeDataOrNil in
                /// Return resume data if available.
                completion(resumeDataOrNil)
                self.logger?.logMessage(
                    message: resumeDataOrNil == nil ? "No resume data available. Will restart if resumed." : "Resume data captured for Task ID: \(task.taskIdentifier)",
                    level: .debug,
                    logPrivacy: .public
                )
            }
        }
    }
    
    /// Resumes a paused download using previously obtained resume data.
    ///
    /// This method creates a new `URLSessionDownloadTask` from the provided resume data and starts it immediately.
    /// It supports tracking progress and saving the final file to a custom location.
    ///
    /// - Parameters:
    ///   - resumeData: The resume data obtained from a previous download task via `pauseDownload(...)`.
    ///                 - Must be a valid `Data` blob; otherwise the download will fail.
    ///
    ///   - destinationURL: The final local file destination.
    ///                     - If `nil`, the file is saved to a temporary system location.
    ///
    ///   - progress: An optional closure providing real-time progress updates as a `Double` from `0.0` to `1.0`.
    ///               - Useful for updating download indicators.
    ///
    ///   - completion: A closure returning a `NetworkingResponse<T>`:
    ///                 - `.success(URL)`: The final local file URL.
    ///                 - `.failure(NetworkError)`: The error describing the failure.
    ///
    /// - Returns:
    ///   - A `URLSessionDownloadTask` if the task was successfully created; otherwise `nil`.
    ///
    /// - Note:
    ///   - If `resumeData` is corrupted or mismatched, the download will fail.
    ///   - Ensure `resumeData` corresponds to the same file and server.
    ///
    /// - Example Usage:
    ///   ```swift
    ///       downloader.resumeDownload(
    ///           with: resumeData,
    ///           destinationURL: FileManager.default.temporaryDirectory.appendingPathComponent("video.mp4"),
    ///           progress: { progress in
    ///               print("Download progress: \(progress * 100)%")
    ///           },
    ///           completion: { (response: NetworkingResponse<DownloadModel>) in
    ///               switch response.result {
    ///               case .success(let fileURL):
    ///                   print("File downloaded to:", fileURL)
    ///               case .failure(let error):
    ///                   print("Download failed:", error)
    ///               }
    ///           }
    ///       )
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Thread-safe via `lockQueue` when modifying internal state.
    @discardableResult
    public func resumeDownload<T: Decodable>(with resumeData: Data, destinationURL: URL? = nil, progress: ((Double) -> Void)?, completion: @escaping (NetworkingResponse<T>) -> Void) -> URLSessionDownloadTask? {
        logger?.logMessage(message: "Attempting to resume download with resumeData. Size: \(resumeData.count) bytes", level: .info, logPrivacy: .public)
        if !connectionMonitor.isReachable {
            /// If the device is offline, throw a `NetworkError.noInternetConnection` error.
            /// This prevents unnecessary network calls and allows the caller to handle offline scenarios gracefully.
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: nil, response: nil, data: nil, result: .failure(.noInternetConnection))
            completion(networkingResponse)
            return nil
        }
        /// Create a new download task using `resumeData`
        guard let task = urlSession?.downloadTask(withResumeData: resumeData) else {
            let networkingResponse: NetworkingResponse<T> = NetworkingResponse(request: nil, response: nil, data: resumeData, result: .failure(.downloadFailed(nil)))
            completion(networkingResponse)
            return nil
        }
        /// Create taskData
        let taskHandler = DownloadTaskHandler(
            destinationURL: destinationURL,
            progress: progress,
            completion: completion
        )
        /// Set taskData again
        lockQueue.sync {
            activeDownloads[task.taskIdentifier] = taskHandler
        }
        logger?.logMessage(message: "Resumed download task created. Task ID: \(task.taskIdentifier)", level: .debug, logPrivacy: .public)
        /// Resume task
        task.resume()
        logger?.logMessage(message: "Resumed download task started. Task ID: \(task.taskIdentifier)", level: .debug, logPrivacy: .public)
        return task
    }
    
}

// MARK: - Cancel
extension Downloader {
    
    /// Cancels an ongoing download task.
    ///
    /// This method cancels a single download task and removes it from the internal tracking list.
    /// If the server supports resume, canceling may generate `resumeData`.
    ///
    /// - Parameter task: The task to cancel. Must be a valid and running `URLSessionDownloadTask`.
    ///
    /// - Note:
    ///   - Canceling may prevent further progress updates or completion callbacks.
    ///   - Use `pauseDownload(...)` if you wish to resume later.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   downloader.cancelDownload(task: downloadTask)
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Uses `lockQueue` to safely modify shared download task storage.
    public func cancelDownload(task: URLSessionTask) {
        logger?.logMessage(message: "Canceling download. Task ID: \(task.taskIdentifier)", level: .info, logPrivacy: .public)
        task.cancel()
        /// Ensures thread-safe access to `activeDownloads` using `lockQueue`.
        lockQueue.sync {
            _ = activeDownloads.removeValue(forKey: task.taskIdentifier)
        }
    }
    
    /// Cancels all active download tasks managed by the downloader.
    ///
    /// This method iterates over all ongoing download tasks and cancels each one.
    /// All associated progress and completion handlers will be removed, and `activeDownloads` will be cleared.
    ///
    /// - Note:
    ///   - Tasks that support resume may return resume data when canceled (not captured here).
    ///   - Use `pauseDownload(...)` per task to capture resume data if needed.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   downloader.cancelAllDownloads()
    ///   ```
    ///
    /// - Thread Safety:
    ///   - Access to `activeDownloads` is synchronized using `lockQueue` to prevent race conditions.
    public func cancelAllDownloads() {
        logger?.logMessage(message: "Canceling all ongoing downloads.", level: .info, logPrivacy: .public)
        lockQueue.sync {
            /// Fetch all tasks currently running in the session.
            urlSession?.getAllTasks(completionHandler: { tasks in
                /// Filters tasks that match `activeDownloads`.
                let results = zip(tasks, self.activeDownloads).enumerated().filter() {
                    $1.0.taskIdentifier == $1.1.key
                }
                /// Cancels each matched task.
                results.forEach { result in
                    let task = result.element.0
                    task.cancel()
                    self.logger?.logMessage(message: "Canceled download. Task ID: \(task.taskIdentifier)", level: .debug, logPrivacy: .public)
                }
            })
            /// Clears all stored active downloads.
            activeDownloads.removeAll()
        }
    }
    
}

// MARK: - URLSessionDownloadDelegate
extension Downloader: URLSessionDownloadDelegate {
    
    /// Reports the progress of a download task as data is written.
    ///
    /// - This method is periodically called as the download progresses.
    /// - It calculates the percentage of data downloaded and logs the progress.
    /// - If a progress handler exists for the task, it is invoked with the current progress value.
    ///
    /// - Parameters:
    ///   - session: The `URLSession` handling the download task.
    ///   - downloadTask: The `URLSessionDownloadTask` tracking the download.
    ///   - bytesWritten: The number of bytes written since the last call.
    ///   - totalBytesWritten: The total number of bytes downloaded so far.
    ///   - totalBytesExpectedToWrite: The expected total size of the file.
    ///
    /// - Note:
    ///   - This method only tracks progress **if the server provides the content length** (`totalBytesExpectedToWrite > 0`).
    ///   - The calculated progress value is a fraction between `0.0` and `1.0`, representing the percentage downloaded.
    ///   - The progress is logged and, if available, passed to the registered `progressHandler` for UI updates.
    ///
    /// - Thread Safety:
    ///   - The `lockQueue.sync` block ensures **thread-safe access** to `activeDownloads`.
    ///   - This prevents race conditions when updating progress.
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        /// Ensure this session is valid and totalBytesExpectedToWrite is available.
        guard
            session == urlSession,
            totalBytesExpectedToWrite > 0
        else {
            return
        }
        /// Calculate progress percentage.
        let progressValue = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        /// Log progress
        logger?.logMessage(message: "Download progress: \(progressValue * 100)% (Task ID: \(downloadTask.taskIdentifier))", level: .debug, logPrivacy: .public)
        /// Call the associated `progressHandler` from `activeDownloads`.
        lockQueue.sync {
            if let taskHandler = activeDownloads[downloadTask.taskIdentifier] {
                taskHandler.progressHandler?(progressValue)
            }
        }
    }
    
    /// Called when a download task has completed and the file has been successfully downloaded.
    ///
    /// - This method is triggered when a `URLSessionDownloadTask` finishes downloading a file.
    /// - The downloaded file is stored in a **temporary location** and should be moved to a permanent destination if needed.
    /// - Developers should handle file management within this method to ensure the file persists beyond the session.
    ///
    /// - Parameters:
    ///   - session: The `URLSession` handling the download task.
    ///   - downloadTask: The completed `URLSessionDownloadTask` that finished downloading.
    ///   - location: A `URL` pointing to the **temporary system directory** where the downloaded file is stored.
    ///
    /// - Note:
    ///   - The file at `location` is **automatically deleted** by the system once this method returns.
    ///   - To keep the file, it must be **moved** to a permanent directory (e.g., `Documents` or `Caches`).
    ///   - Use `FileManager` to move the file to a desired destination.
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        /// Retrieve the task's metadata from `activeDownloads`.
        var localTaskHandler: AnyDownloadTaskHandler?
        lockQueue.sync {
            localTaskHandler = activeDownloads[downloadTask.taskIdentifier]
            /// We do not remove it from the dictionary immediately. It will also be removed during `didCompleteWithError`.
        }
        /// Ensure we have valid task data.
        guard let taskHandler = localTaskHandler else {
            logger?.logMessage(message: "No localTaskData found for Task ID: \(downloadTask.taskIdentifier)", level: .error, logPrivacy: .public)
            return
        }
        /// Validate HTTP response status.
        if
            let httpResponse = downloadTask.response as? HTTPURLResponse,
            httpResponse.statusCode.statusCodeType != .successful {
            logger?.logMessage(message: "Invalid status code \(httpResponse.statusCode) for Task ID: \(downloadTask.taskIdentifier)", level: .error, logPrivacy: .public)
            let statusCode = httpResponse.statusCode
            let error = NSError(domain: "Downloader", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Invalid status code \(statusCode)"])
            taskHandler.finish(with: nil, error: error)
            return
        }
        /// Move the downloaded file to the `destinationURL` if provided.
        if let destinationURL = taskHandler.destinationURL {
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                logger?.logMessage(message: "Download finished successfully. Task ID: \(downloadTask.taskIdentifier). File saved to: \(destinationURL.path)",  level: .info, logPrivacy: .public)
                try FileManager.default.moveItem(at: location, to: destinationURL)
                taskHandler.finish(with: destinationURL, error: nil)
            } catch {
                logger?.logMessage(message: "File move error: \(error.localizedDescription). Task ID: \(downloadTask.taskIdentifier)", level: .error, logPrivacy: .public)
                taskHandler.finish(with: destinationURL, error: error)
            }
        } else {
            logger?.logMessage(message: "Download finished. Temporary file: \(location.path). Task ID: \(downloadTask.taskIdentifier)", level: .info, logPrivacy: .public)
            /// If no `destinationURL`, return the temporary file location.
            taskHandler.finish(with: location, error: nil)
        }
    }
    
    /// Handles the completion of a download task, determining success or failure.
    ///
    /// - This method is called when a download task completes, either successfully or with an error.
    /// - If the task is successful, it logs the completion.
    /// - If the task fails, it logs the error and invokes the completion handler with a failure result.
    /// - Ensures thread-safe access when removing the task from `activeDownloads`.
    ///
    /// - Parameters:
    ///   - session: The `URLSession` instance managing the download task.
    ///   - task: The `URLSessionTask` that has completed execution.
    ///   - error: An optional `Error` if the task encountered a failure.
    ///            If `nil`, the download completed successfully.
    ///
    /// - Note:
    ///   - The method first ensures that the session matches `urlSession` before proceeding.
    ///   - The task is removed from `activeDownloads` using a **thread-safe** approach.
    ///   - If the download fails and **resume data** is available, it could be used to restart the download.
    ///   - Future improvements could include handling **resumable downloads**.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        /// Ensure this session is valid.
        guard session == urlSession else {
            return
        }
        /// Retrieve the task data and remove it from `activeDownloads`.
        var localTaskHandler: AnyDownloadTaskHandler?
        lockQueue.sync {
            localTaskHandler = activeDownloads[task.taskIdentifier]
            activeDownloads.removeValue(forKey: task.taskIdentifier)
        }
        guard let taskHandler = localTaskHandler else {
            return
        }
        /// If an error occurred and the download did not finish, report it.
        if let error = error {
            logger?.logMessage(message: "Download completed with error: \(error.localizedDescription). Task ID: \(task.taskIdentifier)", level: .error, logPrivacy: .public)
            /// Check if `resumeData` is available - TODO
            taskHandler.finish(with: nil, error: error)
        } else {
            logger?.logMessage(message: "Download task completed successfully. Task ID: \(task.taskIdentifier)", level: .info, logPrivacy: .public)
        }
    }
    
}
