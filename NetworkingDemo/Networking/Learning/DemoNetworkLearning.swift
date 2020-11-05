//
//  DemoNetworkLearning.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation
import Networking

// MARK: Network Learning to Customize Networking for Demo Project
final class DemoNetworkLearning: NetworkLearning {
    
    /// Add Error Codes, Customize...
    enum StatusCode: Int {
        case success = 200
        case sampleErrorCode = 301
    }
    
    func checkCustomError<ResultType>(errorModel: ErrorModel, success: (ResultModel<ResultType>) -> Void, fail: (ErrorModel) -> Void) where ResultType : Codable {
        fail(errorModel)
    }
    
    func checkSuccess<ResultType>(responseModel: ResultModel<ResultType>, success: (ResultModel<ResultType>) -> Void, fail: (ErrorModel) -> Void) where ResultType : Codable {
        guard let response = getMappedModel(json: responseModel.getJson()) else {
            let errorModel = ErrorModel(networkErrorTypes: .invalidJSONError)
            fail(errorModel)
            return
        }
        /// Sample Block
        if let isSuccess = response["isSuccess"] as? Bool, isSuccess {
            if
                let statusCode = response["statusCode"] as? Int,
                statusCode == StatusCode.sampleErrorCode.rawValue {
                /// Do something
            }
            success(responseModel)
        } else {
            let errorModel = ErrorModel(networkErrorTypes: .clientError)
            fail(errorModel)
        }
    }
    
}
