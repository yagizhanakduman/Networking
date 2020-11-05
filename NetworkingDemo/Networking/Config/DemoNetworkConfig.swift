//
//  DemoNetworkConfig.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation
import Networking

// MARK: Customize Config for Network Manager
enum DemoNetworkConfig: NetworkServiceProtocol {

    case starships
    case startshipWithId(_ id: String)

    var baseURL: String {
        return "https://swapi.dev/api/"
    }

    var path: String {
        switch self {
        case .starships:
            return "starships/"
        case let .startshipWithId(id):
            return "starships/\(id)/"
        }
    }

    var method: HTTPMethods {
        switch self {
        case .starships, .startshipWithId:
            return .get
//        case .xxx:
//            return .post
        }
    }
    
    var header: RequestHeaderParameters {
        switch self {
        case .starships, .startshipWithId:
            return nil
//        case .xxx:
//            return ["Authorization" : "Bearer \(accessToken)"]
        }
        
    }

}
