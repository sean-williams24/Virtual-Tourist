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
            }

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
        return fetchedResultsController.sections?[section].numberOfObjects ?? 21
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoAlbumCell", for: indexPath) as! PhotoAlbumCell
        let photo = fetchedResultsController.object(at: indexPath)
        
        if photo.image == nil {
            
            // If the FRC photo has no image data, set placeholder, download photo from URL string on background queue, save image to core data and set image in cell

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
        } else {
            
            // If there are photos on the pin, show previously downloaded photos from FRC
            
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
}


// MARK: Fetched results controller delegate methods

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
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

