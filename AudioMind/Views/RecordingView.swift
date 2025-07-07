//
//  RecordingView.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//


import SwiftUI
import SwiftData

struct RecordingView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = RecordingViewModel()
    @Query(sort: [SortDescriptor<RecordingSession>(\.createdAt, order: .reverse)]) var sessions: [RecordingSession]
    @State private var selectedSession: RecordingSession?

    var body: some View {
        NavigationView {
            ZStack {
                Color("MossGreen").ignoresSafeArea()
                VStack(spacing: 32) {
                    Spacer(minLength: 24)
                    Text(viewModel.timerText)
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(Color("DarkGreen"))
                        .padding(.top, 16)

                    if viewModel.isRecording {
                        AudioLevelMeterView(levels: viewModel.waveformLevels)
                            .frame(height: 60)
                            .padding(.vertical, 8)
                            .background(Color("Lavendar").opacity(0.15))
                            .cornerRadius(16)
                    } else {
                        Spacer().frame(height: 60)
                    }

                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording(context: context)
                        } else {
                            viewModel.toggleRecording(context: context)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? Color("DarkGreen") : Color("PakistanGreen"))
                                .frame(width: 90, height: 90)
                                .shadow(color: Color("DarkMossGreen").opacity(0.3), radius: 8, y: 4)
                            Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)

                    sessionListCard
                    Spacer()
                }
                .padding(.horizontal)
                .alert(item: Binding(
                    get: {
                        viewModel.error.map { RecordingErrorMessage(message: $0) }
                    },
                    set: { _ in viewModel.error = nil }
                )) { error in
                    Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
                }
                .sheet(item: $selectedSession) { session in
                    SessionDetailView(sessionID: session.id)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .startRecording)) { _ in
            if !viewModel.isRecording {
                viewModel.toggleRecording(context: context)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stopRecording)) { _ in
            if viewModel.isRecording {
                viewModel.stopRecording(context: context)
            }
        }
        .onAppear {
            viewModel.initializeWidgetData(context: context)
        }

    }

    private var sessionListCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Past Recordings")
                .font(.headline)
                .foregroundColor(Color("DarkGreen"))
                .padding(.leading, 16)
                .padding(.top, 8)
            sessionList
               
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(Color("Lavendar").opacity(0.18))
        .cornerRadius(24)
        .shadow(color: Color("DarkMossGreen").opacity(0.10), radius: 8, y: 2)
        .padding(.horizontal, 8)
    }

    private var sessionList: some View {
        Group {
            if sessions.isEmpty {
                EmptyView()
            } else {
                List(sessions) { session in
                    Button(action: { selectedSession = session }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.fileURL.lastPathComponent)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("Lavendar"))
                                Text("Date: \(session.createdAt, formatter: dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(Color("DarkMossGreen"))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color("DarkMossGreen"))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color("DarkGreen"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("DarkMossGreen").opacity(0.15), lineWidth: 1)
                        )
                        
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .frame(maxHeight: 260)
                .background(Color.clear)
                
                
            }
        }
    }
        
}

private struct RecordingErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .short
    return df
}()





