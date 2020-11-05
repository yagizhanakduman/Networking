//
//  NetworkErrorTypes.swift
//  Networking
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

// MARK: Network Error Types
public enum NetworkErrorTypes: Error {
    case clientError
    case serverError
    case networkError
    case parseError
    case invalidJSONError
    case noInternetError
    case emptyError
    
    var message: String {
        switch self {
        case .clientError: return ""
        case .serverError: return ""
        case .networkError: return ""
        case .parseError: return ""
        case .invalidJSONError: return ""
        case .noInternetError: return ""
        case .emptyError: return ""
        }
    }
    
}
