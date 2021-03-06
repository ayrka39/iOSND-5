//
//  HourlyTest.swift
//  Mom's Weather
//
//  Created by David on 11/17/16.
//  Copyright © 2016 David. All rights reserved.
//


import UIKit
import EventKit
import CoreData


class DetailedViewController: UIViewController {
	
	@IBOutlet weak var date: UILabel!
	@IBOutlet weak var location: UILabel!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var calenrView: UIView!
	@IBOutlet weak var calendarTableView: UITableView!
	@IBOutlet weak var thingsView: UIView!
	@IBOutlet weak var connectionWarningView: UIView!
	@IBOutlet weak var warningLabel: UILabel!

	var changeColor = ChangeColor.shared
	var forecasts: [Forecast]?
	let eventStore = EKEventStore()
	var calendars: [EKCalendar]?
	var events: [EKEvent]?
	var fetchedController: NSFetchedResultsController<Forecast>?
	let sectionInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 2.0)
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		connectionWarning()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		fetchData()
		refreshCollectionView()
		changeThings()
		calendarViewColor()
	}
	
	func fetchData() {
		
		let fetchRequest = Forecast.fetch
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
		
		do {
			forecasts = try CoreDataStack.shared.context.fetch(fetchRequest)
			
		} catch {
			let error = error as Error
			displayAlert(error.localizedDescription, alertHandler: nil, presentationCompletionHandler: nil)
		}

	}
	
	func changeThings() {
	
		DispatchQueue.main.async {
			
				let imageOne = self.thingsView.viewWithTag(1) as! UIImageView
				let imageTwo = self.thingsView.viewWithTag(2) as! UIImageView
				let imageThree = self.thingsView.viewWithTag(3) as! UIImageView
				
				
				guard let ninthHour = self.forecasts?.index(where: { $0.hours == "09" }),
					let fifteenthHour = self.forecasts?.index(where: { $0.hours == "15" }) else {
						self.displayAlert("Network appears to be slow. \n\nPlease try to fetch data again", alertHandler: nil, presentationCompletionHandler: nil)
						return
				}
				var altered = 0
				if ninthHour > fifteenthHour {
					altered = ninthHour + 2
				} else {
					altered = fifteenthHour
				}
				let status = true
				
				switch status {
				case (self.forecasts?[ninthHour...altered].contains(where: {($0.icon == "01d" || $0.icon == "01n") && $0.maxTemp >= 20}))!:
					imageOne.image = #imageLiteral(resourceName: "sunglasses")
					imageTwo.image = #imageLiteral(resourceName: "sunscreen")
					imageThree.image = #imageLiteral(resourceName: "waterbottle")
				case (self.forecasts?[ninthHour...altered].contains(where: { $0.maxTemp >= 20 && !($0.icon! == "01d" || $0.icon! == "01n")}))!:
					imageOne.image = #imageLiteral(resourceName: "waterbottle")
					imageTwo.image = #imageLiteral(resourceName: "sunglasses")
				case (self.forecasts?[ninthHour...altered].contains(where: { $0.icon == "09d" || $0.icon == "09d" || $0.icon == "10d" || $0.icon == "10n" }))!:
					imageOne.image = #imageLiteral(resourceName: "raincoat")
					imageTwo.image = #imageLiteral(resourceName: "rubberboots")
				case (self.forecasts?[ninthHour...altered].contains(where: { $0.minTemp <= 5 && $0.icon != ""}))!:
					imageOne.image = #imageLiteral(resourceName: "sweatshirtb")
				default:
					imageOne.image = #imageLiteral(resourceName: "anything")
				}
	
			self.changeColor.viewColor(icon: UIImage(named: self.weatherIconForViewColor(forecastIndex: 1))!, view: self.thingsView)
			self.changeColor.viewGradient(view: self.thingsView, start: 1.0, end: 0.1)
		}
	}
}

extension DetailedViewController: UICollectionViewDelegate, UICollectionViewDataSource {

	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		
		guard let count = forecasts?.count else {
			return 0
		}
		return count
		
	}
	

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "weatherCell", for: indexPath) as! WeatherCell

		guard let forecast = forecasts?[indexPath.item] else {
			
			return cell
		}
		
		cell.configureCollectionViewCell(hourly: forecast)
		
		self.location.text = forecast.city
		self.date.text = self.extractDate(dateNumber: forecast.date as! Date)
			//showCurrentDate()
			//self.extractDate(dateNumber: forecast.date as! Date)

		self.changeColor.viewColor(icon: UIImage(named: self.weatherIconForViewColor(forecastIndex: 1))!, view: cell.hourView)
		self.changeColor.viewGradient(view: cell.hourView, start: 0.1, end: 1.0)
		
		return cell
	}

}

extension DetailedViewController: UICollectionViewDelegateFlowLayout {
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		let paddingSpace = sectionInsets.left * 9
		let availableWidth = collectionView.frame.width - paddingSpace
		let widthPerItem = availableWidth / 8
		let heightPerItem = collectionView.frame.height
		
		return CGSize(width: widthPerItem, height: heightPerItem)
	}
	
	func collectionView(_ collectionView: UICollectionView,
	                    layout collectionViewLayout: UICollectionViewLayout,
	                    insetForSectionAt section: Int) -> UIEdgeInsets {
		return sectionInsets
	}
}

extension DetailedViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let events = self.events else {
			return 0
		}
		return events.count
	}
	
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "calendarCell") as! CalendarCell
		
		guard let events = self.events else {
			cell.textLabel?.text = "Unknown events"
			return cell
		}
		DispatchQueue.main.async {
			let event = events[(indexPath as NSIndexPath).row]
			let eventDate = self.showEventDate(startDate: event.startDate)
			cell.textLabel?.text = "• \(event.title) \(eventDate)"
		
		}
		return cell
	}
	
	func calendarViewColor() {
		self.changeColor.viewColor(icon: UIImage(named: weatherIconForViewColor(forecastIndex: 2))!, view: calenrView)
		self.changeColor.viewGradient(view: calenrView, start: 0.1, end: 1.0)
	}
	
}

