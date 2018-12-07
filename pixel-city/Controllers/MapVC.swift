//
//  MapVC.swift
//  pixel-city
//
//  Created by Ahmed Mohamed El-Desouky on 12/3/18.
//  Copyright © 2018 Ahmed Mohamed El-Desouky. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var MapViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var PullUpViwe: UIView!
    
    var locationManager = CLLocationManager()
    var authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRedius: Double = 1000
    
    var ScreenSize = UIScreen.main.bounds
    
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    
    var flowLayout = UICollectionViewLayout()
    var collectionView: UICollectionView?
    
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        configureLocationServices()
        addDooubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.4998187423, green: 0.8423911929, blue: 0.200254235, alpha: 1)
        
        registerForPreviewing(with: self, sourceView: collectionView!)
        
        PullUpViwe.addSubview(collectionView!)
    }
    
    func addDooubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender: )))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        PullUpViwe.addGestureRecognizer(swipe)
    }
    
    func animateViewUP() {
        MapViewBottomConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown() {
        cancelAllSessions()
        MapViewBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (ScreenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.style = .whiteLarge
        spinner?.color = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }

    func addProgressLbl() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (ScreenSize.width / 2) - 120, y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Futura Medium", size: 16)
        progressLbl?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        progressLbl?.textAlignment = .center
        collectionView?.addSubview(progressLbl!)
    }
    
   func removeProgressLbl() {
    if progressLbl != nil {
        progressLbl?.removeFromSuperview()
    }
    }
    
    @IBAction func centerMapBtn(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
}
    
extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9647058824, green: 0.6509803922, blue: 0.137254902, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
        func centerMapOnUserLocation() {
            guard let coordinate = locationManager.location?.coordinate else { return }
            let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRedius * 2.0, longitudinalMeters: regionRedius * 2.0)
                mapView.setRegion(coordinateRegion, animated: true)
            }
// Drop pin on the maap
        @objc func dropPin(sender: UITapGestureRecognizer) {
            removePin()
            removeSpinner()
            removeProgressLbl()
            cancelAllSessions()
            
// Clean images from collectionView after drop another Pin
            imageUrlArray = []
            imageArray = []
            collectionView?.reloadData()
            
            animateViewUP()
            addSwipe()
            addSpinner()
            addProgressLbl()
            
            let touchPoint = sender.location(in: mapView)
            let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let annotation = DroppablePin(coordinate: touchCoordinate, identifire: "droppablePin")
            mapView.addAnnotation(annotation)
            
            print(flickrUrl(forApiKey: apiKey, withAnnotation: annotation, andNumberOfPhotos: 40))
            
            let coordinateRegion = MKCoordinateRegion(center: touchCoordinate, latitudinalMeters: regionRedius * 2.0, longitudinalMeters: regionRedius * 2.0)
            mapView.setRegion(coordinateRegion, animated: true)
            
            retrieveUrls(forAnnotation: annotation) { (finished) in
                if finished {
            self.retrieveImages(handler: { (finished) in
                        if finished {
    // Hide spinner , Hide label
                            self.removeSpinner()
                            self.removeProgressLbl()
                            
    // reload collectionView
                          self.collectionView?.reloadData()
                        }
                    })
                }
                
            }
        }
        
        func removePin() {
            for annotation in mapView.annotations {
                mapView.removeAnnotation(annotation)
            }
        }
    
// Import photos from api to app
    func retrieveUrls(forAnnotation annotation: DroppablePin, handler: @escaping(_ status: Bool) -> ()) {
        Alamofire.request(flickrUrl(forApiKey: apiKey, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            let photoDict = json["photos"] as! Dictionary<String, AnyObject>
            let photoDictArray = photoDict["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photoDictArray {
                let postUrl = "http://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg)"
                self.imageUrlArray.append(postUrl)
            }
            handler(true)
        }
    }
    
    // Append photos in my app
    func retrieveImages(handler: @escaping (_ status: Bool) -> ()) {
        for url in imageUrlArray {
            Alamofire.request(url).responseImage { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLbl?.text = "\(self.imageArray.count)/40 IMAGES DOWNLOADED"
                
                if self.imageArray.count == self.imageUrlArray.count {
                    handler(true)
                }
            }
        }
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sesssionDataTask, uploadData, downloadData) in
            sesssionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
            
 // $0.cansel() = ({ $0 }) for task in sesssionDataTask {  task.cancel() }
            
      }
    }
    
        }

// Confirm CLLocationManagerDelegate
extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // number of item in array
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as?
        PhotoCell else { return UICollectionViewCell() }
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
        popVC.initData(forImage: imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}

// 3DTouch
extension MapVC:UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexpath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexpath) else { return nil }
        
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return nil }
        
        popVC.initData(forImage: imageArray[indexpath.row])
        previewingContext.sourceRect = cell.contentView.frame
        
        return popVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    
}
