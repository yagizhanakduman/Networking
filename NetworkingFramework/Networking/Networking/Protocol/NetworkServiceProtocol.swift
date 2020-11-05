//
//  NetworkServiceProtocol.swift
//  Networking
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

public protocol NetworkServiceProtocol {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethods { get }
    var header: RequestHeaderParameters { get }
}
