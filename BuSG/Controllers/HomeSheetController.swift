//
//  HomeSheetController.swift
// BuSG
//
//  Created by Ryan The on 28/11/20.
//

import UIKit
import CoreLocation

class HomeSheetController: SheetController {

    lazy var tableView = UITableView(frame: CGRect(), style: .grouped)
    
    lazy var refreshControl = UIRefreshControl(frame: CGRect(), primaryAction: UIAction(handler: { _ in
        self.reloadData()
    }))
    
    var searchText: String = ""
    
    var suggestedServices: [BusSuggestion] = []
    
    var nearbyStops: [BusStop] = []
    
    private func reloadData() {
        nearbyStops = ApiProvider.shared.getBusStops(nearby: LocationProvider.shared.currentLocation.coordinate)
        ApiProvider.shared.getSuggestedServices { busData in
            self.suggestedServices = busData
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search for a bus stop or service"
        searchBar.delegate = self
        headerView.searchBar = searchBar
        
        tableView.addSubview(refreshControl)
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        
        contentView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: tableView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
        ])
        
        tableView.register(BusServiceTableViewCell.self, forCellReuseIdentifier: K.identifiers.busServiceCell)
        tableView.register(BusSuggestionTableViewCell.self, forCellReuseIdentifier: K.identifiers.busSuggestedCell)

        reloadData()
    }
}

extension HomeSheetController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return suggestedServices.isEmpty ? nearbyStops.count : suggestedServices.count
        case 1: fallthrough
        default: return nearbyStops.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        suggestedServices.isEmpty ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return suggestedServices.isEmpty ? "Nearby" : "Suggested"
        case 1: fallthrough
        default: return "Nearby"
        }
    }
        
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return suggestedServices.isEmpty ? 85 : 55
        case 1: fallthrough
        default: return 85
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let suggestedCell = { () -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: K.identifiers.busSuggestedCell, for: indexPath) as! BusSuggestionTableViewCell
            cell.eventImage = UIImage(systemName: "calendar")
            cell.serviceNoLabel.text = self.suggestedServices[indexPath.row].busService.serviceNo
            cell.destinationLabel.text = self.suggestedServices[indexPath.row].originBusStop.rawRoadDesc
            cell.eventLabel.text = self.suggestedServices[indexPath.row].event.title
            return cell
        }
        let nearbyCell = { () -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: K.identifiers.busServiceCell, for: indexPath) as! BusServiceTableViewCell
            let nearbyStopData = self.nearbyStops[indexPath.row]
            cell.busServices = nearbyStopData.busServices
            cell.roadDescLabel.text = nearbyStopData.roadDesc
            cell.busStopCodeLabel.text = nearbyStopData.busStopCode
            cell.roadNameLabel.text = nearbyStopData.roadName
            let distance = LocationProvider.shared.distanceFromCurrentLocation(to: CLLocation(latitude: nearbyStopData.latitude, longitude: nearbyStopData.longitude))
            if distance > 100 {
                cell.distanceLabel.text = "\(String(format: "%.2f", distance/1000)) km"
            } else {
                cell.distanceLabel.text = "\(String(format: "%.1f", distance)) m"
            }
            
            return cell
        }
        switch indexPath.section {
        case 0: return suggestedServices.isEmpty ? nearbyCell() : suggestedCell()
        case 1: fallthrough
        default: return nearbyCell()
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            present(BusStopSheetController(for: suggestedServices.isEmpty ? nearbyStops[indexPath.row].busStopCode : suggestedServices[indexPath.row].originBusStop.busStopCode), animated: true)
        case 1: fallthrough
        default:
            present(BusStopSheetController(for: nearbyStops[indexPath.row].busStopCode), animated: true)
        }
    }
}

extension HomeSheetController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let closeButton = UIButton(type: .system, primaryAction: UIAction(handler: { _ in
            searchBar.resignFirstResponder()
        }))
        closeButton.setTitle("Cancel", for: .normal)
        headerView.trailingButton = closeButton
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        self.tableView.reloadData()
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        headerView.trailingButton = nil
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension HomeSheetController: SheetControllerDelegate {
    
    func sheetController(_ sheetController: SheetController, didUpdate state: SheetState) {
        UIView.animate(withDuration: 0.3) {
            switch state {
            case .minimized:
                self.tableView.layer.opacity = 0
            default:
                self.tableView.layer.opacity = 1
            }
        }
    }

    func sheetController(_ sheetController: SheetController, didReturnFromDismissalBy presentingSheetController: SheetController) {
        LocationProvider.shared.delegate?.locationProviderDidRequestNavigateToCurrentLocation()
    }
    
}
