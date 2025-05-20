//
//  Networking+Download.swift
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

// MARK: - Download
extension Networking {
    
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
        return downloader.download(from: url, method: method, headers: headers, destinationURL: destinationURL, progressHandler: progressHandler, completion: completion)
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
        return try await downloader.download(from: url, method: method, headers: headers, destinationURL: destinationURL, progressHandler: progressHandler, completion: completion)
    }
    
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
        downloader.pauseDownload(task: task, completion: completion)
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
        return downloader.resumeDownload(with: resumeData, destinationURL: destinationURL, progress: progress, completion: completion)
    }
    
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
        downloader.cancelDownload(task: task)
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
        downloader.cancelAllDownloads()
    }
    
}
