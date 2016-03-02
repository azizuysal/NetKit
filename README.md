[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Language](https://img.shields.io/badge/swift-2.1-orange.svg)](http://swift.org)

# NetKit

A Concise HTTP Framework in Swift.

## Requirements

NetKit requires Swift 2.1 and Xcode 7.2.

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate NetKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "azizuysal/NetKit"
```

Run `carthage update` to build the framework and drag the built `NetKit.framework` into your Xcode project.

### CocoaPods

Not supported.

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

##License

The MIT License (MIT)
