//
//  StarshipsRouter.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 1.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import UIKit

// MARK: Star Wars Router
final class StarshipsRouter: NSObject, StarshipsRoutingLogic {
    weak var viewController: StarshipsViewController?
 
    func routeToStarshipDetail(id: String, starship: StarshipModel) {
        let detailVC = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "StarshipDetailViewController") as! StarshipDetailViewController
        detailVC.starshipId = id
        detailVC.starship = starship
        viewController?.navigationController?.pushViewController(detailVC, animated: true)
    }
    
}
