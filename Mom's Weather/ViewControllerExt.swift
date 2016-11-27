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
import CoreLocation

extension MainViewController {
	
	func locationAuthStatus() {
		
		
		let status = CLLocationManager.authorizationStatus()
		
		switch status {
		case .notDetermined:
			requestAccessToLocation()
		case .authorizedWhenInUse:
			print("authorized")
		case .denied:
			print("alerted")
			alertToLocationAccess()
		case .restricted:
			break
		default:
			print("no authorization")
			
		}

	}
	
	func locationManagerSetting() {
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
		locationManager.startUpdatingLocation()
		
	}
	
	func requestAccessToLocation() {
		locationManager.requestWhenInUseAuthorization()
	}
	
	func getCurrentLocation() {
	
		currentLocation = locationManager.location
		location.latitude = currentLocation?.coordinate.latitude ?? 0.00
		location.longitude = currentLocation?.coordinate.longitude ?? 0.00
		
		var savedLocation = Locations(context: coreDataStack.context)
		savedLocation.latitude = location.latitude
		savedLocation.longitude = location.longitude
		
		coreDataStack.saveContext()
		
		
		guard CLLocationManager.locationServicesEnabled() else {
			
			do {
				let newLocation = try coreDataStack.context.fetch(Locations.fetch)
				print("newLocation: \(newLocation.first?.latitude), \(newLocation.last?.latitude)")
				location.latitude = newLocation.last?.latitude
				location.longitude = newLocation.last?.longitude
			} catch {
				fatalError("no location info")
			}
			
			return
		}
	}
	
	
	func showCurrentDate() -> String {
		
		let currentDate = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEE, MMM dd"
		let today = dateFormatter.string(from: currentDate)
		self.date.text = today
		
		return self.date.text!
	}
	
	func alertToLocationAccess() {
		let alert = UIAlertController(title: "Location services for this app are disabled", message: "Your location is used to display local weather forecasts. Do you allow location access to \"While Using the App\"?", preferredStyle: .alert)
		let settingAction = UIAlertAction(title: "OpenSetting", style: .default) { _ -> Void in
			guard let url = URL(string: "prefs:root=General") else {
				return
			}
			if UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url, completionHandler: { (success) in
					print("settings opened")
				})
			}
		}
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		
		alert.addAction(cancelAction)
		present(alert, animated: true, completion: nil)
	}
	
}

extension DetailedViewController {
	
	func configureTableView() {
		
		calendarTableView.delegate = self
		calendarTableView.dataSource = self
		
	}
	
	func configureCollectionView() {
		collectionView.delegate = self
		collectionView.dataSource = self
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
			print("no access")
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
		let endDate = Date(timeIntervalSinceNow: 60*60*24)
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
	
	func dateChecked() -> String {
		
		let currentTime = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH"
		let now = dateFormatter.string(from: currentTime)

		var tomorrow: Date {
			return NSCalendar.current.date(byAdding: .day, value: 1, to: currentTime)!
		}
		
		if Int(now)! >= 14 {
			dateFormatter.dateFormat = "EEE, MMM dd"
			let dayAfter = dateFormatter.string(from: tomorrow)
			return dayAfter
		} else {
			dateFormatter.dateFormat = "EEE, MMM dd"
			let currentDate = dateFormatter.string(from: currentTime)
			return "\(currentDate)"
		}
	}
	
	func showCurrentDate() -> String {
		
		let currentDate = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEE, MMM dd"
		let today = dateFormatter.string(from: currentDate)
		self.date.text = today
		
		return self.date.text!
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
}


