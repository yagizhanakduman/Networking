//
//  ErrorModel.swift
//  Networking
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

// MARK: Error Model for API's Error Response
open class ErrorModel {
    
    private var errorModel: Any?
    private var message: String?
    private var networkErrorTypes: NetworkErrorTypes?
    private var statusCode: Int?
    
    public init(errorModel: Any? = nil, networkErrorTypes: NetworkErrorTypes, statusCode: Int? = nil) {
        self.errorModel = errorModel
        self.message = networkErrorTypes.message
        self.networkErrorTypes = networkErrorTypes
    }
    
    public func getErrorModel() -> Any? {
        return self.errorModel
    }

    public func getErrorMessage() -> String? {
        return self.message
    }

    public func getNetworkErrorTypes() -> NetworkErrorTypes? {
        return self.networkErrorTypes
    }
    
    public func getStatusCode() -> Int? {
        return self.statusCode
    }
    
}
