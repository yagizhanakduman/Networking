//
//  StarshipsViewController.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 1.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import UIKit
import Networking

// MARK: - Star Wars View Controller
final class StarshipsViewController: UIViewController {
    var interactor: StarshipsBusinessLogic?
    var router: (NSObjectProtocol & StarshipsRoutingLogic)?
    
    @IBOutlet weak var tableView: UITableView! {
        willSet {
            newValue.estimatedRowHeight = UITableView.automaticDimension
            newValue.rowHeight = 60 
            newValue.separatorStyle = .singleLine
            newValue.backgroundColor = .clear
            newValue.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 80, right: 0)
        }
    }
    
    var allStarships: AllStarshipsModel?
    var starships: [StarshipModel] = []
    
    // MARK: Object lifecycle
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Setup
    private func setup() {
        let viewController = self
        let interactor = StarshipsInteractor()
        let presenter = StarshipsPresenter()
        let router = StarshipsRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
    }
    
    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTableView()
        getStarships()
    }
    
    private func setupView() {
        self.title = "Starships"
    }
    
    private func setupTableView() {
        tableView.register(StarshipsTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func getStarships() {
        interactor?.getStarships()
    }
    
}

// MARK: - Display Logic
extension StarshipsViewController: StarshipsDisplayLogic {
    
    func displayAllStarshipsSuccess(response: AllStarshipsModel) {
        allStarships = response
        guard let results = response.results else {
            return
        }
        starships = results
        tableView.reloadData()
    }
    
    func displayFail(error: ErrorModel) {
        debugPrint("fail")
    }
    
}

// MARK: - Table View Delegate & Data Source
extension StarshipsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return starships.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return configureStarshipsTableViewCell(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        getIdFromURL(index: indexPath.row)
    }
    
    private func configureStarshipsTableViewCell(indexPath: IndexPath) -> StarshipsTableViewCell{
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as StarshipsTableViewCell
        cell.configureCell(starship: starships[indexPath.row])
        return cell
    }
    
    private func getIdFromURL(index: Int) {
        guard let url = starships[index].url else {
            return
        }
        let id = url.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        routeToStarshipDetail(id: id, starship: starships[index])
    }
    
    private func routeToStarshipDetail(id: String, starship: StarshipModel) {
        router?.routeToStarshipDetail(id: id, starship: starship)
    }
    
}
