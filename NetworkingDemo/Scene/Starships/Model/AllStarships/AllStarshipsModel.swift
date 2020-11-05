//
//  AllStarshipsModel.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 1.11.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

struct AllStarshipsModel: Codable {
    
    var count: Int?
    var next: String?
    var previous: String?
    var results: [StarshipModel]?
    
    enum CodingKeys: String, CodingKey {
        case count = "count"
        case next = "next"
        case previous = "previous"
        case results = "results"
    }
    
}
