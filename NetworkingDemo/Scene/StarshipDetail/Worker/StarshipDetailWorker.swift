//
//  StarshipDetailWorker.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 5.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation
import Networking

// MARK: Starship Detail Worker
final class StarshipDetailWorker {
    
    func getStarshipWithId(request: StarshipDetail.Startship.Request, success: @escaping(StarshipModel) -> Void, fail: @escaping(ErrorModel) -> Void) {
        let id = request.id
        let manager = DemoNetworkManager()
        manager.getStarshipWithId(id: id, success: { resultModel in
            if let response = resultModel.getModel(type: StarshipModel.self) {
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
