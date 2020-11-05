//
//  BaseModel.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

struct BaseModel: Codable {
    
    var isSuccess: Bool?
    var statusCode: Int?
    var userMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case isSuccess = "isSuccess"
        case statusCode = "statusCode"
        case userMessage = "userMessage"
    }
    
}
