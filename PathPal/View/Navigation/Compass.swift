//
//  Compass.swift
//  PathPal
//
//  Created by Suji Lee on 12/26/23.
//

import SwiftUI
import Starscream

struct Compass: View {
    @ObservedObject var mapVM: MapViewModel
    @State var navigateToVisionPage: Bool = false
    @State var compassDegreeAdjustment: Double = 12.8
    
    var body: some View {
        VStack(spacing: 30) {
            VStack {
                Text("출발 방향 맞추기")
                    .foregroundStyle(Color.hex292929)
                    .font(.system(size: 21, weight: .semibold))
                    .padding(.bottom, 5)
                Text("방향 설정이 완료되면 시각 보조 화면으로 이동합니다")
                    .font(.system(size: 15))
                    .padding(.bottom)
                // 안내 메세지
                Text("진동이 울릴 때까지 출발 방향을 변경해주세요")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.hex353535)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, -60)
            // 나침반
            ZStack {
                // 목표 방향을 가리키는 화살표 (변경 없음)
                Image("CompassLine")
                    .resizable()
                    .scaledToFit()
                    .frame(width: screenWidth * 0.7)
                    .rotationEffect(.degrees((mapVM.startDirection)))
                    .rotationEffect(.degrees(-(mapVM.userHeading)))
                Image("CompassCenter")
                    .resizable()
                    .scaledToFit()
                    .frame(width: screenWidth * 0.8)
            }
            .accessibilityHidden(true)
            
            //네비게이션 링크
            NavigationLink("설정 중...", destination: VisionView(mapVM: mapVM), isActive: $navigateToVisionPage)
        }
        .background(Color.white)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing, content: {
                NavigationLink(destination: {
                    MapView(mapVM: mapVM)
                }, label: {
                    Text("지도 보기")
                })
            })
        }
        .onAppear {
            mapVM.hasTriggeredHapticFeedback = false
            mapVM.isHeadingRightDirection = false
            mapVM.hasDepartured = false
        }
        .onReceive(mapVM.$isHeadingRightDirection, perform: { isHeading in
            if isHeading && !mapVM.hasTriggeredHapticFeedback {
                triggerHapticFeedback()
                mapVM.hasTriggeredHapticFeedback = true  // 진동 발생 표시
                navigateToVisionPage = true
            }
        })
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// 세모 모양을 그리는 구조체
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        
        return path
    }
}

#Preview {
    Compass(mapVM: MapViewModel(), navigateToVisionPage: false)
}
