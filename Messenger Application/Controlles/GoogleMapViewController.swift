import UIKit
import CoreLocation
import GoogleMaps

class GoogleMapViewController: UIViewController {

    let fireStore = FirebaseManager.instance
    let locationManager = CLLocationManager()
    var mapView = GMSMapView()
    var zoneChats = [ZoneChat]()
    private var coordinate = CLLocationCoordinate2D()
    private var user: String?
    private var userID: String?
    private var nameZone: String?
    private var coordinateZone = CLLocationCoordinate2D()
    private var geolocationAccess = false
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var messagerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createMap()
        getZoneChats()
    }
    
    @IBAction private func viewMyLocation(_ sender: Any) {
        if geolocationAccess == true {
            mapView.camera = GMSCameraPosition(latitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 15)
        } else {
            if let BUNDLE_IDENTIFIER = Bundle.main.bundleIdentifier,
                let url = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(BUNDLE_IDENTIFIER)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    @objc private func addCircle() {
        locationManager.requestAlwaysAuthorization()
        let alertController = UIAlertController(title: "What name zone?", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(textField) in
            textField.placeholder = "type your name zone"
        })
        
        let cancelButtonAction = UIAlertAction(title: "Cancel", style: .cancel)
        let logInButtonAction = UIAlertAction(title: "Create zone", style: .default) {
            (action) -> Void in
            let circle = GMSCircle()
            let marker = GMSMarker(position: circle.position)
            circle.radius = 30 // Meters
            circle.fillColor  = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 0.2)
            circle.position =  CLLocationCoordinate2D(latitude: (self.coordinate.latitude), longitude: (self.coordinate.longitude))
            circle.strokeWidth = 2;
            circle.strokeColor = .black
            circle.map = self.mapView; // Add it to the map
            marker.title = alertController.textFields?.first?.text
            marker.map = self.mapView
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.zoneChats.append(ZoneChat(circle: circle, marker: marker ))
            self.fireStore.uploadZone(nameMarker: marker.title!, centerCircle: circle.position)
            self.goToMessager(self)
            self.transitionButton(hidden: false)
            self.coordinateZone=self.coordinate
        }
        alertController.addAction(cancelButtonAction)
        alertController.addAction(logInButtonAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    private func createMap() {
        let camera = GMSCameraPosition.camera(withLatitude: 23.931735,longitude: 121.082711, zoom: 7)
        mapView = GMSMapView(frame: self.view.bounds, camera: camera)
        let addZoneButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCircle))
        navigationItem.leftBarButtonItem = addZoneButton
        navigationItem.leftBarButtonItem?.isEnabled = false
        mapView.isMyLocationEnabled = true
        // GOOGLE MAPS SDK: BORDER
        let mapInsets = UIEdgeInsets(top: 80.0, left: 0.0, bottom: 45.0, right: 0.0)
        mapView.padding = mapInsets

        locationManager.distanceFilter = 10
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // GOOGLE MAPS SDK: USER'S LOCATION
        mapView.isMyLocationEnabled = true
        mapView.addSubview(messagerButton)
        view.addSubview(mapView)
        view.addSubview(locationButton)
    }
    
    private func getZoneChats() {
        fireStore.downloadZone(completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let chatZones):
                self.zoneChats = chatZones
                DispatchQueue.main.async {
                    for zone in self.zoneChats {
                        zone.circle.map = self.mapView
                        zone.marker.map = self.mapView
                    }
                }
            case .failure(let error):
                print("\(error)")
            }
        })
    }
    @IBAction private func goToMessager(_ sender: Any) {
        locationManager.stopUpdatingLocation()
        let alertController = UIAlertController(title: "What your name?", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(textField) in
            textField.placeholder = "type your name"
        })
        
        let cancelButtonAction = UIAlertAction(title: "Cancel", style: .cancel){
            (action) -> Void in
            self.locationManager.startUpdatingLocation()
        }
        let logInButtonAction = UIAlertAction(title: "Log in", style: .default) {
            (action) -> Void in
            self.user = alertController.textFields?.first?.text
            self.userID = UUID().uuidString
            self.fireStore.addUserChat(username: self.user!, userID: self.userID!, coordinate: self.coordinateZone, comletion: { [weak self] result in guard let self = self else { return }
                switch result {
                case .success(_):
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: UIConstants.sequeIndificator.messager, sender: self)
                    }
                case .failure(_):
                    break
                }
            }
        )}
           
        alertController.addAction(cancelButtonAction)
        alertController.addAction(logInButtonAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == UIConstants.sequeIndificator.messager,
            let vc = segue.destination as? ChatViewController {
            vc.user = user
            vc.userID = userID
            vc.x = coordinateZone.latitude
            vc.y = coordinateZone.longitude
            vc.title = nameZone
        }
    }
}
// MARK: - CLLocationManagerDelegate
extension GoogleMapViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            mapView.isMyLocationEnabled = true
            geolocationAccess = true
            navigationItem.leftBarButtonItem?.isEnabled = true
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
           // mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 20, bearing: 0, viewingAngle: 0)
            navigationItem.leftBarButtonItem?.isEnabled = true
            searchZone(zones: zoneChats, location: location)
            coordinate = location.coordinate
        }
    }
    
    private func searchZone(zones: [ZoneChat], location: CLLocation) {
        for zone in zones {
            let loc = CLLocation(latitude: zone.circle.position.latitude, longitude: zone.circle.position.longitude)
            if location.distance(from: loc) <= 30 {
                if messagerButton.isHidden != false {
                    transitionButton(hidden: false)
                }
                coordinateZone = zone.circle.position
                nameZone = zone.marker.title
                navigationItem.leftBarButtonItem?.isEnabled = false
                break
            } else { messagerButton.isHidden = true }
        }
    }
}

extension GoogleMapViewController {
    private func transitionButton(hidden: Bool) {
        messagerButton.isHidden = hidden
        messagerButton.alpha = 0
        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.messagerButton.alpha = 1
        })
    }
    
     @IBAction func saveDataFromAddMessageController(_ segue: UIStoryboardSegue){
           guard segue.identifier == UIConstants.sequeIndificator.map else { return }
        locationManager.startUpdatingLocation()
    }
    
    
}
