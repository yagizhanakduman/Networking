//
//  StarshipDetailPresenter.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 5.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import UIKit
import Networking

// MARK: Starship Detail Presenter
final class StarshipDetailPresenter: StarshipDetailPresentationLogic {
    weak var viewController: StarshipDetailDisplayLogic?
    
    func presentStarshipWithId(response: StarshipDetail.Startship.Response) {
        if let error = response.error {
            viewController?.displayStarshipWithIdFail(error: error)
            return
        }
        guard let model = response.model else {
            viewController?.displayStarshipWithIdFail(error: ErrorModel(networkErrorTypes: .emptyError))
            return
        }
        viewController?.displayStarshipWithIdSuccess(response: model)
    }
    
}
