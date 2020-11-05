//
//  StarshipsWorker.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 1.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation
import Networking

// MARK: Star Wars Worker For API Call & Parse
final class StarshipsWorker {
    
    func getStarships(success: @escaping(AllStarshipsModel) -> Void, fail: @escaping(ErrorModel) -> Void) {
        let manager = DemoNetworkManager()
        manager.getStarships(success: { resultModel in
            if let response = resultModel.getModel(type: AllStarshipsModel.self) {
                success(response)
            } else {
                let errorModel = ErrorModel(networkErrorTypes: .parseError)
                fail(errorModel)
            }
        }, fail: { errorModel in
            fail(errorModel)
        })
    }
    
}
