//
//  StarshipDetailModels.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 5.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation
import Networking

// MARK: Startship Detail Use Cases
enum StarshipDetail {
    
    enum Startship {
        struct Request {
            var id: String
        }
        
        struct Response {
            var model: StarshipModel?
            var error: ErrorModel?
        }
        
        struct ViewModel {
        }
    }
}
