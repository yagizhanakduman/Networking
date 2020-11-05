//
//  StarshipDetailDisplayLogic.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 5.11.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation
import Networking

protocol StarshipDetailDisplayLogic: class {
    func displayStarshipWithIdSuccess(response: StarshipModel)
    func displayStarshipWithIdFail(error: ErrorModel)
}
