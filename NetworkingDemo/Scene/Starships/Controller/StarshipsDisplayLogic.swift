//
//  StarshipsDisplayLogic.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 1.11.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation
import Networking

protocol StarshipsDisplayLogic: class {
    func displayAllStarshipsSuccess(response: AllStarshipsModel)
    func displayFail(error: ErrorModel)
}
