//
//  NetworkLearning.swift
//  Networking
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

public protocol NetworkLearning: class {
    
    func sendError(errorModel: ErrorModel, fail: Fail)
    func checkCustomError<ResultType: Codable>(errorModel: ErrorModel, success: Success<ResultType>,  fail: Fail)
    func checkSuccess<ResultType: Codable>(responseModel: ResultModel<ResultType>, success: Success<ResultType>, fail: Fail)
}

public extension NetworkLearning {
    
    func sendError(errorModel: ErrorModel, fail: Fail) {
        fail(errorModel)
    }
    
}

// MARK: Get Model
extension NetworkLearning {
    
    public func getMappedModel<T: Decodable>(json: String, type: T.Type) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        let object = try? JSONDecoder().decode(type, from: data)
        return object
    }
    
    public func getMappedModel(json: String) -> [String: Any]? {
        let dictionary = try? JSONSerializer.toDictionary(json)
        return dictionary as? [String: Any]
    }
    
}
