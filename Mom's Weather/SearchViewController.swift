//
//  SearchViewController.swift
//  Mom's Weather
//
//  Created by David on 11/28/16.
//  Copyright © 2016 David. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit



class SearchViewController: UIViewController {
	
	@IBOutlet weak var searchTableView: UITableView!
	@IBOutlet weak var favTableView: UITableView!
	@IBOutlet weak var searchSpinner: UIActivityIndicatorView!
	@IBOutlet weak var connectionWarningView: UIView!
	@IBOutlet weak var accessWarningLabel: UILabel!

	
	var searchCompleter = MKLocalSearchCompleter()
	var searchController = UISearchController()
	var searchResults = [MKLocalSearchCompletion]()
	var results = [MKLocalSearchCompletion]()
	var search: MKLocalSearch? = nil
	var favorites = [Favorite]()
	var placeToDelete: Favorite?
	let coreDataStack = CoreDataStack.shared
	var changeColor = ChangeColor.shared
	var openWeatherClient = OpenWeatherClient.shared
	var controller: NSFetchedResultsController<Favorite>!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()

		searchCompleter.delegate = self
		searchController.loadViewIfNeeded()
		searchControllerSetting()
		fetchData()
		searchSpinner.stopAnimating()
		
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		connectionWarning()
		tableViewColor()
	}
}


extension SearchViewController: UISearchBarDelegate {
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		DispatchQueue.main.async {
			self.searchSpinner.startAnimating()
			self.searchCompleter.queryFragment = self.searchController.searchBar.text!
			self.searchCompleter.filterType = .locationsOnly
		}

	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchResults = []
		searchTableView.reloadData()
	}
}

extension SearchViewController: MKLocalSearchCompleterDelegate {
	
	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		DispatchQueue.main.async {
			self.searchResults = completer.results
			self.searchTableView.reloadData()
			self.searchSpinner.stopAnimating()
		}

	}
	
	func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
		connectionWarning()
	}
}


extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		if tableView.tag == 1 {
			return 1
		}
		guard let sections = controller.sections else {
			return 0
		}
		return sections.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		if tableView.tag == 1 {
			
			// filter cities out of given places
			results = searchResults.filter({ $0.title.contains(", ")})
			return results.count
			
		} else {
			guard let sections = controller.sections else {
				return 0
			}
			let currentSection = sections[section]
			return currentSection.numberOfObjects
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		if tableView.tag == 1 {
			
			let searchResult = results[indexPath.row]
			let cell = searchTableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! SearchCell
			
			cell.placeLabel.text = searchResult.title
			
			cell.tapAction = { cell in
				
				let favorite = Favorite(context: self.coreDataStack.context)
				favorite.place = cell.placeLabel.text
				self.favorites.append(favorite)
				DispatchQueue.main.async {
					self.coreDataStack.saveContext()
				}
			}			
			return cell
			
		} else {
			
			let cell = favTableView.dequeueReusableCell(withIdentifier: "favoriteCell", for: indexPath) as! FavoriteCell
			
			let favorite = controller.object(at: indexPath)
			cell.configureCell(favorite: favorite)
			
			cell.tapAction = { cell in
				self.placeToDelete = self.controller.object(at: indexPath)
				let alert = UIAlertController(title: "Delete favorite", message: "Are you sure you'd like to delete \"\((self.placeToDelete?.place)!)\" from the favorite list?", preferredStyle: .actionSheet)
				let deleteAction = UIAlertAction(title: "Delete", style: .default, handler: { [weak self] (action: UIAlertAction) in
					print("deleted")
					DispatchQueue.main.async {
						self?.coreDataStack.context.delete((self?.placeToDelete)!)
						self?.coreDataStack.saveContext()
					}
				})
				let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) in
					print("cancelled")
					
				})
				alert.addAction(deleteAction)
				alert.addAction(cancelAction)
				
				self.present(alert, animated: true, completion: nil)
			}
			
			return cell
		}
	}
	
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		
		let view = UIView()
		if tableView.tag == 2 {
			
			let label = UILabel()
			label.frame = CGRect(x: 5, y: 5, width: tableView.frame.width, height: 35)
			label.text = " Favorite Places"
			label.textColor = UIColor(red: 97/255, green: 109/255, blue: 115/255, alpha: 1.0)
			label.font = UIFont(name: "Chalkduster", size: 15.0)
			
			view.addSubview(label)
			return view
		}
		return view

	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		
		var height = CGFloat()
		if tableView.tag == 2 {
			height = 44
			return height
		}
		return height
	}
	
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if tableView.tag == 1 {
			DispatchQueue.main.async {
				self.searchSpinner.startAnimating()
				let cell = self.searchTableView.cellForRow(at: indexPath) as! SearchCell
				self.getCoordinates(place: "\(cell.placeLabel.text!)")
			}

		} else {
			DispatchQueue.main.async {
				self.searchSpinner.startAnimating()
				let cell = self.favTableView.cellForRow(at: indexPath) as! FavoriteCell
				self.getCoordinates(place: "\(cell.favoriteLabel.text!)")
			}
		}
	}
	
	func getCoordinates(place: String) {
		let geocoder = CLGeocoder()
		
		DispatchQueue.main.async {
			
			geocoder.geocodeAddressString(place) { (placemarks, error) in
				guard error == nil else {
					self.displayAlert((error?.localizedDescription)!, alertHandler: nil, presentationCompletionHandler: nil)
					return
				}
				self.searchSpinner.startAnimating()
				guard let placemark = placemarks?.last else {
					return
				}
				let location = Locations(context: self.coreDataStack.context)
				location.latitude = (placemark.location?.coordinate.latitude)!
				location.longitude = (placemark.location?.coordinate.longitude)!
				
				self.coreDataStack.saveContext()
				self.openWeatherClient.getCurrentData()
				self.openWeatherClient.getForecastData()
				self.searchSpinner.stopAnimating()
				let destination = self.storyboard?.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
				self.present(destination, animated: true, completion: nil)
			
			}
		}
		
	}
	
}

extension SearchViewController: NSFetchedResultsControllerDelegate {
	
	func fetchData() {
		
		let request = Favorite.fetch
		let sort = NSSortDescriptor(key: "place", ascending: true)
		request.sortDescriptors = [sort]
		
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: coreDataStack.context, sectionNameKeyPath: nil, cacheName: nil)
		self.controller = controller
		
		do {
			try controller.performFetch()
		} catch {
			let error = error as Error
			displayAlert(error.localizedDescription, alertHandler: nil, presentationCompletionHandler: nil)
		}
		self.controller.delegate = self
	}
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		searchTableView.beginUpdates()
		favTableView.beginUpdates()
	}

	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		
		switch type {
		case.insert:
			guard let indexPath = newIndexPath else {
				break
			}
			favTableView.insertRows(at: [indexPath], with: .fade)
		case.delete:
			guard let deletedIndexPath = indexPath else {
				break
			}
			favTableView.deleteRows(at: [deletedIndexPath], with: .fade)
		case.update:
			guard let updatedIndexPath = indexPath else {
				break
			}
			favTableView.reloadRows(at: [updatedIndexPath], with: .fade)
			
		case.move:
			if let indexPath = indexPath {
				favTableView.deleteRows(at: [indexPath], with: .fade)
			}
			if let indexPath = newIndexPath  {
				favTableView.insertRows(at: [indexPath], with: .fade)

			}
			
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		searchTableView.endUpdates()
		favTableView.endUpdates()
	}
}

extension Favorite {
	
	class var fetch: NSFetchRequest<Favorite> {
		return NSFetchRequest<Favorite>(entityName: "Favorite")
	}
	
}


