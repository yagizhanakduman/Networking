//
//  StarshipModel.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 1.11.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

struct StarshipModel: Codable {
    
    var name: String?
    var model: String?
    var manufacturer: String?
    var cost_in_credits: String?
    var length: String?
    var max_atmosphering_speed: String?
    var crew: String?
    var passengers: String?
    var cargo_capacity: String?
    var consumables: String?
    var hyperdrive_rating: String?
    var MGLT: String?
    var starship_class: String?
    var url: String?
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case model = "model"
        case manufacturer = "manufacturer"
        case cost_in_credits = "cost_in_credits"
        case length = "length"
        case max_atmosphering_speed = "max_atmosphering_speed"
        case crew = "crew"
        case passengers = "passengers"
        case cargo_capacity = "cargo_capacity"
        case consumables = "consumables"
        case hyperdrive_rating = "hyperdrive_rating"
        case MGLT = "MGLT"
        case starship_class = "starship_class"
        case url = "url"
    }
    
}
