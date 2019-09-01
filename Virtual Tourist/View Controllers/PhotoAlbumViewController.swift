//
//  PhotoAlbumView.swift
//  Virtual Tourist
//
//  Created by Sean Williams on 30/08/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var newCollectionButton: UIBarButtonItem!
    
    var dataController: DataController!
    var latitude = 0.0
    var longitude = 0.0
    
    var images = [UIImage]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FlickrClient.getPhotosForLocation(lat: latitude, lon: longitude) { (response, error) in
            let photosResponse = response?.photos.photo
            if let photos = photosResponse {
                for photos in photos {
//                    let ID = photos.id
//                    let serverID = photos.server
//                    let farmID = photos.farm
//                    let secret = photos.secret
                    
                    let URLString = "https://farm\(photos.farm).staticflickr.com/\(photos.server)/\(photos.id)_\(photos.secret).jpg"
                    print("URL STRING: \(URLString)")
                    
                    guard let imageURL = URL(string: URLString) else {
                        print("Could not create URL")
                        return
                    }
                    
                    let task = URLSession.shared.downloadTask(with: imageURL, completionHandler: { (url, response, error) in
                        guard let url = url else {
                            print("URL is nil")
                            return
                        }
                        
                        print("URL: \(url)")
                        
                        let imageData = try! Data(contentsOf: url)
                        let image = UIImage(data: imageData)
                        if let image = image {
                            self.images.append(image)
                            print("images array: \(self.images)")
                        }
                    })
                    task.resume()
                }
            }
        }

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func newCollectionButtonTapped(_ sender: Any) {
    }
}
