//
//  NetworkManager.swift
//  Networking
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

public typealias Success<T : Codable> = (ResultModel<T>) -> Void
public typealias Fail = (ErrorModel) -> Void
public typealias RequestHeaderParameters = [String: String]?
typealias Parameters = [String: Any]

// MARK: - Network Manager for API Request & Response
open class NetworkManager {
    
    private var learning : NetworkLearning?
    private var headers: [String : String] = [:]
    private var jsonKeys: [String]?
    private var url : String?
    private var workingThreadType: ThreadType = .mainThread
    
    public var threadType: ThreadType {
        get {
            return workingThreadType
        } set {
            workingThreadType = newValue
        }
    }
    
    public init() {}
    
}

// MARK: - Configuration
extension NetworkManager {
    
    open func setDefaultHeaders(_ headers: [String : String]) {
        self.headers = headers
    }
    
    open func addHeader(parameters: [String: String]?) {
        guard let parameters = parameters else {
            return
        }
        for (key, value) in parameters {
            headers[key] = value
        }
    }
    
    open func deleteAllHeaders() {
        headers = [:]
    }
    
    public func setJsonKey(_ keys: [String]?) {
        jsonKeys = keys
    }
    
    open func setNetworkLearning(_ learning: NetworkLearning) {
        self.learning = learning
    }
    
}

// MARK: - Request
extension NetworkManager {
    
    /// Request Service Method
    open func request<T: Codable>(networkService: NetworkServiceProtocol, success: @escaping Success<T>, fail: @escaping Fail) {
        guard let request = configurationURLRequest(networkService: networkService) else {
            parseNetworkResponse(data: nil, response: nil, error: nil, success: success, fail: fail)
            return
        }
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            let httpResponse = response as? HTTPURLResponse
            self.parseNetworkResponse(data: data, response: httpResponse, error: error, success: success, fail: fail)
        })
        task.resume()
    }
    
    /// Request Service Method with Body Parameters
    open func requestWithBody<R, T: Codable>(networkService: NetworkServiceProtocol, bodyParameters: R? = nil, bodyFileParameters: FileModel? = nil, success: @escaping Success<T>, fail: @escaping Fail) {
        let bodyData = retrieveBodyData(bodyParameters: bodyParameters)
        guard let request = configurationURLRequest(networkService: networkService, bodyData: bodyData, bodyFileParameters: bodyFileParameters) else {
            parseNetworkResponse(data: nil, response: nil, error: nil, success: success, fail: fail)
            return
        }
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            let httpResponse = response as? HTTPURLResponse
            self.parseNetworkResponse(data: data, response: httpResponse, error: error, success: success, fail: fail)
        })
        task.resume()
    }
    
    // MARK: Request Private Utility Methods
    /// Request Configuration
    private func configurationURLRequest(networkService: NetworkServiceProtocol, bodyData: Data? = nil, bodyFileParameters: FileModel? = nil) -> URLRequest? {
        let baseUrlString = networkService.baseURL.appending(networkService.path)
        guard
            let urlString = baseUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: urlString)
        else {
            return nil
        }
        if let _ = bodyFileParameters { deleteAllHeaders() }
        if let extraHeader = networkService.header {
            addHeader(parameters: extraHeader)
        }
        self.url = urlString
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        request.httpMethod = networkService.method.rawValue
        request.timeoutInterval = 30
        if let body = bodyData {
            if let file = bodyFileParameters, let fileData = file.file {
                let boundary = "Boundary-\(UUID().uuidString)"
                request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                request.httpBody = createBodyForUpload(parameters: file.parameters ?? ["":""], boundary: boundary, data: fileData, mimeType: file.mimeType ?? "", filename: file.fileName ?? "")
            } else {
                request.httpBody = body
            }
        }
        return request
    }
    
    /// Get Body Data
    private func retrieveBodyData<R>(bodyParameters: R?) -> Data? {
        var parameters: Parameters? = [:]
        if let param = bodyParameters, param is [String: Any] {
            parameters = bodyParameters as? Parameters
        } else if bodyParameters.self is Dictionary<String,Any>  {
            if let dictionaryParaam = bodyParameters as? Dictionary<String,Any>  {
                let jsonData = try? JSONSerialization.data(withJSONObject: dictionaryParaam, options: .prettyPrinted)
                let jsonString = String(data: jsonData!, encoding: .utf8)
                parameters = try? JSONSerializer.toBodyParameter(jsonString!)
            }
        } else if bodyParameters != nil && !(bodyParameters is String) {
            let inputJSONString = JSONSerializer.toJson(bodyParameters!)
            parameters = try? JSONSerializer.toBodyParameter(inputJSONString)
        } else {
            if bodyParameters != nil {
                let value = bodyParameters as? String
                if value != "" {
                    parameters = try? JSONSerializer.toBodyParameter(bodyParameters as! String)
                }
            }
        }
        guard let json = parameters else {
            return nil
        }
        do {
            return try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        } catch {
            return nil
        }
    }
    
    private func createBodyForUpload(parameters: [String: Any], boundary: String, data: Data, mimeType: String, filename: String) -> Data {
        let body = NSMutableData()
        let boundaryPrefix = "--\(boundary)\r\n"
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))
        return body as Data
    }
    
}

// MARK: - Parse
private extension NetworkManager {
    
    /// Service's Response Parser
    private func parseNetworkResponse<T: Codable>(data: Data?, response: HTTPURLResponse?, error: Error?, success: @escaping Success<T>, fail: @escaping Fail) {
        switch workingThreadType {
        case .backgroundThread:
            self.parseNetworkResponseWithThread(data: data, response: response, error: error, success: success, fail: fail)
        case .mainThread:
            DispatchQueue.main.async {
                self.parseNetworkResponseWithThread(data: data, response: response, error: error, success: success, fail: fail)
            }
        }
    }
    
    private func parseNetworkResponseWithThread<T: Codable>(data: Data?, response: HTTPURLResponse?, error: Error?, success: @escaping Success<T>, fail: @escaping Fail) {
        defer { debugPrint("PARSE END") }
        debugPrint("PARSE START")
        if let error = error {
            if (error as! URLError).code == URLError.notConnectedToInternet {
                let errorModel = ErrorModel(errorModel: error, networkErrorTypes: NetworkErrorTypes.noInternetError)
                fail(errorModel)
            } else {
                let errorModel = ErrorModel(errorModel: error, networkErrorTypes: NetworkErrorTypes.networkError)
                fail(errorModel)
            }
            return
        }
        guard let response = response else {
            let errorModel = ErrorModel(networkErrorTypes: NetworkErrorTypes.networkError)
            fail(errorModel)
            return
        }
        switch response.statusCode {
        case 200...299:
            guard let data = data else {
                let errorModel = ErrorModel(networkErrorTypes: NetworkErrorTypes.parseError)
                fail(errorModel)
                return
            }
            do {
                let json = String(decoding: data, as: UTF8.self)
                let result: ResultModel<T> = try getResultModel(json)
                let hasLearning = self.learning != nil ? true : false
                if hasLearning {
                    self.learning?.checkSuccess(responseModel: result, success: success, fail: fail)
                } else {
                    success(result)
                }
            } catch {
                let errorModel = ErrorModel(networkErrorTypes: NetworkErrorTypes.parseError)
                fail(errorModel)
            }
        case 400...499:
            let errorModel = ErrorModel(networkErrorTypes: NetworkErrorTypes.clientError, statusCode: response.statusCode)
            fail(errorModel)
        case 500...599:
            let errorModel = ErrorModel(networkErrorTypes: NetworkErrorTypes.serverError, statusCode: response.statusCode)
            fail(errorModel)
        default:
            let errorModel = ErrorModel(networkErrorTypes: NetworkErrorTypes.networkError, statusCode: response.statusCode)
            fail(errorModel)
        }
    }
    
    // MARK: Parse Private Utility Methods
    private func getResultModel<T: Codable>(_ json: String?) throws -> ResultModel<T> {
        if jsonKeys == nil || jsonKeys?.isEmpty == true {
            if isJSONArray(json) {
                let array = json?.toArray(type: [T].self)
                let resultModel = ResultModel<T>()
                resultModel.setArrayModel(model: array, type: [T].self)
                resultModel.setJson(json: json)
                resultModel.setRequestUrl(url: url)
                return resultModel
            } else {
                let resultModel = ResultModel<T>()
                let object = json?.toObject(type: T.self)
                resultModel.setModel(model: object,type: T.self)
                resultModel.setJson(json: json)
                resultModel.setRequestUrl(url: url)
                return resultModel
            }
        } else {
            guard let jsonDict = json?.toData() as? [String: Any] else {
                let resultModel = ResultModel<T>()
                resultModel.setJson(json: json)
                resultModel.setRequestUrl(url: url)
                return resultModel
            }
            
            var jsonData: Any?
            for jsonKey in jsonKeys! {
                let jsonKeySplit = jsonKey.split(separator: "/")
                if jsonKeySplit.count > 1 {
                    var dictionary: [String : Any]? = jsonDict
                    for splittedKey in jsonKeySplit {
                        dictionary = dictionary![splittedKey.description] as? [String: Any]
                    }
                    jsonData = dictionary
                } else {
                    if let jsonArray = jsonDict[jsonKey]  as? [Any] {
                        jsonData = jsonArray
                    } else {
                        jsonData = jsonDict[jsonKey] as? [String: Any]
                    }
                }
                
                if jsonData == nil {
                    if let str = jsonData as? String, str == "null" {
                        continue
                    }
                    continue
                } else {
                    break
                }
            }
            
            let resultModel = ResultModel<T>()
            resultModel.setJson(json: json)
            resultModel.setRequestUrl(url: url)
            
            if jsonData != nil && JSONSerialization.isValidJSONObject(jsonData!) {
                do {
                    let data = try JSONSerialization.data(withJSONObject: jsonData!, options: [])
                    if jsonData as? [Any] != nil {
                        let decoder = try JSONDecoder().decode([T].self, from: data)
                        resultModel.setArrayModel(model: decoder, type: [T].self)
                    } else {
                        let decoder = try JSONDecoder().decode(T.self, from: data)
                        resultModel.setModel(model: decoder, type: T.self)
                    }
                } catch let error {
                    print(error.localizedDescription)
                    throw NetworkErrorTypes.parseError
                }
            } else {
                throw NetworkErrorTypes.invalidJSONError
            }
            
            return resultModel
        }
    }
    
    private func isJSONArray(_ jsonString: String?) -> Bool {
        let json = jsonString?.toData()
        var result = false
        var jsonData: Any?
        
        if jsonKeys == nil || jsonKeys?.isEmpty == true {
            jsonData = json
            if let _ = jsonData as? [Any] {
                result = true
            } else {
                result = false
            }
        } else {
            for jsonKey in jsonKeys! {
                let object = json as? [String: Any]
                jsonData = object?[jsonKey] as? [Any]
                if object != nil {
                    break
                } else {
                    continue
                }
            }
            if jsonData != nil && isJSONArray(jsonData as? String) {
                result = true
            }
        }
        return result
    }
    
}
