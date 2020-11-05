//
//  FileModel.swift
//  Networking
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

// MARK: File Model to Upload Picture, Sound etc.
public struct FileModel: Codable {
 
    var file: Data?
    var fileName: String?
    var mimeType: String?
    var parameters: [String : String]?
    
    enum CodingKeys: String, CodingKey {
        case file = "file"
        case fileName = "fileName"
        case mimeType = "mimeType"
        case parameters = "parameters"
    }
    
}
