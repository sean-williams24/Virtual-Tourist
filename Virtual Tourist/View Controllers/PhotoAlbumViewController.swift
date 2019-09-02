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
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var latitude = 0.0
    var longitude = 0.0
    
    var images = [UIImage]()
    
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
//        let predicate = NSPredicate(format: "%k == %@", pin.latitude, latitude)
//        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "dateAdded", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Instantiate fetched results controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
        
        //        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let space: CGFloat = 3.0
        let size = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: size, height: size)
        
        
        setupFetchedResultsController()
        
        FlickrClient.getPhotosForLocation(lat: latitude, lon: longitude) { (response, error) in
            let photosResponse = response?.photos.photo
            if let photos = photosResponse {
                for photos in photos {
                    
                    // Convert downloaded photo data into url string
                    let URLString = "https://farm\(photos.farm).staticflickr.com/\(photos.server)/\(photos.id)_\(photos.secret).jpg"
                    
                    guard let imageURL = URL(string: URLString) else {
                        print("Could not create URL")
                        return
                    }
                    
                    // Download image from the url
                    let task = URLSession.shared.downloadTask(with: imageURL, completionHandler: { (url, response, error) in
                        guard let url = url else {
                            print("URL is nil")
                            return
                        }
                        // Persist image data to Core Data
                        let imageData = try! Data(contentsOf: url)
                        let photo = Photo(context: self.dataController.viewContext)
                        photo.image = imageData
                        photo.dateAdded = Date()
                        try? self.dataController.viewContext.save()
                        
                        // Convert image data to image and place into images array. Reload collection view with each image download. *** REPLACE THIS WITH FETCHED RESULTS CONTROLLER
                        let image = UIImage(data: imageData)
                        if let image = image {
                            self.images.append(image)
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                
                        }
                    })
                    task.resume()
                }
            }

        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
//        let photos = fetchedResultsController.fetchedObjects
//        if let photos = photos {
//            let image = UIImage(data: photos[0].image!)
//            self.imageView.image = image
//        }
        
        collectionView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    


    // MARK: - UICollectionViewDataSource
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoAlbumCell", for: indexPath) as! PhotoAlbumCell
        cell.imageView.image = images[indexPath.row]

        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }

    

    @IBAction func newCollectionButtonTapped(_ sender: Any) {
    }
}



