//
//  StarshipDetailPresentationLogic.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 5.11.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

protocol StarshipDetailPresentationLogic: class {
    func presentStarshipWithId(response: StarshipDetail.Startship.Response)
}
