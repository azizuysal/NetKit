//
//  ServiceController.swift
//  NetKitExample
//
//  Created by Aziz Uysal on 2/17/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation
import NetKit

struct ServiceResult {
  static let Success = "Success"
  static let Error = "Error"
}

class ServiceController {
  
  fileprivate static let jsonService = JsonService()
  fileprivate static let serviceWithDelegate = ServiceWithDelegate()
  fileprivate static let weatherService = GlobalWeatherService()
  fileprivate static let downloadService = DownloadService()
  
  fileprivate static let networkQueueSerial = DispatchQueue(label: "networkQueueSerial", attributes: [])
  fileprivate static let networkQueueParallel = DispatchQueue(label: "networkQueueParallel", attributes: DispatchQueue.Attributes.concurrent)
  fileprivate static let downloadQueue = DispatchQueue(label: "downloadQueue", attributes: [])
  
  // MARK: ExampleService
  
  class func getPostsSync() -> Any {
    var result: Any = []
    
    jsonService.getPosts()
//      .respondOnCurrentQueue(true)
      .responseJSON { json in
        result = json
        notifyUser(JsonService.PostsDownloaded)
        return .success
      }
      .responseError { error in
        print(error)
        notifyUser(JsonService.PostsDownloaded, error: error)
      }
      .resumeAndWait(1)
    
    return result
  }
  
  class func getPosts() {
    _ = networkQueueSerial.sync {
      jsonService.getPosts()
        .responseJSON { json in
          print(json)
          notifyUser(JsonService.PostsDownloaded)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(JsonService.PostsDownloaded, error: error)
        }
        .resumeAndWait()
    }
  }
  
  class func addPost(_ post: Post) {
    networkQueueParallel.async {
      jsonService.addPost()
        .setJSON(post.toJson())
        .responseJSON { json in
          print(json)
          notifyUser(JsonService.PostsCreated)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(JsonService.PostsCreated, error: error)
        }
        .resume()
    }
  }
  
  class func updatePost(_ post: Post) {
    networkQueueParallel.async {
      jsonService.updatePost()
        .setPath(String(post.id))
        .setJSON(post.toJson())
        .responseJSON { json in
          print(json)
          notifyUser(JsonService.PostsUpdated)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(JsonService.PostsUpdated, error: error)
        }
        .resume()
    }
  }
  
  // MARK: ServiceWithDelegate
  
  class func getComments() {
    _ = networkQueueSerial.sync {
      serviceWithDelegate.getComments()
        .responseJSON { json in
          print(json)
          notifyUser(ServiceWithDelegate.CommentsDownloaded)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(ServiceWithDelegate.CommentsDownloaded, error: error)
        }
        .resume()
    }
  }
  
  // MARK: GlobalWeatherService
  
  class func getCities(_ country: String)  {
    _ = networkQueueSerial.sync {
      weatherService.getCitiesByCountry()
        .setURLParameters(["op":"GetCitiesByCountry"])
        .setSOAP("<GetCitiesByCountry xmlns=\"http://www.webserviceX.NET\"><CountryName>\(country)</CountryName></GetCitiesByCountry>")
        .response { data, url, response in
//          print(String(data: data!, encoding: NSUTF8StringEncoding))
          notifyUser(GlobalWeatherService.ReceivedCities)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(GlobalWeatherService.ReceivedCities, error: error)
        }
        .resume()
    }
  }
  
  class func downloadFile(_ filename: String) {
    
    downloadQueue.async {
      downloadService.getFile()
        .setCachePolicy(.reloadIgnoringLocalAndRemoteCacheData)
        .setPath(filename)
        .responseFile { (url, response) in
          let path = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Documents")
          do {
            try FileManager.default.createDirectory(at: path!, withIntermediateDirectories: true, attributes: nil)
          } catch let error as NSError {
            print(error.localizedDescription)
            return .failure(error)
          }
          if let url = url, let response = response, let filename = response.suggestedFilename, let path = path?.appendingPathComponent(filename) {
            do {
              if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.removeItem(at: path)
              }
              try FileManager.default.copyItem(at: url, to: path)
            } catch let error as NSError {
              print(error.localizedDescription)
              return .failure(error)
            }
          } else {
            return .failure(WebServiceError.badData("File parameter is nil"))
          }
          notifyUser(DownloadService.FileDownloaded, filename: response?.suggestedFilename)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(DownloadService.FileDownloaded, error: error)
        }
        .resumeAndWait()
    }
  }
  
  // MARK: Private methods
  
  fileprivate class func notifyUser(_ event: String, error: Error? = nil, filename: String? = nil) {
    var userInfo = [String:AnyObject]()
    userInfo = [ServiceResult.Success:true as AnyObject]
    if let error = error {
      userInfo[ServiceResult.Success] = false as AnyObject?
      userInfo[ServiceResult.Error] = error as NSError
    }
    if let filename = filename {
      userInfo[DownloadService.FileName] = filename as AnyObject?
    }
    NotificationCenter.default.post(name: Notification.Name(rawValue: event), object: nil, userInfo: userInfo)
  }
}

// MARK: Errors

enum WebServiceError: Error, CustomStringConvertible {
  case badResponse(String)
  case badData(String)
  
  var description: String {
    switch self {
    case let .badResponse(info):
      return info
    case let .badData(info):
      return info
    }
  }
}
