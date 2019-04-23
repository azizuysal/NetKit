[![Language](https://img.shields.io/badge/Swift-5.0-orange.svg)](http://swift.org)
[![CocoaPods compatible](https://img.shields.io/badge/CocoaPods-compatible-brightgreen.svg)](https://cocoapods.org)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/azizuysal/NetKit.svg?branch=master)](https://travis-ci.org/azizuysal/NetKit)

# NetKit

A Concise HTTP Framework in Swift.

## Requirements

NetKit requires Swift 5.0 and Xcode 10.2

## Installation

### CocoaPods

You can use [CocoaPods](https://cocoapods.org) to integrate NetKit with your project.

Simply add the following line to your `Podfile`:
```ruby
pod "NetKit"
```

And run `pod update` in your project directory.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate NetKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```yaml
github "azizuysal/NetKit"
```

Run `carthage update` to build the framework and drag the built `NetKit.framework` into your Xcode project.

### Manually

You can integrate NetKit manually into your project simply by dragging `NetKit.framework` onto Linked Frameworks and Libraries section in Xcode.

## Usage

In order to run the included example project, you can install [JSON Server](https://github.com/typicode/json-server). It provides a quick backend for prototyping and mocking on your local machine. A sample `db.json` file is included in the example project.

Use `WebService` to create a client for a particular web service and use it to make requests and process responses.

```swift
import NetKit

let service = WebService(urlString: "http://localhost:3000/")
service.GET("/posts")
  .responseJSON { json in
    print(json)
    return .Success
  }
  .responseError { error in
    print(error)
  }
  .resume()
  ```

`responseJSON()` is a convenience method and combines obtaining a response and converting to JSON into one step. You can also use `response()` method to obtain raw response data.

```swift
.response { data, response in
  print(String(data: data!, encoding: NSUTF8StringEncoding))
  return .Success
}
```

You can return `.Success` or `.Failure(ErrorType)` from the response handlers to signal error status and control will transfer to `.responseError()` in case of an error.

### Synchronous Requests

You can use `resumeAndWait()` in order to make a synchronous request.

```swift
service.PUT("/posts")
  .setPath(String(post.id))
  .setJSON(post.toJson())
  .responseJSON { json in
    print(json)
    return .Success
  }
  .responseError { error in
    print(error)
  }
  .resumeAndWait()
```

### Authentication and SOAP support

If you need to set additional parameters, headers or authentication handlers, you can do so with Swift method chaining.

```swift
weatherService.POST()
  .authenticate { (method, completionHandler) -> WebTaskResult in
    switch method {
    case .Default, .HTTPBasic:
      completionHandler(.UseCredential, NSURLCredential(user: loginId, password: password, persistence: .ForSession))
    default:
      completionHandler(.PerformDefaultHandling, nil)
    }
    return .Success
  }
  .setURLParameters(["op":"GetCitiesByCountry"])
  .setSOAP("<GetCitiesByCountry xmlns=\"http://www.webserviceX.NET\"><CountryName>\(country)</CountryName></GetCitiesByCountry>")
  .response { data, response in
    print(String(data: data!, encoding: NSUTF8StringEncoding))
    return .Success
  }
  .responseError { error in
    print(error)
  }
  .resume()
```

### Support For All Configurations and Task Types

You can easily create `WebService` instances based on ephemeral or background sessions (the default is based on .defaultSessionConfiguration()).

```swift
let service = WebService(urlString: baseURL, configuration: .ephemeralSessionConfiguration())
```

Just as easily, you can create upload or download tasks (the default is data task).

```swift
let task = webService.GET("resource", taskType: WebTask.TaskType.Download)
```

### Background Downloads

You can easily setup a background url session and create file download tasks.

```swift
let webService: WebService = {
  let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.azizuysal.netkit.test")
  configuration.requestCachePolicy = .ReloadIgnoringLocalAndRemoteCacheData
  let service = WebService(urlString: baseURL, configuration: configuration)
  return service
}()
```

You can use the convenient file download handler `responseFile()` to process downloaded files.

```swift
downloadService.getFile()
  .responseFile { (url, response) in
    let path = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first?
    if let url = url, response = response, filename = response.suggestedFilename, path = path?.URLByAppendingPathComponent(filename) {
      do {
        try NSFileManager.defaultManager().copyItemAtURL(url, toURL: path)
      } catch let error as NSError {
        print(error.localizedDescription)
        return .Failure(error)
      }
    } else {
      return .Failure(WebServiceError.BadData("Bad params"))
    }
    notifyUser(DownloadService.FileDownloaded, filename: response?.suggestedFilename)
    return .Success
  }.responseError { error in
    print((error as NSError).localizedDescription)
    notifyUser(DownloadService.FileDownloaded, error: error)
  }
  .resumeAndWait()
```

##License

The MIT License (MIT)
