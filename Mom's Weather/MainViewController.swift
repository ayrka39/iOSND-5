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
	
	let locationManager = CLLocationManager()
	var currentLocation: CLLocation?
	let location = Location.shared
	let openWeatherClient = OpenWeatherClient.shared
	let changeColor = ChangeColor.shared
	let coreDataStack = CoreDataStack.shared
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		showCurrentDate()
		locationManagerSetting()

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		getCurrentWeatherData()
		getUpcomingData()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		locationAuthStatus()
		
	}

	func getCurrentWeatherData() {
		
		openWeatherClient.getCurrentWeatherData() { (currentWeather, error) in
			guard let currentWeather = currentWeather else {
				return
			}
			DispatchQueue.main.async { 
				self.place.text = currentWeather.city
				self.currentTemperature.text = "\(currentWeather.temp!)"
				self.currentWindSpeed.text = currentWeather.windSpeed
				self.currentWeatherIcon.image = UIImage(named: currentWeather.icon!)
				self.changeColor.viewColor(icon: self.currentWeatherIcon.image!, view: self.currentWeatherView)
				self.changeColor.viewGradient(view: self.currentWeatherView, start: 1.0, end: 0.1)
			}
			
		}
		
	}
	
	func getUpcomingData() {
		openWeatherClient.getForecastData() { (forecast, error) in
			guard let forecast = forecast else {
				return
			}
			guard let sixthHour = forecast.index(where: {$0.hours == "06"}),
					let ninthHour = forecast.index(where: {$0.hours == "09"}),
					let twelfthHour = forecast.index(where: {$0.hours == "12"}),
					let fifteenthHour = forecast.index(where: {$0.hours == "15"}) else {
				return
			}
			
			let sixTemp = forecast[sixthHour].minTemp!
			let nineTemp = forecast[ninthHour].maxTemp!
			let noonMinTemp = forecast[twelfthHour].minTemp!
			let noonMaxTemp = forecast[twelfthHour].maxTemp!
			let threeMinTemp = forecast[fifteenthHour].minTemp!
			let threeMaxTemp = forecast[fifteenthHour].maxTemp!
			let afternoonMinTemp = min(noonMinTemp, threeMinTemp)
			let afternoonMaxTemp = max(noonMaxTemp, threeMaxTemp)
			let nineIcon = forecast[ninthHour].icon!
			let noonIcon = forecast[twelfthHour].icon!
			var threeIcon = forecast[fifteenthHour].icon!
			
			DispatchQueue.main.async {
				
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
				switch nineIcon {
				case "01n":
					self.morningIcon.image = #imageLiteral(resourceName: "01d")
				case "02n":
					self.morningIcon.image = #imageLiteral(resourceName: "02d")
				default:
					break
				}
				self.afternoonIcon.image = UIImage(named: noonIcon)
				switch noonIcon {
				case "01n":
					self.afternoonIcon.image = #imageLiteral(resourceName: "01d")
				case "02n":
					self.afternoonIcon.image = #imageLiteral(resourceName: "02d")
				default:
					break
				}
				
				self.changeColor.viewColor(icon: self.morningIcon.image!, view: self.morningView)
				self.changeColor.viewGradient(view: self.morningView, start: 0.1, end: 1.0)
				
				self.changeColor.viewColor(icon: self.afternoonIcon.image!, view: self.afternoonView)
				self.changeColor.viewGradient(view: self.afternoonView, start: 0.1, end: 1.0)
			}
		}		
	}
	
}

extension MainViewController: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let llocation = locations.first else {
			return
		}
		print("found: \(llocation.coordinate.latitude)")
		let savedLocation = Locations(context: self.coreDataStack.context)
		savedLocation.latitude = llocation.coordinate.latitude
		savedLocation.longitude = llocation.coordinate.longitude
		print("saved: \(savedLocation.latitude)")
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		let status = CLLocationManager.authorizationStatus()
		
		switch status {
		case .notDetermined:
			requestAccessToLocation()
		case .authorizedWhenInUse:
			locationManager.stopUpdatingLocation()
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

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("failed to find user's location \(error.localizedDescription)")
	}
}

extension Locations {
	
	class var fetch: NSFetchRequest<Locations> {
		return NSFetchRequest<Locations>(entityName: "Locations")
	}
	
}
