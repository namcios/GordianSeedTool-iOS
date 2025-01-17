//
//  Scan.swift
//  Gordian Seed Tool
//
//  Created by Wolf McNally on 2/18/21.
//

import SwiftUI
import WolfSwiftUI
import URKit
import URUI
import PhotosUI

struct ScanButton: View {
    @State private var isPresented: Bool = false
    let onScanResult: (ScanResult) -> Void
    
    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "qrcode.viewfinder")
        }
        .sheet(isPresented: $isPresented) {
            Scan(isPresented: $isPresented, onScanResult: onScanResult)
        }
    }
}

struct Scan: View {
    @Binding var isPresented: Bool
    @State private var presentedSheet: Sheet?
    let onScanResult: (ScanResult) -> Void
    @StateObject var scanState = URScanState()
    @State private var scanResult: ScanResult? = nil
    @StateObject private var sskrDecoder: SSKRDecoder
    @StateObject private var model: ScanModel
    @State private var estimatedPercentComplete = 0.0
    
    enum Sheet: Identifiable {
        case files
        case photos

        var id: Int {
            switch self {
            case .files:
                return 1
            case .photos:
                return 2
            }
        }
    }

    init(isPresented: Binding<Bool>, onScanResult: @escaping (ScanResult) -> Void) {
        self._isPresented = isPresented
        self.onScanResult = onScanResult
        let sskrDecoder = SSKRDecoder {
            Feedback.progress()
        }
        self._sskrDecoder = StateObject(wrappedValue: sskrDecoder)
        self._model = StateObject(wrappedValue: ScanModel(sskrDecoder: sskrDecoder))
    }
    
    var body: some View {
        return NavigationView {
            VStack {
                Group {
                    if scanResult == nil {
                        scanView
                    } else {
                        resultView
                    }
                }
            }
            .navigationBarItems(trailing: DoneButton($isPresented))
            .navigationBarTitle("Scan")
        }
        .sheet(item: $presentedSheet) { item -> AnyView in
            let isSheetPresented = Binding<Bool>(
                get: { presentedSheet != nil },
                set: { if !$0 { presentedSheet = nil } }
            )
            switch item {
            case .photos:
                var configuration = PHPickerConfiguration()
                configuration.filter = .images
                configuration.selectionLimit = 0
                configuration.preferredAssetRepresentationMode = .compatible
                return PhotoPicker(isPresented: isSheetPresented, configuration: configuration, completion: processLoadedImages)
                    .eraseToAnyView()
            case .files:
                var configuration = DocumentPickerConfiguration()
                configuration.documentTypes = [.image]
                configuration.asCopy = true
                configuration.allowsMultipleSelection = true
                return DocumentPicker(isPresented: isSheetPresented, configuration: configuration, completion: processLoadedImages)
                    .eraseToAnyView()
            }
        }
        .onDisappear {
            if let scanResult = scanResult {
                onScanResult(scanResult)
            }
        }
        .font(.body)
    }
    
    func processLoadedImages<T>(_ imageLoaders: [T]) where T: ImageLoader {
        extractQRCodes(from: imageLoaders) { messages in
            var remaining = messages.makeIterator()
            
            processNext()
            
            func processNext() {
                guard scanResult == nil, let message = remaining.next() else {
                    return
                }
//                DispatchQueue.global().async {
                DispatchQueue.main.async {
                    model.receive(urString: message)
                    processNext()
                }
//                }
            }
        }
    }
    
    var resultView: some View {
        VStack {
            switch scanResult! {
            case .failure(let error):
                Image(systemName: "xmark.octagon.fill")
                    .resizable()
                    .foregroundColor(.red)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                Text(error.localizedDescription)
            default:
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .foregroundColor(.green)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            }
        }
        .padding()
    }
    
    func sskrMemberView(color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 30, height: 10)
    }

    func sskrMemberView(isPresent: Bool) -> some View {
        sskrMemberView(color: isPresent ? Color.green : Color.yellow)
    }
    
    func sskrGroupView(group: SSKRDecoder.Group) -> some View {
        HStack(spacing: 10) {
            Text("\(group.index + 1)")
                .foregroundColor(group.isSatisfied ? .green : .yellow)
            if let memberStatus = group.memberStatus {
                ForEach(memberStatus) { status in
                    sskrMemberView(isPresent: status.isPresent)
                }
            } else {
                sskrMemberView(color: .clear)
            }
        }
    }
    
    var sskrStatusView: some View {
        VStack {
            if let groupThreshold = sskrDecoder.groupThreshold {
                VStack {
                    Label(
                        title: { Text("Recover from SSKR") },
                        icon: { Image("sskr.bar") }
                    )
                        .font(.title)
                    Spacer()
                        .frame(height: 10)
                    Text("\(groupThreshold) of \(sskrDecoder.groups.count) Groups")
                    Spacer()
                        .frame(height: 10)
                    VStack(alignment: .leading) {
                        ForEach(sskrDecoder.groups) { group in
                            sskrGroupView(group: group)
                        }
                    }
                }
                .font(Font.system(.title3).monospacedDigit().bold())
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
            }
        }
    }
    
    var scanView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading) {
                Text("Scan a QR code to import a seed or respond to a request from another device.")
                ZStack {
                    URVideo(scanState: scanState)
                    sskrStatusView
                }
                URProgressBar(value: $estimatedPercentComplete)
            }

            VStack(alignment: .leading) {
                Text("Paste a textual UR from the clipboard, or choose one or more images containing UR QR codes.")
                HStack {
                    pasteButton
                    filesButton
                    photosButton
                }
                .padding()
                .frame(maxWidth: .infinity)
            }

            Text("Acceptable types include ur:crypto-seed, ur:crypto-request, and ur:crypto-sskr.")
                .font(.footnote)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .onReceive(model.resultPublisher) { scanResult in
            switch scanResult {
            case .seed, .request:
                Feedback.success()
                self.scanResult = scanResult
                isPresented = false
            case .failure:
                Feedback.error()
                self.scanResult = scanResult
            }
        }
        .onReceive(scanState.resultPublisher) { result in
            guard scanResult == nil else {
                return
            }
            switch result {
            case .ur(let ur):
                model.receive(ur: ur)
                scanState.restart()
            case .other:
                Feedback.error()
                scanResult = .failure(GeneralError("Unrecognized format."))
            case .progress(let p):
                Feedback.progress()
                estimatedPercentComplete = p.estimatedPercentComplete
            case .reject:
                Feedback.error()
            case .failure(let error):
                Feedback.error()
                scanResult = .failure(GeneralError(error.localizedDescription))
            }
        }
    }
    
    var pasteButton: some View {
        ExportDataButton("Paste", icon: Image(systemName: "doc.on.clipboard"), isSensitive: false) {
            if let string = UIPasteboard.general.string {
                model.receive(urString: string)
            } else {
                Feedback.error()
                scanResult = .failure(GeneralError("The clipboard does not contain a valid ur:crypto-seed, ur:crypto-request, or ur:crypto-sskr."))
            }
        }
    }
    
    var filesButton: some View {
        ExportDataButton("Files", icon: Image(systemName: "doc"), isSensitive: false) {
            presentedSheet = .files
        }
    }
    
    var photosButton: some View {
        ExportDataButton("Photos", icon: Image(systemName: "photo"), isSensitive: false) {
            presentedSheet = .photos
        }
    }
}
