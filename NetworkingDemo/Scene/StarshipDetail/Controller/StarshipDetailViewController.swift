//
//  StarshipDetailViewController.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 5.11.2020.
//  Copyright (c) 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import UIKit
import Networking

// MARK: - Starship Detail View Controller
final class StarshipDetailViewController: UIViewController {
    var interactor: StarshipDetailBusinessLogic?
    var router: (NSObjectProtocol & StarshipDetailRoutingLogic)?
    
    @IBOutlet weak var tableView: UITableView! {
        willSet {
            newValue.estimatedRowHeight = UITableView.automaticDimension
            newValue.rowHeight = 60
            newValue.separatorStyle = .singleLine
            newValue.backgroundColor = .clear
            newValue.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 80, right: 0)
            newValue.allowsSelection = false
        }
    }
    
    var starshipId: String?
    var starship: StarshipModel?
    var cellTypes: [CellType] = []
    
    enum CellType {
        case name
        case model
        case manufacturer
        case costInCredits
        case length
        case maxAtmospheringSpeed
        case crew
        case passengers
        case cargoCapacity
    }
    
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
        let interactor = StarshipDetailInteractor()
        let presenter = StarshipDetailPresenter()
        let router = StarshipDetailRouter()
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
        getStarshipWithId()
    }
    
    private func setupView() {
        self.title = "Starship Detail"
    }
    
    private func setupTableView() {
        tableView.register(StarshipDetailTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    /// Get StarshipModel again to use network request with parameter
    private func getStarshipWithId() {
        guard let id = starshipId else {
            return
        }
        let request = StarshipDetail.Startship.Request(id: id)
        interactor?.getStarshipWithId(request: request)
    }
    
}

// MARK: - Display Logic
extension StarshipDetailViewController: StarshipDetailDisplayLogic {
    
    func displayStarshipWithIdSuccess(response: StarshipModel) {
        starship = response
        cellTypes = [.name, .model, .manufacturer, .costInCredits, .length, .maxAtmospheringSpeed, .crew, .passengers, .cargoCapacity]
        tableView.reloadData()
    }
    
    func displayStarshipWithIdFail(error: ErrorModel) {
        debugPrint("fail")
    }
    
}

// MARK: - Table View Delegate & Data Source
extension StarshipDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return configureTableViewCell(indexPath: indexPath)
    }
    
    private func configureTableViewCell(indexPath: IndexPath) -> StarshipDetailTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as StarshipDetailTableViewCell
        guard let model = starship else {
            cell.configureCell(text: "")
            return cell
        }
        switch cellTypes[indexPath.row] {
        case .name: cell.configureCell(text: "Name: \(model.name ?? "")")
        case .model: cell.configureCell(text: "Model: \(model.model ?? "")")
        case .manufacturer: cell.configureCell(text: "Manufacrurer: \(model.manufacturer ?? "")")
        case .costInCredits: cell.configureCell(text: "Cost In Credits: \(model.cost_in_credits ?? "")")
        case .length: cell.configureCell(text: "Length: \(model.length ?? "")")
        case .maxAtmospheringSpeed: cell.configureCell(text: "Max Atmosphering Speed: \(model.max_atmosphering_speed ?? "")")
        case .crew: cell.configureCell(text: "Crew: \(model.crew ?? "")")
        case .passengers: cell.configureCell(text: "Passengers: \(model.passengers ?? "")")
        case .cargoCapacity: cell.configureCell(text: "Cargo Capacity: \(model.cargo_capacity ?? "")")
        }
        return cell
    }
    
}
