//
//  ViewControllerExt.swift
//  Mom's Weather
//
//  Created by David on 11/18/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import UIKit
import EventKit
import CoreData
import CoreLocation

// MARK: MainViewController extension

extension MainViewController {
	
	func locationAuthStatus() {
		
		let status = CLLocationManager.authorizationStatus()
	
			switch status {
			case .notDetermined:
				requestAccessToLocation()
			case .authorizedWhenInUse:
				print("accessed")
			case .denied:
				print("alerted")
				alertToLocationAccessDenied()
			case .restricted:
				if Reachability.isInternetAvailable() == false {
					alertToLocationAccessRestricted()
				}
			default:
				print("no access")
			}
		}
	
	func locationManagerSetting() {
		
		if Reachability.isInternetAvailable() == false {
			print("reachability works")
			if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
				connectionWarningView.isHidden = true
				print("fallthrough")
			} else {
				print("access alert")
				centerPopup.constant = 0
				currentWeatherView.isHidden = true
				morningView.isHidden = true
				afternoonView.isHidden = true
			}
		}
		
	}
	
	func requestAccessToLocation() {
		locationManager.requestWhenInUseAuthorization()
	}

	func deleteCurrentRecords() {
		
		if Reachability.isInternetAvailable() == true {
			let object = fetchedCurrentData.last
			print("obj: \(object)")
			guard object == nil else {
				let currentDataRequest = CurrentWeather.fetch
				do {
					let deleteRequest = NSBatchDeleteRequest(fetchRequest: currentDataRequest as! NSFetchRequest<NSFetchRequestResult>)
					_ = try coreDataStack.context.execute(deleteRequest)
					
					coreDataStack.saveContext()
				} catch {
					fatalError("Failed removing saved records")
				}

				return
			}
			print("//1")
			openWeatherClient.getCurrentWeatherData()
			
		}
	}
	
	func deleteForecastRecords() {
		
		if Reachability.isInternetAvailable() == true {
			
			let forecastDataRequest = Forecast.fetch
			
			do {
				let deleteRequest = NSBatchDeleteRequest(fetchRequest: forecastDataRequest as! NSFetchRequest<NSFetchRequestResult>)
				_ = try CoreDataStack.shared.context.execute(deleteRequest)
				
			} catch {
				fatalError("Failed removing saved records")
			}
		}
	}
	
	func upcomingDataSpinnerStart() {
		morningDataSpinner.startAnimating()
		afternoonDataSpinner.startAnimating()
	}
	
	func upcomingDataSpinnerStop() {
		morningDataSpinner.stopAnimating()
		afternoonDataSpinner.stopAnimating()
	}
	
	func showCurrentDate() -> String {
		
		let currentDate = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEE, MMM dd"
		let today = dateFormatter.string(from: currentDate)
		self.date.text = today
		
		return self.date.text!
	}
	
	// get a formatted date value from parsed data
	func extractDate(dateNumber: Double) -> String {
		let convertedDate = Date(timeIntervalSince1970: dateNumber)
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEE, MMM dd"
		let date = dateFormatter.string(from: convertedDate)
		return date
		
	}
	
	func alertToLocationAccessDenied() {
		let alert = UIAlertController(title: "Location services for this app are disabled", message: "Your location is used to display local weather forecasts. Do you allow location access to \"While Using the App\"?", preferredStyle: .alert)
		let settingAction = UIAlertAction(title: "OpenSetting", style: .default) { _ -> Void in
			guard let url = URL(string: UIApplicationOpenSettingsURLString) else {
				return
			}
			if UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url, completionHandler: { (success) in
					print("settings opened")
				})
			}
		}
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alert.addAction(settingAction)
		alert.addAction(cancelAction)
		present(alert, animated: true, completion: nil)
	}
	
	func alertToLocationAccessRestricted() {
		let alert = UIAlertController(title: "Location services for this app are restricted", message: "Please check if Internet connection is available", preferredStyle: .alert)
		let OkAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alert.addAction(OkAction)
		alert.addAction(cancelAction)
		present(alert, animated: true, completion: nil)
	}

}

// MARK: DetailedViewController extension

extension DetailedViewController {
	
	
	func connectionWarning() {
		
		if Reachability.isInternetAvailable() == false {
			
			if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
				connectionWarningView.isHidden = true
				print("fallthrough")
			} else {
				print("access alert")
				connectionWarningView.isHidden = false
			}
		} else {
			connectionWarningView.isHidden = true
			calendarAuthStatus()
		}

	}
	
	
	func calendarAuthStatus() {
	
		let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
		
		switch status {
		case EKAuthorizationStatus.notDetermined:
			requestAccessToCalendar()
		case EKAuthorizationStatus.authorized:
			loadEvents()
			refreshTableView()
		case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
			alertToLocationAccessRestricted()
		}
	}

	func requestAccessToCalendar() {
		
		eventStore.requestAccess(to: EKEntityType.event, completion: {
			(accessGranted: Bool, error: Error?) in
			
			if accessGranted == true {
				DispatchQueue.main.async(execute: {
					self.loadEvents()
					self.refreshTableView()
				})
			} else {
				DispatchQueue.main.async(execute: {
					print("no calendar")
				})
			}
		})
	}
	
	
	func loadEvents() {

		let startDate = Date()
		let endDate = Date(timeIntervalSinceNow: 60*60*24*30)
		let eventsPredicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
			
		self.events = eventStore.events(matching: eventsPredicate).sorted() { (event1: EKEvent, event2: EKEvent) -> Bool in
			
			return event1.startDate.compare(event2.startDate) == ComparisonResult.orderedAscending
		}
		
	}
	
	func refreshTableView() {
		calendarTableView.isHidden = false
		calendarTableView.reloadData()
	}
	
	func refreshCollectionView() {
		collectionView.reloadData()
	}
	

	func showEventDate(startDate: Date) -> String {
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH:mm"
		let eventDate = dateFormatter.string(from: startDate)
		if eventDate == "00:00" {
			return "🔆"
		}
		return eventDate
	}
	
	func alertToLocationAccessRestricted() {
		let alert = UIAlertController(title: "Calendar for this app is restricted", message: "Please check if Internet connection is available", preferredStyle: .alert)
		let OkAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alert.addAction(OkAction)
		alert.addAction(cancelAction)
		present(alert, animated: true, completion: nil)
	}

	
	// get a formatted date value from parsed data
	func extractDate(dateNumber: Date) -> String {
		let today = Date()
		let forecastDate: Date!
		if today != dateNumber {
			forecastDate = dateNumber.addingTimeInterval(-60*60*24)
		} else {
			forecastDate = dateNumber
		}
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEE, MMM dd"
		let date = dateFormatter.string(from: forecastDate)
		return date
		
	}
}

// MARK: SearchViewController extension

extension SearchViewController {
	
	func connectionWarning() {
		
		if Reachability.isInternetAvailable() == false {
			print("reachability works - search")
			if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
				connectionWarningView.isHidden = true
				print("fallthrough")
			} else {
				print("access alert")
				connectionWarningView.isHidden = false
			}
		} else {
			connectionWarningView.isHidden = true
			
		}
		
	}
	
	func searchControllerSetting() {
		
		searchController = UISearchController(searchResultsController: nil)
		searchController.dimsBackgroundDuringPresentation = false
		searchController.isActive = true
		searchController.searchBar.delegate = self
		searchController.searchBar.barTintColor = UIColor(red: 135/255, green: 206/255, blue: 250/255, alpha: 1.0)
		searchController.searchBar.placeholder = "Search for places here"
		searchController.searchBar.sizeToFit()
		searchController.searchBar.searchBarStyle = .minimal
		searchController.searchBar.isTranslucent = false
		searchTableView.tableHeaderView = searchController.searchBar
		definesPresentationContext = true
	}
	
	func tableViewColor() {
		
		self.changeColor.viewColor(icon: #imageLiteral(resourceName: "02d"), view: searchTableView)
		self.changeColor.viewGradient(view: searchTableView, start: 1.0, end: 0.1)
		
		self.changeColor.viewColor(icon: #imageLiteral(resourceName: "01d"), view: favTableView)
		self.changeColor.viewGradient(view: favTableView, start: 0.1, end: 1.0)
		
	}
}
