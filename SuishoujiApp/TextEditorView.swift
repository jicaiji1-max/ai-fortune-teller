import SwiftUI
import CoreLocation

struct TextEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let existingNote: Note?
    let onSave: (String, String?, Double?, Double?, [String]?) -> Void
    
    // 位置服务
    @State private var currentLocation: CLLocation?
    @State private var locationName: String?
    @State private var isFetchingLocation = false
    // 强持有 LocationFetcher，防止回调前被释放
    @State private var locationFetcher: AnyObject? = nil
    
    init(existingNote: Note? = nil, onSave: @escaping (String, String?, Double?, Double?, [String]?) -> Void) {
        self.existingNote = existingNote
        self.onSave = onSave
        _text = State(initialValue: existingNote?.text ?? "")
        _selectedTags = State(initialValue: existingNote?.tags ?? [])
        _locationName = State(initialValue: existingNote?.locationName)
        _currentLocation = State(initialValue: {
            if let lat = existingNote?.latitude, let lon = existingNote?.longitude {
                return CLLocation(latitude: lat, longitude: lon)
            }
            return nil
        }())
    }

    @State private var text = ""
    @State private var selectedTags: [String] = []
    @FocusState private var isFocused: Bool
    @State private var showDiscardAlert = false
    
    private var isEditMode: Bool {
        existingNote != nil
    }
    
    private var hasLocation: Bool {
        locationName != nil || currentLocation != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Location button (only in new mode, not edit mode)
                if !isEditMode {
                    HStack {
                        Button(action: {
                            fetchCurrentLocation()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: hasLocation ? "location.fill" : "location")
                                    .font(.caption)
                                Text(hasLocation ? (locationName ?? "已获取位置") : "获取当前位置")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(hasLocation ? Color.green.opacity(0.9) : Color.blue.opacity(0.9), in: Capsule())
                        }
                        .disabled(isFetchingLocation)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                }
                
                TextEditor(text: $text)
                    .focused($isFocused)
                    .font(.body)
                    .padding()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    TagSelectorView(selectedTags: $selectedTags)
                        .padding(.vertical, 8)
                }
                .background(.regularMaterial)
                .zIndex(100)
            }
            .navigationTitle(existingNote == nil ? "写字" : "编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            dismiss()
                        } else {
                            showDiscardAlert = true
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear { isFocused = true }
        .alert("放弃更改？", isPresented: $showDiscardAlert) {
            Button("放弃", role: .destructive) { dismiss() }
            Button("继续编辑", role: .cancel) {}
        } message: {
            Text("您输入的内容将会丢失")
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(
            trimmed,
            locationName,
            currentLocation?.coordinate.latitude,
            currentLocation?.coordinate.longitude,
            selectedTags.isEmpty ? nil : selectedTags
        )
        dismiss()
    }
    
    // 获取当前位置
    private func fetchCurrentLocation() {
        isFetchingLocation = true
        
        class LocationFetcher: NSObject, CLLocationManagerDelegate {
            var completionHandler: ((CLLocation?, String?) -> Void)?
            let manager = CLLocationManager()
            var isCompleted = false
            
            override init() {
                super.init()
                manager.delegate = self
            }
            
            func start() {
                manager.requestWhenInUseAuthorization()
                manager.startUpdatingLocation()
            }
            
            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                guard let location = locations.last, !isCompleted else { return }
                isCompleted = true
                manager.stopUpdatingLocation()
                
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    var locationName: String?
                    if let placemark = placemarks?.first {
                        var components: [String] = []
                        if let locality = placemark.locality {
                            components.append(locality)
                        }
                        if let thoroughfare = placemark.thoroughfare {
                            components.append(thoroughfare)
                        }
                        if let name = placemark.name {
                            components.insert(name, at: 0)
                        }
                        locationName = components.joined(separator: " ")
                    }
                    self.completionHandler?(location, locationName)
                }
            }
            
            func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
                guard !isCompleted else { return }
                isCompleted = true
                completionHandler?(nil, nil)
            }
        }
        
        let fetcher = LocationFetcher()
        locationFetcher = fetcher  // 强持有，防止 ARC 提前释放
        fetcher.completionHandler = { location, name in
            Task { @MainActor in
                self.currentLocation = location
                self.locationName = name
                self.isFetchingLocation = false
                self.locationFetcher = nil  // 完成后释放
            }
        }
        fetcher.start()
    }
}
