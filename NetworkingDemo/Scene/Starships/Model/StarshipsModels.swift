//
//  StarshipsModels.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 1.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation
import Networking

// MARK: Star Wars Use Cases
enum Starships {
    
    enum Starships {
        struct Request {
        }
        
        struct Response {
            var model: AllStarshipsModel?
            var error: ErrorModel?
        }
        
        struct ViewModel {
        }
    }
    
}
