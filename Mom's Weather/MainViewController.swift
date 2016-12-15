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


class MainViewController: UIViewController {

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
	@IBOutlet weak var offlineLabel: UILabel!
	@IBOutlet weak var accessWarningLabel: UILabel!
	
	let locationManager = CLLocationManager()
	var currentLocation: CLLocation?
	var fetchedCurrentData = [CurrentWeather]()
	var fetchedUpcomingData = [Forecast]()
	var location = [Locations]()
	let openWeatherClient = OpenWeatherClient.shared
	let changeColor = ChangeColor.shared
	let coreDataStack = CoreDataStack.shared
	

	
	override func viewDidLoad() {
		super.viewDidLoad()
		showCurrentDate()
		locationManagerSetting()
		chooseWeatherData()

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		fetchCurrentData()
		fetchForecastData()
		deleteCurrentRecords()
		getCurrentData()
		getUpcomingData()
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		offlineWarning()
	}
	
	func fetchCurrentData() {
		let fetchRequest = CurrentWeather.fetch
		do {
			fetchedCurrentData = try CoreDataStack.shared.context.fetch(fetchRequest)
			print("wait: \(fetchedCurrentData.first?.city)")
		} catch {
			let error = error as Error
			displayAlert(error.localizedDescription, alertHandler: nil, presentationCompletionHandler: nil)
		}
	}
	
	func fetchForecastData() {
		
		let fetchRequest = Forecast.fetch
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
		
		do {
			fetchedUpcomingData = try self.coreDataStack.context.fetch(fetchRequest)
			print("fetchedUp: \(fetchedUpcomingData.last?.city) \(fetchedUpcomingData.count)")
		} catch {
			let error = error as Error
			displayAlert(error.localizedDescription, alertHandler: nil, presentationCompletionHandler: nil)
		}
		
	}
	
	func getCurrentWeatherData() {

		openWeatherClient.getCurrentWeatherData { (currentData, error) in
		 
			DispatchQueue.main.async {
				guard error == nil else {
					self.displayAlert((error?.localizedDescription)!, alertHandler: nil, presentationCompletionHandler: nil)
					self.currentDataSpinner.stopAnimating()
					return
				}
				self.currentDataSpinner.startAnimating()
				guard let currentData = currentData else {
					return
				}
				self.place.text = currentData.city
				self.currentTemperature.text = "\(currentData.temp!)"
				self.currentWeatherIcon.image = UIImage(named: currentData.icon!)
				self.currentWindSpeed.text = currentData.windSpeed
				self.currentDataSpinner.stopAnimating()
				self.changeColor.viewColor(icon: self.currentWeatherIcon.image!, view: self.currentWeatherView)
				self.changeColor.viewGradient(view: self.currentWeatherView, start: 1.0, end: 0.1)
			}
		}
		
		
	}


	func getCurrentData() {
		
		openWeatherClient.getCurrentData()
		
		DispatchQueue.main.async {
			self.currentDataSpinner.startAnimating()
			print("fetched no: \(self.fetchedCurrentData.count)")
			guard let currentData = self.fetchedCurrentData.last else {
				return /* check an error - index out of range*/
			}
			self.place.text = currentData.city
			self.currentTemperature.text = "\(currentData.temp)"
			self.currentWeatherIcon.image = UIImage(named: currentData.icon!)
			self.currentWindSpeed.text = currentData.windSpeed
			self.currentDataSpinner.stopAnimating()
			self.changeColor.viewColor(icon: self.currentWeatherIcon.image!, view: self.currentWeatherView)
			self.changeColor.viewGradient(view: self.currentWeatherView, start: 1.0, end: 0.1)
		}
	}
	
	func getUpcomingWeatherData() {

		openWeatherClient.getForecastWeatherData { (forecastData, error) in
			
			DispatchQueue.main.async {
				
				guard error == nil else {
					self.displayAlert((error?.localizedDescription)!, alertHandler: nil, presentationCompletionHandler: nil)
					self.upcompingSpinnerStop()
					return
				}
				
				guard let forecastData = forecastData else {
					return
				}
				print("upcoming Weather data")
				guard let sixthHour = forecastData.index(where: {$0.hours == "06"}),
					let ninthHour = forecastData.index(where: {$0.hours == "09"}),
					let twelfthHour = forecastData.index(where: {$0.hours == "12"}),
					let fifteenthHour = forecastData.index(where: {$0.hours == "15"}) else {
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
				
				let sixTemp = forecastData[sixthHour].minTemp!
				let nineTemp = forecastData[ninthHour].maxTemp!
				let noonMinTemp = forecastData[altered12].minTemp!
				let noonMaxTemp = forecastData[altered12].maxTemp!
				let threeMinTemp = forecastData[altered15].minTemp!
				let threeMaxTemp = forecastData[altered15].maxTemp!
				let afternoonMinTemp = min(noonMinTemp, threeMinTemp)
				let afternoonMaxTemp = max(noonMaxTemp, threeMaxTemp)
				let nineIcon = forecastData[ninthHour].icon!
				let noonIcon = forecastData[twelfthHour].icon!
				
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
				
				self.upcompingSpinnerStop()
				
				self.changeColor.viewColor(icon: self.morningIcon.image!, view: self.morningView)
				self.changeColor.viewGradient(view: self.morningView, start: 0.1, end: 1.0)
				
				self.changeColor.viewColor(icon: self.afternoonIcon.image!, view: self.afternoonView)
				self.changeColor.viewGradient(view: self.afternoonView, start: 0.1, end: 1.0)
			}
		}

	}
	

	func getUpcomingData() {
		
		deleteForecastRecords()
		openWeatherClient.getForecastData()
				
		DispatchQueue.main.async {
			
			self.upcompingSpinnerStart()

			guard let sixthHour = self.fetchedUpcomingData.index(where: {$0.hours == "06"}),
				let ninthHour = self.fetchedUpcomingData.index(where: {$0.hours == "09"}),
				let twelfthHour = self.fetchedUpcomingData.index(where: {$0.hours == "12"}),
				let fifteenthHour = self.fetchedUpcomingData.index(where: {$0.hours == "15"}) else {
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
			
			let sixTemp = self.fetchedUpcomingData[sixthHour].minTemp
			let nineTemp = self.fetchedUpcomingData[ninthHour].maxTemp
			let noonMinTemp = self.fetchedUpcomingData[altered12].minTemp
			let noonMaxTemp = self.fetchedUpcomingData[altered12].maxTemp
			let threeMinTemp = self.fetchedUpcomingData[altered15].minTemp
			let threeMaxTemp = self.fetchedUpcomingData[altered15].maxTemp
			let afternoonMinTemp = min(noonMinTemp, threeMinTemp)
			let afternoonMaxTemp = max(noonMaxTemp, threeMaxTemp)
			let nineIcon = self.fetchedUpcomingData[ninthHour].icon!
			let noonIcon = self.fetchedUpcomingData[twelfthHour].icon!
			
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
			
			self.upcompingSpinnerStop()
			
			self.changeColor.viewColor(icon: self.morningIcon.image!, view: self.morningView)
			self.changeColor.viewGradient(view: self.morningView, start: 0.1, end: 1.0)
			
			self.changeColor.viewColor(icon: self.afternoonIcon.image!, view: self.afternoonView)
			self.changeColor.viewGradient(view: self.afternoonView, start: 0.1, end: 1.0)
			
		}
		
	}

}


extension MainViewController: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.first else {
			return
		}
		
		currentLocation = location
		
		let savedLocation = Locations(context: coreDataStack.context)
		savedLocation.latitude = (currentLocation?.coordinate.latitude)!
		savedLocation.longitude = (currentLocation?.coordinate.longitude)!
		print("lat: \(savedLocation.latitude), \(savedLocation.longitude)")
		DispatchQueue.main.async {
			self.coreDataStack.saveContext()
		}
		
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status == .authorizedWhenInUse {
			locationManager.startMonitoringSignificantLocationChanges()
			connectionWarningView.isHidden = true
		} else if status == .denied {
			connectionWarningView.isHidden = false
			alertToLocationAccessDenied()
		} else {
			connectionWarningView.isHidden = false
		}
	}
	
}

// MARK: Error alert
extension UIViewController {
	
	func displayAlert(_ message: String, alertHandler: ((UIAlertAction) -> Void)?, presentationCompletionHandler: (() -> Void)?) {
		let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: alertHandler))
		present(alert, animated: true, completion: presentationCompletionHandler)
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

