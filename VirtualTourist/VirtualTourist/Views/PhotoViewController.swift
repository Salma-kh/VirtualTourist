//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by salma apple on 1/21/19.
//  Copyright © 2019 Salma alenazi. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController,MKMapViewDelegate,NSFetchedResultsControllerDelegate , UICollectionViewDataSource, UICollectionViewDelegate  {
    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var FlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    //Variables
    var select = [IndexPath]()
    var insert: [IndexPath]!
    var delete: [IndexPath]!
    var update: [IndexPath]!
    var allPages: Int? = nil

    var pin: Pin?
    var presentAlert = false
    var fetchedResults: NSFetchedResultsController<Photo>!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateFlowLayout(view.frame.size)
        mapView.delegate = self
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false

        guard let pin = pin else {
            return
        }
        displayPinOnTheMap(pin)
        setFetchedResultWith(pin)
        
        if let photos = pin.photos, photos.count == 0 {
            // pin selected has no photos
            getPhotosFromAPI(pin)
        }
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateFlowLayout(size)
    }
    private func updateFlowLayout(_  size: CGSize) {
        let landscape = size.width > size.height
        let space: CGFloat = landscape ? 5 : 3
        let items: CGFloat = landscape ? 2 : 3
        let dimension = (size.width - ((items + 1) * space)) / items
        FlowLayout?.minimumInteritemSpacing = space
        FlowLayout?.minimumLineSpacing = space
        FlowLayout?.itemSize = CGSize(width: dimension, height: dimension)
        FlowLayout?.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
    }
    private func displayPinOnTheMap(_ pin: Pin) {
        
        let lat = Double(pin.lat!)!
        let long = Double(pin.long!)!
        let locCoord = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = locCoord
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        mapView.setCenter(locCoord, animated: true)
    }

    private func setFetchedResultWith(_ pin: Pin) {
        
        let fr = NSFetchRequest<Photo>(entityName: Photo.name)
        fr.sortDescriptors = []
        fr.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        fetchedResults = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: CoreData.shared().context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResults.delegate = self
        
        // Start the fetched results controller
        var error: NSError?
        do {
            try fetchedResults.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("\(#function) Error performing initial fetch: \(error)")
        }
    }
    private func storePhotos(_ photos: [PhotoParser], forPin: Pin) {
        func showErrorMessage(msg: String) {
            displayInfo(Title: "Error", Message: msg)
        }
        
        for photo in photos {
            UIUpdates {
                if let url = photo.url {
                    _ = Photo(title: photo.title, imageurl: url, forPin: forPin, context: CoreData.shared().context)
                    self.save()
                }
            }
        }
    }
    private func getPhotosFromAPI(_ pin: Pin) {
        
        let lat = Double(pin.lat!)!
        let lon = Double(pin.long!)!
        FlickerApi.shared().searchBy(lat: lat, long: lon, allPages: allPages) { (photosParsed, error) in
            self.UIUpdates {
            }
            if let photosParsed = photosParsed {
                self.allPages = photosParsed.photos.pages
                let totalPhotos = photosParsed.photos.photo.count
                self.storePhotos(photosParsed.photos.photo, forPin: pin)
                if totalPhotos == 0 {
                    print("No photos found for this location ")
                }
            } else if let error = error {
                print("\(#function) error:\(error)")
                self.displayInfo(Title: "Error", Message: error.localizedDescription)
                print("Something went wrong, please try again")
            }
        }
    }
    private func imageUrlAlart(_ imageUrl: String) {
        if !self.presentAlert {
            self.displayInfo(Title: "Error", Message: "Error while fetching image for URL: \(imageUrl)", action: {
                self.presentAlert = false
            })
        }
        self.presentAlert = true
    }
    private func imageConfiguration(using cell: PhotoCellViewController, photo: Photo, collectionView: UICollectionView, index: IndexPath) {
        let place = UIImage(named: ImageName.placeHolder)
        var cellImage = place
        if let imageData = photo.image {
            cell.imageView.image = UIImage(data: imageData as Data)
        } else {
            cell.imageView.image = UIImage(named: "placeHolder")

            if let imageUrl = photo.imageurl {
                FlickerApi.shared().downloadimages(imageurl: imageUrl) { (data, error) in
                    if let _ = error {
                        self.UIUpdates {
                            self.imageUrlAlart(imageUrl)
                        }
                        return
                    } else if let data = data {
                        self.UIUpdates {
                            if let currentCell = collectionView.cellForItem(at: index) as? PhotoCellViewController {
                                if currentCell.imageUrl == imageUrl {
                                    currentCell.imageView.image = UIImage(data: data)
                                }
                            }
                            photo.image = NSData(data: data)
                            DispatchQueue.global(qos: .background).async {
                                self.save()
                            }
                        }
                    }
                }
            }
        }
    }

    @IBAction func deletePhotos(_ sender: UIButton) {
        for photos in fetchedResults.fetchedObjects! {
            CoreData.shared().context.delete(photos)
        }
        save()
        getPhotosFromAPI(pin!)
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let Id = "pin"
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: Id) as? MKPinAnnotationView
        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Id)
            pin!.canShowCallout = false
            pin!.pinTintColor = .red
        } else {
            pin!.annotation = annotation
        }
        return pin
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sectionInfo = self.fetchedResults.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCellViewController.identifier, for: indexPath) as! PhotoCellViewController
        cell.imageView.image = nil
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = fetchedResults.object(at: indexPath)
        let photoViewCell = cell as! PhotoCellViewController
        photoViewCell.imageUrl = photo.imageurl!
        imageConfiguration(using: photoViewCell, photo: photo, collectionView: collectionView, index: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResults.object(at: indexPath)
        CoreData.shared().context.delete(photoToDelete)
        save()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying: UICollectionViewCell, forItemAt: IndexPath) {
        
        if collectionView.cellForItem(at: forItemAt) == nil {
            return
        }
        
        let photo = fetchedResults.object(at: forItemAt)
        if let imageUrl = photo.imageurl {
            FlickerApi.shared().canceldownloadimages(imageUrl)
        }
    }
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        insert = [IndexPath]()
        delete = [IndexPath]()
        update = [IndexPath]()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,didChange anObject: Any,at indexPath: IndexPath?,
    for type: NSFetchedResultsChangeType,newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            insert.append(newIndexPath!)
            break
        case .delete:
            delete.append(indexPath!)
            break
        case .update:
            update.append(indexPath!)
            break
        case .move: break
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insert{
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.delete {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.update {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResults.sections?.count ?? 0
    }
}
