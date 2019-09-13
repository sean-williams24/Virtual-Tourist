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
    var photosArray: [Photo] = []
    var latitude = 0.0
    var longitude = 0.0
    var blockOperations: [BlockOperation] = []
    
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
    
    
    fileprivate func downloadPhotosFromFlickr() {
        FlickrClient.getPhotosForLocation(lat: pin.coordinate.latitude, lon: pin.coordinate.longitude) { (response, error) in
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
                    DispatchQueue.global(qos: .background).async {
                        let task = URLSession.shared.downloadTask(with: imageURL, completionHandler: { (url, response, error) in
                            guard let url = url else {
                                print("URL is nil")
                                return
                            }
                            
                            // Persist image data to Core Data
                            let imageData = try! Data(contentsOf: url)
                            let photo = Photo(context: self.dataController.viewContext)
                            self.photosArray.append(photo)
                            
                            photo.image = imageData
                            photo.dateAdded = Date()
                            photo.pin = self.pin
                            
                            DispatchQueue.main.async {
                                try? self.dataController.viewContext.save()
                                self.collectionView.reloadData()
                            }
                            print("photos array count: \(self.photosArray.count)")
                        })
                        task.resume()
                    }
                }
            }
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
        if pin.photos?.count == 0 {
            downloadPhotosFromFlickr()
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        collectionView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    


// MARK: - UICollectionViewDataSource
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 21
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoAlbumCell", for: indexPath) as! PhotoAlbumCell
        self.newCollectionButton.isEnabled = false
        cell.imageView.image = UIImage(named: "Placeholder")
        cell.activityView.startAnimating()
 
        let aPhoto = fetchedResultsController.object(at: indexPath)
        
        if let aPhoto = aPhoto.image {
            let image = UIImage(data: aPhoto)
            DispatchQueue.main.async {
                cell.imageView.image = image
                cell.activityView.stopAnimating()
                self.newCollectionButton.isEnabled = true
            }
        } else {
            self.newCollectionButton.isEnabled = false
            cell.imageView.image = UIImage(named: "Placeholder")
            cell.activityView.startAnimating()
        }
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }

    
//////////////////////////// DELETE POTENTIALLY ////////////////////////////////
//    fileprivate func batchDeletePhotos() {
//        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
//        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch)
//
//        do {
//            try dataController.viewContext.execute(deleteRequest)
//            try dataController.viewContext.save()
//
//        } catch {
//            print ("There was an error")
//        }
//    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        let photos = fetchedResultsController.fetchedObjects
        if let photos = photos {
            for photo in photos {
                dataController.viewContext.delete(photo)
                photosArray.removeAll()
            }
        }
        downloadPhotosFromFlickr()
    }
    
    
    deinit {
        // Cancel all block operations when VC deallocates
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }
        
        blockOperations.removeAll(keepingCapacity: false)
    }
}


// MARK: Fetched results controller delegate methods

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    
    // The first two methods tell us when the data the fetched results controller is managing will and did change. This is important to batch update the user interface
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: BlockOperation in self.blockOperations {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    

    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == NSFetchedResultsChangeType.insert {
//            print("Insert Object: \(newIndexPath)")
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
//            print("Update Object: \(indexPath)")
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.move {
//            print("Move Object: \(indexPath)")
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
//            print("Delete Object: \(indexPath)")
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
        }
    }

}

