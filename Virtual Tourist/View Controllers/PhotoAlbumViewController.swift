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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {


    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var newCollectionButton: UIBarButtonItem!
    @IBOutlet var imageView: UIImageView!
    
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
                    
                    let URLString = "https://farm\(photos.farm).staticflickr.com/\(photos.server)/\(photos.id)_\(photos.secret).jpg"
                    
                    guard let imageURL = URL(string: URLString) else {
                        print("Could not create URL")
                        return
                    }
                    
                    let task = URLSession.shared.downloadTask(with: imageURL, completionHandler: { (url, response, error) in
                        guard let url = url else {
                            print("URL is nil")
                            return
                        }
                        
                        let imageData = try! Data(contentsOf: url)
                        let image = UIImage(data: imageData)
                        if let image = image {
                            self.images.append(image)
                            print(self.images.count)
                            

                            
                            DispatchQueue.main.async {
                                let photo1 = self.images[0]
                                self.imageView.image = photo1
                                self.collectionView.reloadData()
                            }
                        }
                    })
                    task.resume()
                }
            }

        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        collectionView.reloadData()
    }

    // MARK: - UICollectionViewDataSource
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoAlbumCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        let photo = images[(indexPath as NSIndexPath).row]
        cell.photoAlbumCellImageView.image = photo

        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }

    

    @IBAction func newCollectionButtonTapped(_ sender: Any) {
    }
}
