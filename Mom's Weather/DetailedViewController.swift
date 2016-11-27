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
	@IBOutlet weak var calendarTableView: UITableView!
	@IBOutlet weak var thingsView: UIView!
	
	var openWeatherClient = OpenWeatherClient.shared
	var changeColor = ChangeColor.shared
	var forecast = [Forecast]()
	let eventStore = EKEventStore()
	var calendars: [EKCalendar]?
	var events: [EKEvent]?
	let sectionInsets = UIEdgeInsets(top: 0.0, left: 1.0, bottom: 0.0, right: 1.0)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		configureCollectionView()
		configureTableView()
		showCurrentDate()
	
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		calendarAuthStatus()
		refreshCollectionView()
		changeThings()
	}
	
	
	func changeThings() {
				
		openWeatherClient.getForecastData() { (forecast, error) in
			guard let forecast = forecast else {
				return
			}
			let imageOne = self.thingsView.viewWithTag(1) as! UIImageView
			let imageTwo = self.thingsView.viewWithTag(2) as! UIImageView
			let imageThree = self.thingsView.viewWithTag(3) as! UIImageView

			let checkedDate = self.dateChecked()
			
			guard let i = forecast.index(where: {$0.date == checkedDate && $0.hours == "09" }),
					let j = forecast.index(where: {$0.date == checkedDate && $0.hours == "15"}) else {
					print("failed?")
					return
			}
			
			let status = true
			
			switch status {
			case forecast[i...j].contains(where: {($0.icon! == "01d" || $0.icon! == "01n") && $0.maxTemp! >= 20}):
				imageOne.image = #imageLiteral(resourceName: "sunglasses")
				imageTwo.image = #imageLiteral(resourceName: "sunscreen")
				imageThree.image = #imageLiteral(resourceName: "waterbottle")
			case forecast[i...j].contains(where: { $0.maxTemp! >= 20 && !($0.icon! == "01d" || $0.icon! == "01n")}):
				imageOne.image = #imageLiteral(resourceName: "waterbottle")
				imageTwo.image = #imageLiteral(resourceName: "sunglasses")
			case forecast[i...j].contains(where: {($0.icon == "09d" || $0.icon == "09d" || $0.icon == "10d" || $0.icon == "10n")}):
				imageOne.image = #imageLiteral(resourceName: "raincoat")
				imageTwo.image = #imageLiteral(resourceName: "rubberboots")
			case forecast[i...j].contains(where: { $0.minTemp! <= 5 && $0.icon != ""}):
				imageOne.image = #imageLiteral(resourceName: "sweatshirtb")
			default:
				imageOne.image = #imageLiteral(resourceName: "anything")
			}
		}

	}
}

extension DetailedViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 6
	
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "weatherCell", for: indexPath) as! WeatherCell
		
		openWeatherClient.getForecastData() { (forecasts, error) in
			
			DispatchQueue.main.async {
				guard let forecasts = forecasts else {
					return
				}
				
				let forecast = forecasts[indexPath.row]
	
				cell.configureCollectionViewCell(hourly: forecast)
				self.location.text = forecast.city
				self.changeColor.viewColor(icon: cell.iconImageView.image!, view: cell.hourView)
				self.changeColor.viewGradient(view: cell.hourView, start: 0.1, end: 1.0)
				
			}
		}
		
		return cell
	}
}

extension DetailedViewController: UICollectionViewDelegateFlowLayout {
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let paddingSpace = sectionInsets.left * 7
		let availableWidth = collectionView.frame.width - paddingSpace
		let widthPerItem = availableWidth / 6
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
	
	func numberOfSections(in tableView: UITableView) -> Int {
		
		return 1
		
	}
	
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
			cell.textLabel?.text = "✓ \(event.title) \(eventDate)"
		
		}
		return cell
	}
	
}

