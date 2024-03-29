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
    
    class func taskForGettingPhotosForLocation(url: String, completion: @escaping (FlickrResponse?, Error?) -> Void) {
 
        let request = URLRequest(url: URL(string: url)!)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                completion(nil, error)
                debugPrint("Error downloading data from Flickr: \(error!)")
                return
            }
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(FlickrResponse.self, from: data)
                Auth.flickrPages = min(response.photos.pages, 4000/21)
                Auth.photoResponse = response.photos.photo
                DispatchQueue.main.async {
                    completion(response, error)
                }
            } catch {
                completion(nil, error)
                debugPrint("Decoding error: \(error)")
            }
        }
        task.resume()
    }
    
    class func getPhotosForLocation(lat: Double, lon: Double, completion: @escaping (Bool, Error?) -> Void) {
        if Auth.flickrPages == 0 { Auth.flickrPages = 1 }
        
        let urlString = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(Auth.APIKey)&accuracy=11&lat=\(lat)&lon=\(lon)&per_page=21&page=\(Int.random(in: 0..<Auth.flickrPages))&format=json&nojsoncallback=1)"
        
        taskForGettingPhotosForLocation(url: urlString) { (response, error) in
            if let _ = response {
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
}
