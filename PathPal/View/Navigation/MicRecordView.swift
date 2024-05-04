//
//  STT.swift
//  PathPal
//
//  Created by Suji Lee on 2/8/24.
//

import Foundation
import SwiftUI
import AVFoundation
import AudioToolbox

struct MicRecordView: View {
    
    @StateObject var sttManager: GoogleSpeechManager = GoogleSpeechManager()
    @StateObject var ttsManager: SpeechService = SpeechService()
    
    @State var transcripts: [String] = []
    @Binding var query: String
//    @State var hasAlertRecordEnded: Bool = false
    @State var hasGuidedQuery: Bool = false
    
    @Binding var isShowingMic: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Color.white)
                .ignoresSafeArea()
            VStack(spacing: 40) {
                Button(action: {
                    run()
                }, label: {
                    Image("RecordMic")
                })
                .accessibilityLabel("마이크")
                .accessibilityHint(Text("버튼을 눌러 마이크를 켜고 끌 수 있습니다"))
                //결과
                VStack {
                    if sttManager.isRecording {
                        Text("음성 인식 중")
                    } else {
                        HStack {
                            Text("검색어")
                            Text(" : \(query)")
                        }
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.hex292929)
                
                //완료하기 버튼
                VStack {
                    if hasGuidedQuery && !sttManager.isRecording {
                        Button(action: {
                            
                            isShowingMic = false
                        }, label: {
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: screenWidth * 0.6, height: 45)
                                .foregroundStyle(Color.hex246FFF)
                                .overlay {
                                    Text("완료하기")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.white)
                                }
                        })
                    }
                }
            }
        }
        .onAppear {
            query = ""
        }
        .onChange(of: sttManager.isFinal) { isFinal in
            if isFinal {
                transcripts.append(sttManager.getPrevTranscript())
//                if hasAlertRecordEnded {
                    query = transcripts.first ?? ""
//                    let ttsString = "\(query)를 검색어로 설정합니다"
//                    ttsManager.speak(text: ttsString)
                    hasGuidedQuery = true
//                }
            }
        }
    }
    
    func run() {
        if sttManager.isRecording {
            self.sttManager.stopRecording()
            print("Recording stopped.")
//            if !sttManager.isRunningAudioSession {
//                //녹음 종료음
//                AudioServicesPlaySystemSound(1113)
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    hasAlertRecordEnded = true
//                }
//            }
        } else {
//            if !sttManager.isRunningAudioSession && !sttManager.isRecording {
//                //녹음 시작음
//                AudioServicesPlaySystemSound(1113)
//                hasAlertRecordEnded = false
//            }
            self.transcripts.removeAll()
            self.sttManager.startRecording()
            print("Recording ...")
        }
    }

}
