//
//  NavigationPage.swift
//  PathPal
//
//  Created by Suji Lee on 12/26/23.
//

import SwiftUI
import Combine

enum SearchMode {
    case startingPoint
    case destination
}

struct NavigationPage: View {
    @ObservedObject var socketManager = SocketManager.shared
    
    @ObservedObject var mapVM: MapViewModel
    @State private var errorMsg: String?
    var cancellables = Set<AnyCancellable>()
    @State var searchMode: SearchMode = .startingPoint
    @State var totalString: String = ""
    
    // NavigationLink의 활성화 상태를 추적하는 새로운 @State 변수들
    @State private var isStartingPointActive = false
    @State private var isDestinationActive = false
    
    @State var isStartingPointEqualsUserLocation: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
//                Button("Crash") {
//                  fatalError("Crash was triggered")
//                }
                // 출발지
                VStack(alignment: .leading) {
                    Text("출발지")
                        .font(.system(size: 17, weight: .semibold))
                    HStack(spacing: 15) {
                        //출발지 검색 버튼
                        NavigationLink(destination: SearchView(mapVM: mapVM, searchMode: .constant(SearchMode.startingPoint), isStartingPointEqualsUserLocation: $isStartingPointEqualsUserLocation)) {
                            RoundedRectangle(cornerRadius: 25.5)
                                .stroke(Color.hexBBD2FF)
                                .frame(width: screenWidth * 0.85, height: 50)
                                .overlay {
                                    HStack {
                                        switch isStartingPointEqualsUserLocation {
                                        case false:
                                            if mapVM.startingPoint.name == "" {
                                                Text("출발지 검색")
                                                    .font(.system(size: 15))
                                                    .foregroundStyle(Color.hex959595)
                                                Spacer()
                                            } else {
                                                HStack {
                                                    Text( mapVM.startingPoint.name)
                                                        .font(.system(size: 15))
                                                        .foregroundStyle(Color.hex292929)
                                                    Spacer()
                                                }
                                            }
                                        case true:
                                            HStack {
                                                Text("현위치")
                                                    .font(.system(size: 15))
                                                    .foregroundStyle(Color.hex292929)
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding()
                                }
                        }
                    }
                }
                .padding(.bottom)
                
                // 도착지
                VStack(alignment: .leading) {
                    Text("도착지")
                        .font(.system(size: 17, weight: .semibold))
                    HStack(spacing: 15) {
                        //도착지 검색 버튼
                        NavigationLink(destination: SearchView(mapVM: mapVM, searchMode: .constant(SearchMode.destination), isStartingPointEqualsUserLocation: $isStartingPointEqualsUserLocation)) {
                            RoundedRectangle(cornerRadius: 25.5)
                                .stroke(Color.hexBBD2FF)
                                .frame(width: screenWidth * 0.85, height: 50)
                                .overlay {
                                    HStack {
                                        if mapVM.destination.name == "" {
                                            Text("도착지 검색")
                                                .font(.system(size: 15))
                                                .foregroundStyle(Color.hex959595)
                                        } else {
                                            HStack {
                                                Text(mapVM.destination.name)
                                                    .font(.system(size: 15))
                                                    .foregroundStyle(Color.hex292929)
                                                Spacer()
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                }
                        }
                    }
                }
                .padding(.bottom, 40)
                VStack {
                    if mapVM.routeInstruction == nil {
                        VStack {
                            Button(action: {
                                fetchRoute()
                            }, label: {
                                RoundedRectangle(cornerRadius: 25.5)
                                    .frame(width: screenWidth * 0.85, height: 50)
                                    .foregroundStyle(Color.hex246FFF)
                                    .overlay {
                                        Text("길찾기")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color.white)
                                    }
                            })
                            .disabled(mapVM.isFetching)
                        }
                    } else {
                        if mapVM.routeInstruction == [] {
                            Text("검색 결과가 없습니다")
                                .accessibilityHint("출발지와 도착지를 확인해주세요")
                        } else {
                            VStack {
                                //경로 안내
                                VStack {
                                    HStack {
                                        Text("경로 안내")
                                            .font(.system(size: 17, weight: .semibold))
                                        Spacer()
                                        NavigationLink(destination: {
                                            MapView(mapVM: mapVM)
                                        }, label: {
                                            Text("지도 보기")
                                                .font(.system(size: 13))
                                                .foregroundStyle(Color.hex454545)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(Color.hex292929, lineWidth: 0.5)
                                                }
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                        })
                                    }
                                    .frame(width: screenWidth * 0.86)
                                    ScrollView {
                                        HStack(spacing: 15) {
                                            Image("PathPal")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 15)
                                                .accessibilityHidden(true)
                                            Text(totalString)
                                            Spacer()
                                        }
                                        .font(.system(size: 15.5, weight: .medium))
                                        .padding(17)
                                        .background(Color.hexF4F8FF)
                                        VStack(alignment: .leading) {
                                            ForEach(mapVM.routeInstruction ?? [], id: \.self) { route in
                                                VStack(alignment: .leading) {
                                                    Text(route)
                                                        .font(.system(size: 14.5))
                                                }
                                                .padding(10)
                                                Divider()
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.bottom, 20)
                                    }
                                    .frame(width: screenWidth * 0.86, height: screenHeight * 0.4)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.hex959595.opacity(0.7), lineWidth: 0.7)
                                    }
                                }
                                .padding(.bottom)
                            }
                            // 출발하기
                            VStack {
                                NavigationLink(destination: {
                                    Compass(mapVM: mapVM)
                                }, label: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .frame(width: screenWidth * 0.86, height: 50)
                                        .foregroundStyle(Color.hex246FFF)
                                        .overlay {
                                            Text("출발하기")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(Color.white)
                                        }
                                })
                            }
                        }
                    }
                    Spacer()
                }
            }
            .padding(.top, 60)
            .toolbar {
                if !(mapVM.routeInstruction?.isEmpty ?? true) {
                    ToolbarItem(placement: .topBarTrailing, content: {
                        Button(action: {
                            mapVM.initStartingPoint()
                            mapVM.initDestination()
                            isStartingPointEqualsUserLocation = false
                        }, label: {
                            Text("경로 초기화")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.hex246FFF)
                        })
                    })
                }
            }
        }
        .onAppear(perform: {
            socketManager.setupWebSocket(totalTime: "600")
            socketManager.setupDataProcessing()
        })
        .onDisappear(perform: {
            print("웹 소켓 disconnection 함수 호출")
            socketManager.websocket.disconnect()
        })
    }
    
    func formatDistanceAndTime(distanceInMeters: Int, timeInSeconds: Int) -> String {
        let distance: String
        let time: String
        
        // 거리 변환: 1000 미터 이상일 경우 km로 표시, 아니면 m로 표시
        if distanceInMeters >= 1000 {
            distance = String(format: "%.2f km", Double(distanceInMeters) / 1000.0)
        } else {
            distance = "\(distanceInMeters)m"
        }
        
        // 시간 변환: 시간과 분으로 변환
        let hours = timeInSeconds / 3600
        let minutes = (timeInSeconds % 3600) / 60
        
        if hours > 0 {
            time = "\(hours)시간" + (minutes > 0 ? " \(minutes)분" : "")
        } else {
            time = "\(minutes)분"
        }
        
        return "총 거리: \(distance), 소요 시간: \(time)"
    }
    
    func fetchRoute() {
        let startName = "내 위치".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let endName = mapVM.destination.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        let parameters = [
            "startX": mapVM.startingPoint.noorLon ?? "",
            "startY": mapVM.startingPoint.noorLat ?? "",
            "angle": 20,
            "speed": 1,
            "endPoiId": mapVM.destination.id,
            "endX": mapVM.destination.noorLon ?? "",
            "endY": mapVM.destination.noorLat ?? "",
            "reqCoordType": "WGS84GEO",
            "startName": startName ?? "",
            "endName": endName ?? "",
            "searchOption": "4",
            "resCoordType": "WGS84GEO",
            "sort": "index"
        ] as [String : Any]
        mapVM.fetchRoute(parameters: parameters)
            .sink(receiveCompletion: { _ in
            }, receiveValue: { data in
                //                print("경로 데이터 : ", data)
                mapVM.parseRouteCoordinates(routeResponse: data)
                mapVM.routeProperties = data.features[0].properties
                //                print("캐싱한 porperty 데이터", mapVM.routeProperties)
                mapVM.generateNavigationInstructions(response: data)
                //경유지 데이터 삽입
                mapVM.extractWayPoints(from: data)
                totalString = formatDistanceAndTime(distanceInMeters: mapVM.routeProperties?.totalDistance ?? 0, timeInSeconds: mapVM.routeProperties?.totalTime ?? 0)
                mapVM.hassucceededFetching = true
                mapVM.isFetching = false
            })
            .store(in: &mapVM.cancellables)
    }
}

#Preview {
    NavigationPage(mapVM: MapViewModel())
}
