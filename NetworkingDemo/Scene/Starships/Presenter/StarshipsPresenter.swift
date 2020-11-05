//
//  StarshipsPresenter.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 1.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import UIKit
import Networking

// MARK: Star Wars Presenter
final class StarshipsPresenter: StarshipsPresentationLogic {
    weak var viewController: StarshipsDisplayLogic?
    
    func presentStarships(response: Starships.Starships.Response){
        if let error = response.error {
            viewController?.displayFail(error: error)
            return
        }
        guard let model = response.model else {
            viewController?.displayFail(error: ErrorModel(networkErrorTypes: .emptyError))
            return
        }
        viewController?.displayAllStarshipsSuccess(response: model)
    }
    
}
