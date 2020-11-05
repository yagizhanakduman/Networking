//
//  StarshipsRoutingLogic.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 1.11.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

protocol StarshipsRoutingLogic: class {
    func routeToStarshipDetail(id: String, starship: StarshipModel)
}
