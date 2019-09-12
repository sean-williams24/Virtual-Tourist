//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Sean Williams on 01/09/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient {
    
    struct Auth {
        static var APIKey = "6fc73c69adc5c8d33679b0b1d91fcd55"
        static var flickrPages = 600
    }
    
//    enum Endpoints {
//        static let base = "https://api.flickr.com/services"
//    }
    
    class func getPhotosForLocation(lat: Double, lon: Double, completion: @escaping (FlickrResponse?, Error?) -> Void) {
        let request = URLRequest(url: URL(string: "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(Auth.APIKey)&accuracy=11&lat=\(lat)&lon=\(lon)&per_page=21&page=\(Int.random(in: 1...600))&format=json&nojsoncallback=1)")!)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                completion(nil, error)
                print("Error downloading data from Flickr: \(error?.localizedDescription)")
                return
            }
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(FlickrResponse.self, from: data)
                Auth.flickrPages = response.photos.pages
                completion(response, error)
                
            } catch {
                completion(nil, error)
                print("Decoding error: \(error)")
            }
        }
        task.resume()
    }
    
    
    
    
//    class func getStudentLocations(completion: @escaping ([StudentLocation], Error?) -> Void) {
//        let request = URLRequest(url: Endpoints.getStudentLocation.url)
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            guard let data = data  else {
//                completion([], error)
//                return
//            }
//            let decoder = JSONDecoder()
//            do {
//                let responseDict = try decoder.decode([String:[StudentLocation]].self, from: data)
//                let responseObject = responseDict.values.map({$0})
//                let flattened = Array(responseObject.joined())
//                completion(flattened, nil)
//            } catch {
//                completion([], error)
//                print(error)
//            }
//        }
//        task.resume()
//    }
}
