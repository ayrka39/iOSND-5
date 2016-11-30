//
//  SearchViewController.swift
//  Mom's Weather
//
//  Created by David on 11/28/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CoreLocation
import MapKit


class SearchViewController: UIViewController {
	
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var mapView: MKMapView!
	
	var places: [String] = []
	var filtedPlaces: [String] = []
	var inSearchMode = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		searchBar.returnKeyType = UIReturnKeyType.done
	}
	
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return places.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as? SearchCell else {
			return SearchCell()
		}
		
		let place: Locations!
		
		return cell
	}
	
}

extension SearchViewController: UISearchBarDelegate {
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		
		view.endEditing(true)
	}
	
	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		
		guard searchBar.text != nil || searchBar.text != "" else {
			inSearchMode = false
			tableView.reloadData()
			view.endEditing(true)
			return
		}
		
		inSearchMode = true
		let lowerCase = searchBar.text!.lowercased()
		filtedPlaces = places.filter({ $0.range(of: lowerCase) != nil})
		tableView.reloadData()
	}
}
