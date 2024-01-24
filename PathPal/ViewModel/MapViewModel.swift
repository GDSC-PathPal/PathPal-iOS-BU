//
//  MapViewModel.swift
//  PathPal
//
//  Created by Suji Lee on 1/23/24.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

let TMAP_APP_KEY = Bundle.main.object(forInfoDictionaryKey: "TMAP_APP_KEY") as? String ?? ""

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocation = CLLocation(latitude: 2.111111, longitude: 2.111111)
    @Published var userHeading: CLLocationDirection = CLLocationDirection()
    
    @Published var destination: PoiDetail = PoiDetail(id: "", name: "")
    @Published var startingPoint: PoiDetail = PoiDetail(id: "", name: "")
    @Published var skResponse: SKResponse?
    
    @Published var isFetching: Bool = false
    @Published var isSearching: Bool = false
    
    @Published var routeProperties: Properties?
    
    @Published var extractedMapIds: [String] = []
    @Published var routeInstruction: [String] = []
    
    var cancellables = Set<AnyCancellable>()
    
    private let locationManager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    @Published var isLoading = true  // Tracks if the location is being loaded initially
    var bearing: CLLocationDirection = 0 // Holds the latest heading/bearing
//    var mapView: GMSMapView?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingLocation()
        self.locationManager.startUpdatingHeading()  // Start receiving heading updates
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            lastLocation = location
            userLocation = location
            
            startingPoint.noorLon = String(format: "%.6f", location.coordinate.longitude)
            startingPoint.noorLat = String(format: "%.6f", location.coordinate.latitude)
            isLoading = false
            //                      print("řocation updated: \(location.coordinate.latitude), \(location.coordinate.lrongitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        bearing = newHeading.trueHeading != -1 ? newHeading.trueHeading : newHeading.magneticHeading
        userHeading = newHeading.trueHeading != -1 ? newHeading.trueHeading : newHeading.magneticHeading
        //      print("Heading updated: \(bearing)")
    }
    
    func requestKeywordDataToSK(query: String, longitude: String, latitude: String, page: Int) -> Future<[PoiDetail], Error> {
        return Future { promise in
            let targetUrl = "https://apis.openapi.sk.com/tmap/pois?version=1&searchKeyword=\(query)&searchType=all&page=\(page)&count=15&resCoordType=WGS84GEO&multiPoint=N&searchtypCd=R&radius=0&reqCoordType=WGS84GEO&poiGroupYn=N&centerLon=\(longitude)&centerLat=\(latitude)"
            
            print(targetUrl)
            let encodedUrl = targetUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            
            guard let url = URL(string: encodedUrl) else {
                fatalError("Invalid URL")
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("\(TMAP_APP_KEY)", forHTTPHeaderField: "appKey")
            URLSession.shared.dataTaskPublisher(for: request)
                .map { $0.data }
                .decode(type: SKResponse.self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("Failed to search places: \(error)")
                        promise(.failure(error))
                    case .finished:
                        break
                    }
                }, receiveValue: { data in
//                    print("검색 결과 from sk : ", data)
                    self.skResponse = data
                    promise(.success(data.searchPoiInfo.pois.poi))
                    
                })
                .store(in: &self.cancellables)
        }
    }
    
    func fetchRoute(parameters: [String: Any]) -> AnyPublisher<RouteResponse, Error> {
        let url = URL(string: "https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&callback=function")!
        let headers = [
            "accept": "application/json",
            "content-type": "application/json",
            "appKey": "\(TMAP_APP_KEY)"  // Replace TMAP_APP_KEY with your actual app key
        ]
        
        // Convert parameters to JSON data
        guard let postData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            fatalError("Invalid parameters")
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        // Make the request and decode the response
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                print("HTTP Status Code: \(response.statusCode)")
                
                guard response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                return output.data
            }
            .decode(type: RouteResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .catch { error -> AnyPublisher<RouteResponse, Error> in
                if let urlError = error as? URLError {
                    print("Error Code: \(urlError.errorCode)")
                    print("Error Message: \(urlError.localizedDescription)")
                } else {
                    print("Unknown error: \(error)")
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func generateNavigationInstructions(response: RouteResponse) {
        var instructions: [String] = []
    
        for feature in response.features {
            if feature.geometry.type == "Point" {
                if let description = feature.properties.description {
                    instructions.append(formatInstruction(description: description, turnType: feature.properties.turnType ?? 0))
                }
            }
        }
        
        self.routeInstruction = instructions
        print("경로 문자열 : ", instructions)
    }
    
    func formatInstruction(description: String, turnType: Int) -> String {
        var instruction = description


        // 횡단보도 관련 문자열 예외처리
        if instruction.contains("횡단보도 후") {
            instruction = instruction.replacingOccurrences(of: "횡단보도 후", with: "횡단보도를 건넌 후")
        }
        switch turnType {
        case 11:
             return "직진, \(instruction)"
        case 12:
            return "좌회전, \(instruction)"
        case 13:
            return "우회전, \(instruction)"
        case 14:
            return "유턴, \(instruction)"
        case 16:
            return "8시 방향으로 좌회전, \(instruction)"
        case 17:
            return "10시 방향으로 좌회전, \(instruction)"
        case 18:
            return "2시 방향으로 우회전, \(instruction)"
        case 19:
            return "4시 방향으로 우회전, \(instruction)"
        case 125:
            return "육교 건너기, \(instruction)"
        case 126:
            return "지하보도를 건너기, \(instruction)"
        case 127:
            return "계단 진입, \(instruction)"
        case 128:
            return "경사로 진입, \(instruction)"
        case 129:
            return "계단과 경사로 진입, \(instruction)"
        case 184:
            return "경유지, \(instruction)"
        case 185...189:
            return "경유지, \(instruction)"
        case 200:
            return "출발지에서 직진, \(instruction)"
        case 201:
            return "목적지 도착"
        case 211:
            return "횡단보도 건너기, \(instruction)"
        case 212:
            return "좌측 횡단보도 건너기, \(instruction)"
        case 213:
            return "우측 횡단보도 건너기, \(instruction)"
        case 214:
            return "8시 방향 횡단보도 건너기, \(instruction)"
        case 215:
            return "10시 방향 횡단보도 건너기, \(instruction)"
        case 216:
            return "2시 방향 횡단보도 건너기, \(instruction)"
        case 217:
            return "4시 방향 횡단보도 건너기, \(instruction)"
        case 218:
            return "엘리베이터 이용, \(instruction)"
        case 233:
            return "직진, \(instruction)"
        default:
            // 방향 정보가 없는 경우에는 직진으로 간주
            if description.contains("이동") {
                instruction = "출발지에서 직진 \(instruction)"
            }
        }
        return instruction
    }

    func directionDescription(from turnType: Int) -> String {
                switch turnType {
                case 1...7:
                    return "안내 없음"
                case 11:
                    return "직진"
                case 12:
                    return "좌회전"
                case 13:
                    return "우회전"
                case 14:
                    return "유턴"
                case 16:
                    return "8시 방향 좌회전"
                case 17:
                    return "10시 방향 좌회전"
                case 18:
                    return "2시 방향 우회전"
                case 19:
                    return "4시 방향 우회전"
                case 125:
                    return "육교"
                case 126:
                    return "지하보도"
                case 127:
                    return "계단 진입"
                case 128:
                    return "경사로 진입"
                case 129:
                    return "계단+경사로 진입"
                case 184:
                    return "경유지"
                case 185:
                    return "첫 번째 경유지"
                case 186:
                    return "두 번째 경유지"
                case 187:
                    return "세 번째 경유지"
                case 188:
                    return "네 번째 경유지"
                case 189:
                    return "다섯 번째 경유지"
                case 200:
                    return "출발지"
                case 201:
                    return "목적지"
                case 211:
                    return "횡단보도"
                case 212:
                    return "좌측 횡단보도"
                case 213:
                    return "우측 횡단보도"
                case 214:
                    return "8시 방향 횡단보도"
                case 215:
                    return "10시 방향 횡단보도"
                case 216:
                    return "2시 방향 횡단보도"
                case 217:
                    return "4시 방향 횡단보도"
                case 218:
                    return "엘리베이터"
                case 233:
                    return "직진 임시"
                default:
                    return ""
                }
    }

    func roadTypeDescription(from roadType: Int?) -> String {
        switch roadType {
        case 21, 22, 23, 24: return "보행자 도로"
        // 여기에 더 많은 도로 유형을 추가할 수 있습니다.
        default: return ""
        }
    }
}
