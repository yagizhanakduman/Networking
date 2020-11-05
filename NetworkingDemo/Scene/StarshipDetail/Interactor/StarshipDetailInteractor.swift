//
//  StarshipDetailInteractor.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 5.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import UIKit

// MARK: Starship Detail Interactor
final class StarshipDetailInteractor: StarshipDetailBusinessLogic {
    var presenter: StarshipDetailPresentationLogic?
    var worker: StarshipDetailWorker?
    
    func getStarshipWithId(request: StarshipDetail.Startship.Request) {
        worker = StarshipDetailWorker()
        worker?.getStarshipWithId(request: request, success: { result in
            let response = StarshipDetail.Startship.Response(model: result, error: nil)
            self.presenter?.presentStarshipWithId(response: response)
        }, fail: { error in
            let response = StarshipDetail.Startship.Response(model: nil, error: error)
            self.presenter?.presentStarshipWithId(response: response)
        })
    }
    
}
