//
//  DemoNetworkManager.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation
import Networking

// MARK: - Demo Network Manager
final class DemoNetworkManager {
    
    let manager: NetworkManager
    var defaultHeaders: [String : String] = ["Content-Type" : "application/json"]
    
    /// Network Manager Configuration
    init() {
        manager = NetworkManager()
        manager.setDefaultHeaders(defaultHeaders)
        /// Specific JSON Key for Result
        //manager.setJsonKey(["xxx"])
        /// Custom Settings
        //manager.setNetworkLearning(DemoNetworkLearning())
    }
    
}

// MARK: - Starship
extension DemoNetworkManager {
    
    func getStarships(success: @escaping (ResultModel<AllStarshipsModel>) -> Void, fail: @escaping (ErrorModel) -> Void) {
        manager.request(networkService: DemoNetworkConfig.starships, success: success, fail: fail)
    }
    
    func getStarshipWithId(id: String, success: @escaping (ResultModel<StarshipModel>) -> Void, fail: @escaping (ErrorModel) -> Void) {
        manager.request(networkService: DemoNetworkConfig.startshipWithId(id), success: success, fail: fail)
    }
    
}

// MARK: - Sample Post
extension DemoNetworkManager {
    
    /*func postSomething(somethingId: String, model: SomethingRequestModel, success: @escaping (ResultModel<SomethingResultModel>) -> Void, fail: @escaping (ErrorModel) -> Void) {
        manager.requestWithBody(networkService: DemoNetworkConfig.something(somethingId: somethingId), bodyParameters: model, success: success, fail: fail)
    }*/
    
}
