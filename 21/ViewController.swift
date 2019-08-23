import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    let mapView = MKMapView(frame: .zero)
    
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        view.addSubview(mapView)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        mapView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        mapView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        mapView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        mapView.delegate = self
    
        mapView.showsUserLocation = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .notDetermined, .restricted, .denied:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            fatalError()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            for _ in 0...20 {
                let currentLocation = self.mapView.userLocation.coordinate
                let newLocation = currentLocation.shiftRandomPosition(meters: 30000, randomMeters: true)
                
                self.mapView.addAnnotation(Annotation(coordinate: newLocation))
            }
            
            self.mapView.setRegion(MKCoordinateRegion(center: self.mapView.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)), animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
        MKClusterAnnotation(memberAnnotations: memberAnnotations)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Annotation else { return nil }
        
        let identifier = "marker"
        let view: MKMarkerAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        view.clusteringIdentifier = "identifier"
        
        
        return view
    }
}

class Annotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        
        super.init()
    }
}

// https://stackoverflow.com/a/55459722/7715250
extension CLLocationCoordinate2D {
    /// Get coordinate moved from current to `distanceMeters` meters with azimuth `azimuth` [0, Double.pi)
    ///
    /// - Parameters:
    ///   - distanceMeters: the distance in meters
    ///   - azimuth: the azimuth (bearing)
    /// - Returns: new coordinate
    private func shift(byDistance distanceMeters: Double, azimuth: Double) -> CLLocationCoordinate2D {
        let bearing = azimuth
        let origin = self
        let distRadians = distanceMeters / (6372797.6) // earth radius in meters
        
        let lat1 = origin.latitude * Double.pi / 180
        let lon1 = origin.longitude * Double.pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        return CLLocationCoordinate2D(latitude: lat2 * 180 / Double.pi, longitude: lon2 * 180 / Double.pi)
    }
    
    func shiftRandomPosition(meters: Double, randomMeters: Bool) -> CLLocationCoordinate2D {
        let finalMeters: Double
        
        if randomMeters {
            finalMeters = Double.random(in: -meters..<meters)
        } else {
            finalMeters = meters
        }
        
        let randomAzimuth = Double.random(in: -Double.pi..<Double.pi)
        
        return shift(byDistance: finalMeters, azimuth: randomAzimuth)
    }
}
