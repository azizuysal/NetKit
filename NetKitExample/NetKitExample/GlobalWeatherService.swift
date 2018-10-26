//
//  GlobalWeatherService.swift
//  NetKitExample
//
//  Created by Aziz Uysal on 2/18/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation
import NetKit

protocol GlobalWeatherAPI {
  var webService: WebService {get}
  
  func getCitiesByCountry() -> WebTask
  func getWeather() -> WebTask
}

extension GlobalWeatherAPI {
  
  func getCitiesByCountry() -> WebTask {
    return webService.POST("")
  }
  
  func getWeather() -> WebTask {
    return webService.POST("")
  }
}

class GlobalWeatherService: GlobalWeatherAPI {
  
  private static let baseURL = "http://www.webservicex.net/globalweather.asmx"
  let webService = WebService(urlString: baseURL)!
}

extension Notification.Name {
  static let receivedCities = Notification.Name("GlobalWeather.ReceivedCities")
  static let receivedWeather = Notification.Name("GlobalWeather.ReceivedWeather")
}
