//
//  ViewController.swift
//  weatherForMom
//
//  Created by David on 10/31/16.
//  Copyright © 2016 David. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData


class MainViewController: UIViewController, CLLocationManagerDelegate {

	@IBOutlet weak var date: UILabel!
	@IBOutlet weak var place: UILabel!
	@IBOutlet weak var currentTemperature: UILabel!
	@IBOutlet weak var currentWindSpeed: UILabel!
	@IBOutlet weak var currentWeatherIcon: UIImageView!
	@IBOutlet weak var morningTemperature: UILabel!
	@IBOutlet weak var afternoonTemperature: UILabel!
	@IBOutlet weak var morningIcon: UIImageView!
	@IBOutlet weak var afternoonIcon: UIImageView!
	@IBOutlet weak var currentWeatherView: UIView!
	@IBOutlet weak var morningView: UIView!
	@IBOutlet weak var afternoonView: UIView!
	@IBOutlet weak var centerPopup: NSLayoutConstraint!
	@IBOutlet weak var connectionWarningView: UIView!
	@IBOutlet weak var currentDataSpinner: UIActivityIndicatorView!
	@IBOutlet weak var morningDataSpinner: UIActivityIndicatorView!
	@IBOutlet weak var afternoonDataSpinner: UIActivityIndicatorView!
	
	let locationManager = CLLocationManager()
	var currentLocation: CLLocation?
	var fetchedCurrentData = [CurrentWeather]()
	let openWeatherClient = OpenWeatherClient.shared
	let changeColor = ChangeColor.shared
	let coreDataStack = CoreDataStack.shared
	

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		showCurrentDate()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
		requestAccessToLocation()
		locationManager.startMonitoringSignificantLocationChanges()
		locationManagerSetting()
		connectionWarningView.isHidden = true

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		deleteCurrentRecords()
		getCurrentWeatherData()
		getUpcomingData()
		
		
	}
	

	func getCurrentWeatherData() {
		currentDataSpinner.startAnimating()
		openWeatherClient.getCurrentWeatherData()
		
		DispatchQueue.main.async {
		
			do {
				self.fetchedCurrentData = try self.coreDataStack.context.fetch(CurrentWeather.fetch)
				print("fetched no: \(self.fetchedCurrentData.count)")
				let currentData = self.fetchedCurrentData[0] /* check an error - index out of range*/
				
				self.place.text = currentData.city
				self.currentTemperature.text = "\(currentData.temp)"
				self.currentWeatherIcon.image = UIImage(named: currentData.icon!)
				self.currentWindSpeed.text = currentData.windSpeed
				
				self.changeColor.viewColor(icon: self.currentWeatherIcon.image!, view: self.currentWeatherView)
				self.changeColor.viewGradient(view: self.currentWeatherView, start: 1.0, end: 0.1)
				
			} catch {
				let error = error as Error
				fatalError("no currentWeather data \(error)")
			}
		}
		self.currentDataSpinner.stopAnimating()

	}
	

	func getUpcomingData() {
		upcomingDataSpinnerStart()
		deleteForecastRecords()
		openWeatherClient.getForecastData()
		var fetchedUpcomingData = [Forecast]()
		
		DispatchQueue.main.async {
		
			let fetchRequest = Forecast.fetch
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
			
			do {
				fetchedUpcomingData = try self.coreDataStack.context.fetch(fetchRequest)
				print("fetchedUpcomingData: \(fetchedUpcomingData.count)")
				
				guard let sixthHour = fetchedUpcomingData.index(where: {$0.hours == "06"}),
					let ninthHour = fetchedUpcomingData.index(where: {$0.hours == "09"}),
					let twelfthHour = fetchedUpcomingData.index(where: {$0.hours == "12"}),
					let fifteenthHour = fetchedUpcomingData.index(where: {$0.hours == "15"}) else {
						return
				}
				
				var altered12 = 0
				var altered15 = 0
			
				if ninthHour > fifteenthHour && ninthHour < twelfthHour {
					altered12 = twelfthHour
					altered15 = twelfthHour + 1
				} else if ninthHour > fifteenthHour && ninthHour > twelfthHour {
					altered12 = twelfthHour + 8
					altered15 = twelfthHour + 9
				} else {
					altered12 = twelfthHour
					altered15 = fifteenthHour
				}

				let sixTemp = fetchedUpcomingData[sixthHour].minTemp
				let nineTemp = fetchedUpcomingData[ninthHour].maxTemp
				let noonMinTemp = fetchedUpcomingData[altered12].minTemp
				let noonMaxTemp = fetchedUpcomingData[altered12].maxTemp
				let threeMinTemp = fetchedUpcomingData[altered15].minTemp
				let threeMaxTemp = fetchedUpcomingData[altered15].maxTemp
				let afternoonMinTemp = min(noonMinTemp, threeMinTemp)
				let afternoonMaxTemp = max(noonMaxTemp, threeMaxTemp)
				let nineIcon = fetchedUpcomingData[ninthHour].icon!
				let noonIcon = fetchedUpcomingData[twelfthHour].icon!
				
				if sixTemp == nineTemp {
					self.morningTemperature.text = "\(sixTemp)°"
				} else {
					let MorningMinTemp = min(sixTemp, nineTemp)
					let MorningMaxTemp = max(sixTemp, nineTemp)
					self.morningTemperature.text = "\(MorningMinTemp)° ~ \(MorningMaxTemp)°"
				}
				
				if afternoonMinTemp == afternoonMaxTemp {
					self.afternoonTemperature.text = "\(afternoonMinTemp)°"
				} else {
					self.afternoonTemperature.text = "\(afternoonMinTemp)° ~ \(afternoonMaxTemp)°"
				}
				
				self.morningIcon.image = UIImage(named: nineIcon)
				self.afternoonIcon.image = UIImage(named: noonIcon)
				
				self.changeColor.viewColor(icon: self.morningIcon.image!, view: self.morningView)
				self.changeColor.viewGradient(view: self.morningView, start: 0.1, end: 1.0)
				
				self.changeColor.viewColor(icon: self.afternoonIcon.image!, view: self.afternoonView)
				self.changeColor.viewGradient(view: self.afternoonView, start: 0.1, end: 1.0)
				
				
			} catch {
				fatalError("no upcoming weather data")
			}
		}
		self.upcomingDataSpinnerStop()
	}
	
}

// MARK: FetchRequest extension
extension Locations {
	
	class var fetch: NSFetchRequest<Locations> {
		return NSFetchRequest<Locations>(entityName: "Locations")
	}
	
}

extension CurrentWeather {
	
	class var fetch: NSFetchRequest<CurrentWeather> {
		return NSFetchRequest<CurrentWeather>(entityName: "CurrentWeather")
	}
	
}

extension Forecast {
	
	class var fetch: NSFetchRequest<Forecast> {
		return NSFetchRequest<Forecast>(entityName: "Forecast")
	}
	
}

