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
    var blockOperations: [BlockOperation] = []
    var FlickrURLs: [String] = []
    var photosToDisplay: Bool!
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate

        let sortDescriptor = NSSortDescriptor(key: "dateAdded", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
            
        // Instantiate fetched results controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
            do {
                try fetchedResultsController.performFetch()
            } catch {
                fatalError("The fetch could not be performed: \(error.localizedDescription)")
            }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if pin.photos?.count == 0 {
            downloadPhotosFromFlickr()
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let space: CGFloat = 3.0
        let size = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: size, height: size)
        
        navigationController?.isToolbarHidden = false
        
        setupFetchedResultsController()
        
        let viewRegion = MKCoordinateRegion(center: pin.coordinate, latitudinalMeters: 40000, longitudinalMeters: 40000)
        self.mapView.setRegion(viewRegion, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        self.mapView.addAnnotation(annotation)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()

    }
    
    override func viewDidAppear(_ animated: Bool) {
//        collectionView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    
    fileprivate func downloadPhotosFromFlickr() {
        FlickrClient.getPhotosForLocation(lat: pin.coordinate.latitude, lon: pin.coordinate.longitude) { (response, error) in
            let photosResponse = response?.photos.photo
            
            self.FlickrURLs = []
            
            if let photos = photosResponse {
                if photos.count == 0 {
                    self.photosToDisplay = false
                }
                for photos in photos {
                    
                    // Convert downloaded photo data into url string
                    let URLString = "https://farm\(photos.farm).staticflickr.com/\(photos.server)/\(photos.id)_\(photos.secret).jpg"
                    self.FlickrURLs.append(URLString)
                    let photo = Photo(context: self.dataController.viewContext)
                    photo.pin = self.pin
                    photo.urlString = URLString
                    photo.dateAdded = Date()
                    try? self.dataController.viewContext.save()

                }
                print("Download photos from flickr URLS count: \(self.FlickrURLs.count)")
            }

//            self.collectionView.reloadData()
            if self.FlickrURLs.count == 0 {
                // If there are no photos at location then display message on collection view background
                let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.collectionView.frame.width, height: self.collectionView.frame.height))
                messageLabel.text = "NO PHOTOS FOUND AT THIS LOCATION"
                messageLabel.textColor = .black
                messageLabel.numberOfLines = 0;
                messageLabel.textAlignment = .center;
                messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
                messageLabel.sizeToFit()
                self.collectionView.backgroundView = messageLabel;
            }

        }
    }

// MARK: - UICollectionViewDataSource
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if FlickrURLs.count > 0 {
//            return FlickrURLs.count
//        } else if fetchedResultsController.sections?[section].numberOfObjects ?? 21 > 0 {
//            return fetchedResultsController.sections?[section].numberOfObjects ?? 21
//        } else {
//            return 0
//        }
        return fetchedResultsController.sections?[section].numberOfObjects ?? 21
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoAlbumCell", for: indexPath) as! PhotoAlbumCell
        let photo = fetchedResultsController.object(at: indexPath)
        
        if photo.image == nil {
            // if DownloadFlickrImages has been called, download new images from FlickrURLS array

            self.newCollectionButton.isEnabled = false
            cell.imageView.image = UIImage(named: "Placeholder")
            cell.activityView.startAnimating()
            
            DispatchQueue.global(qos: .background).async {
                if let urlString = photo.urlString {
                    let url = URL(string: urlString)
                    if let imageData = try? Data(contentsOf: url!) {
                        let image = UIImage(data: imageData)
 
                        
                        DispatchQueue.main.async {
                            let photo = Photo(context: self.dataController.viewContext)
                            photo.image = imageData
                            try? self.dataController.viewContext.save()
                            
                            cell.imageView.image = image
                            cell.activityView.stopAnimating()
                            self.newCollectionButton.isEnabled = true
                        }
                    }
                }
            }
            
            
            
            // Download image from the url
//            DispatchQueue.global(qos: .background).async {
////                print("Flickr URL array count: \(self.FlickrURLs.count)")
//                let photo = self.fetchedResultsController.object(at: indexPath)
//                let urlString = photo.urlString
//                let URLString = self.FlickrURLs[indexPath.row]
//
////                print("Core Data url string: \(urlString ?? "No URL String")")
//                if let urlString = urlString {
//                    let imageURL = URL(string: urlString)
//                    print(imageURL as Any)
//                    let task = URLSession.shared.downloadTask(with: imageURL!, completionHandler: { (url, response, error) in
//                        guard let url = url else {
//                            print("URL is nil")
//                            return
//                        }
//
//                        // Persist image data to Core Data
//                        let imageData = try! Data(contentsOf: url)
//
//                        let photo = Photo(context: self.dataController.viewContext)
//                        photo.pin = self.pin
//                        photo.image = imageData
//                        photo.dateAdded = Date()
//                        try? self.dataController.viewContext.save()
//
//                        DispatchQueue.main.async {
//                            let image = UIImage(data: imageData)
//                            cell.imageView.image = image
//                            cell.activityView.stopAnimating()
//                            self.newCollectionButton.isEnabled = true
//                        }
//                    })
//                    task.resume()
//                }
//            }

        } else {
            // If there are photos on the pin, show previously downloaded photos
            
            let aPhoto = fetchedResultsController.object(at: indexPath)

            if let aPhoto = aPhoto.image {
                let image = UIImage(data: aPhoto)
                DispatchQueue.main.async {
                    cell.imageView.image = image
                }
            }
        }
        return cell
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if FlickrURLs.count > 0 {
//            FlickrURLs.remove(at: indexPath.row)
//            collectionView.reloadData()
//        } else {
//            let photoToDelete = fetchedResultsController.object(at: indexPath)
//            dataController.viewContext.delete(photoToDelete)
//            try? dataController.viewContext.save()
//            collectionView.reloadData()
//        }
        
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }

    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        
        let photos = fetchedResultsController.fetchedObjects
        if let photos = photos {
            for photo in photos {
                dataController.viewContext.delete(photo)
                try? dataController.viewContext.save()
            }
        }
        downloadPhotosFromFlickr()
    }
    
    
//    deinit {
//        // Cancel all block operations when VC deallocates
//        for operation: BlockOperation in blockOperations {
//            operation.cancel()
//        }
//        
//        blockOperations.removeAll(keepingCapacity: false)
//    }
}


// MARK: Fetched results controller delegate methods

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    
    // The first two methods tell us when the data the fetched results controller is managing will and did change. This is important to batch update the user interface
    
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        blockOperations.removeAll(keepingCapacity: false)
//    }
//    
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        collectionView!.performBatchUpdates({ () -> Void in
//            for operation: BlockOperation in self.blockOperations {
//                operation.start()
//            }
//        }, completion: { (finished) -> Void in
//            self.blockOperations.removeAll(keepingCapacity: false)
//        })
//    }
    

    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
        case .update:
            collectionView.reloadItems(at: [newIndexPath!])
        default:
            break
        }

    }

}

