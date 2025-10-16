//
//  CreatePostView.swift
//  Campusmealsv2
//
//  Created by Claude on 04/10/2025.
//  Simple post creation matching app style
//

import SwiftUI
import PhotosUI
import CoreLocation

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var postService = PostService.shared
    @ObservedObject private var locationService = LocationDetectionService.shared
    @StateObject private var locationManager = LocationManager.shared

    @State private var selectedImages: [UIImage] = []
    @State private var selectedPHAssets: [PHAsset] = []
    @State private var notes: String = ""
    @State private var detectedRestaurant: DetectedRestaurant?
    @State private var selectedMealType: MealType = .lunch
    @State private var showImagePicker = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isDetectingLocation = false
    @State private var showPermissionAlert = false

    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    private var locationText: String {
        if let restaurant = detectedRestaurant {
            return restaurant.address ?? "Location detected"
        } else if let location = locationManager.currentLocation {
            return "Current location"
        } else {
            return "No location data"
        }
    }

    var body: some View {
        ZStack {
            // Background - WHITE like SocialFeedView
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar (matching SocialFeedView TikTok style)
                topBar

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Image Selection
                        imageSection

                        // Location Section (auto-detected)
                        locationSection

                        // Notes (simple text field)
                        notesSection

                        // Quick options
                        quickOptionsSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .background(Color.white)
            }

            // Upload Progress Overlay
            if isUploading {
                uploadingOverlay
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerWithAssets(images: $selectedImages, assets: $selectedPHAssets, selectionLimit: 3)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .alert("Photo Library Access Required", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        } message: {
            Text("Please allow access to your photo library in Settings to share food photos.")
        }
        .onChange(of: selectedImages) { oldValue, newValue in
            // Detect location when images are selected (with smooth animation)
            if !newValue.isEmpty && oldValue.count < newValue.count {
                withAnimation(.easeInOut(duration: 0.3)) {
                    // Visual feedback
                }
                Task {
                    await detectLocationFromImages()
                }
            }
        }
        .onAppear {
            // Start location services with BEST accuracy
            locationManager.checkCurrentStatus()
            locationManager.startUpdatingLocation()
        }
    }

    // MARK: - Top Bar (matching SocialFeedView TikTok style)
    private var topBar: some View {
        HStack(spacing: 16) {
            // Back Button (left aligned like TikTok)
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }

            Spacer()

            // Title (center)
            Text("New Post")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)

            Spacer()

            // Post Button (right aligned)
            Button(action: {
                Task {
                    await createPost()
                }
            }) {
                Text("Post")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(selectedImages.isEmpty || notes.isEmpty ? Color(.systemGray3) : citiBikeBlue)
            }
            .disabled(selectedImages.isEmpty || notes.isEmpty || isUploading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.white)
    }

    // MARK: - Image Section (Clean white background style)
    private var imageSection: some View {
        VStack(spacing: 0) {
            if selectedImages.isEmpty {
                Button(action: {
                    checkPhotoLibraryPermission()
                }) {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(citiBikeBlue)

                        Text("Add Photos")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)

                        Text("Up to 3 photos")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.systemGray))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 140, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .clipped()
                                    .transition(.scale.combined(with: .opacity))

                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedImages.remove(at: index)
                                        if index < selectedPHAssets.count {
                                            selectedPHAssets.remove(at: index)
                                        }
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)).frame(width: 28, height: 28))
                                }
                                .padding(8)
                            }
                        }

                        if selectedImages.count < 3 {
                            Button(action: {
                                checkPhotoLibraryPermission()
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(citiBikeBlue)

                                    Text("Add More")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(.systemGray))
                                }
                                .frame(width: 140, height: 140)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Notes Section (Clean style matching feed)
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Caption")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)

            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("What did you eat? How was it?")
                        .font(.system(size: 16))
                        .foregroundColor(Color(.systemGray3))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $notes)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Location Section (Auto-detected with clean style)
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Location")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)

                if isDetectingLocation {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.leading, 4)
                }

                Spacer()

                Button(action: {
                    Task {
                        await detectLocationFromImages()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Detect")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(citiBikeBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(citiBikeBlue.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(selectedImages.isEmpty)
            }

            // Location Display Card
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(citiBikeBlue)

                    Text(locationText)
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .lineLimit(2)

                    Spacer()
                }

                // Restaurant Info (if detected)
                if let restaurant = detectedRestaurant {
                    Divider()
                        .background(Color(.systemGray5))

                    HStack(spacing: 10) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 16))
                            .foregroundColor(Color(.systemGray))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(restaurant.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)

                            if let rating = restaurant.rating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(.systemGray))
                                }
                            }
                        }

                        Spacer()

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                detectedRestaurant = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(.systemGray3))
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Quick Options (Meal type pills - clean style)
    private var quickOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)

            HStack(spacing: 10) {
                ForEach([MealType.breakfast, .lunch, .dinner, .snack], id: \.self) { mealType in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMealType = mealType
                        }
                    }) {
                        Text(mealType.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(selectedMealType == mealType ? .white : .black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(selectedMealType == mealType ? Color.black : Color(.systemGray6))
                            .cornerRadius(22)
                    }
                }
            }
        }
    }

    // MARK: - Check Photo Library Permission
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            // Permission granted, show picker
            showImagePicker = true

        case .notDetermined:
            // Request permission
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        showImagePicker = true
                    } else {
                        showPermissionAlert = true
                    }
                }
            }

        case .denied, .restricted:
            // Show alert to go to settings
            showPermissionAlert = true

        @unknown default:
            showPermissionAlert = true
        }
    }

    private func detectLocationFromImages() async {
        guard let currentLocation = locationManager.currentLocation else {
            return
        }

        isDetectingLocation = true
        defer { isDetectingLocation = false }

        do {
            let result = try await locationService.detectLocationAndRestaurant(
                from: selectedImages[0],
                fallbackLocation: currentLocation
            )

            await MainActor.run {
                detectedRestaurant = result.restaurant
            }
        } catch {
            await MainActor.run {
                detectedRestaurant = nil
            }
        }
    }

    // MARK: - Uploading Overlay (Clean white style)
    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2.0)

                VStack(spacing: 8) {
                    Text("Creating your post...")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(Int(uploadProgress * 100))% complete")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.8))
                }

                ProgressView(value: uploadProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: citiBikeBlue))
                    .frame(width: 240)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.4))
                    .blur(radius: 20)
            )
        }
    }

    // MARK: - Create Post (Optimized with feedback)
    private func createPost() async {
        // Haptic feedback on start
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        isUploading = true

        do {
            _ = try await postService.createPost(
                images: selectedImages,
                selfieImage: nil as UIImage?,
                notes: notes,
                location: locationText,
                mealType: selectedMealType,
                dietTags: [],
                restaurantName: detectedRestaurant?.name,
                restaurantRating: detectedRestaurant?.rating,
                nutritionInfo: nil as PostNutritionInfo?,
                onProgress: { progress in
                    Task { @MainActor in
                        uploadProgress = progress
                    }
                }
            )

            await MainActor.run {
                isUploading = false
                // Success haptic
                let successGenerator = UINotificationFeedbackGenerator()
                successGenerator.notificationOccurred(.success)
                dismiss()
            }
        } catch {
            await MainActor.run {
                isUploading = false
                errorMessage = error.localizedDescription
                showError = true
                // Error haptic
                let errorGenerator = UINotificationFeedbackGenerator()
                errorGenerator.notificationOccurred(.error)
            }
        }
    }
}

// MARK: - Image Picker with PHAsset (UIKit Bridge)
struct ImagePickerWithAssets: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Binding var assets: [PHAsset]
    let selectionLimit: Int

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = selectionLimit
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerWithAssets

        init(_ parent: ImagePickerWithAssets) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else { return }

            let identifiers = results.compactMap(\.assetIdentifier)
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
            var assets: [PHAsset] = []

            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            DispatchQueue.main.async {
                self.parent.assets = assets
            }

            // Load UIImages (asynchronously but tracked)
            let group = DispatchGroup()
            var loadedImages: [UIImage] = []

            for (index, result) in results.enumerated() {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            loadedImages.append(image)
                            print("📷 Image \(index + 1) loaded")
                        } else if let error = error {
                            print("📷 ❌ Failed to load image \(index + 1): \(error.localizedDescription)")
                        }
                        group.leave()
                    }
                }
            }

            // Wait for all images to load, then update UI
            group.notify(queue: .main) {
                self.parent.images = loadedImages
                print("📷 ✅ All \(loadedImages.count) images loaded")
                print("📷 ✅ Assets count: \(self.parent.assets.count)")
                print("📷 ═══════════════════════════════════════\n")
            }
        }
    }
}

#Preview {
    CreatePostView()
}
