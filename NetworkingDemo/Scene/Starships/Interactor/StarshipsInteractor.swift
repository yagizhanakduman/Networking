//
//  StarshipsInteractor.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 1.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import UIKit

// MARK: Star Wars Interactor
final class StarshipsInteractor: StarshipsBusinessLogic {
    var presenter: StarshipsPresentationLogic?
    var worker: StarshipsWorker?
    
    func getStarships() {
        worker = StarshipsWorker()
        worker?.getStarships(success: { result in
            let response = Starships.Starships.Response(model: result, error: nil)
            self.presenter?.presentStarships(response: response)
        }, fail: { error in
            let response =  Starships.Starships.Response(model: nil, error: error)
            self.presenter?.presentStarships(response: response)
        })
    }
    
}
