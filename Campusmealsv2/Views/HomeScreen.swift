//
//  HomeScreen.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import SwiftUI
import CoreLocation
import MapKit

struct HomeScreen: View {
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var vendorService = VendorService.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var menuService = MenuService.shared

    @State private var searchText: String = ""
    @State private var userLocation: CLLocation?
    @State private var userName: String = "User"
    @State private var selectedVendor: Vendor?
    @State private var showVendorDetail = false
    @State private var showSocialFeed = false
    @State private var showFridge = false
    @State private var showLogoutMenu = false
    @State private var showFoodSearch = false
    @State private var showFoodResults = false
    @State private var showWeeklyProgress = false
    @State private var showAI = false
    @State private var selectedIntent: FoodIntent?
    @State private var foodResults: [FoodResult] = []
    @State private var isLoadingResults = false
    @State private var menuItems: [MenuItem] = []
    @State private var selectedTab: TabItem = .browse

    // Squad Up & Eat states
    @State private var showCreateMatch = false
    @State private var showMatchInvites = false
    @State private var showEpisodeFeed = false
    @State private var showProfile = false
    @State private var pendingInvitesCount = 0
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7295, longitude: -73.9965), // NYU Washington Square
        span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
    )

    // Citi Bike Blue Color
    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    var body: some View {
        TabView(selection: $selectedTab) {
            // Browse Tab
            Tab("Browse", systemImage: "house.fill", value: .browse) {
                browseView
            }

            // Social Tab
            Tab("Social", systemImage: "person.2.fill", value: .social) {
                SocialFeedView()
            }

            // AI Tab
            Tab("AI", systemImage: "sparkles", value: .ai) {
                aiPlaceholderView
            }

            // Fridge Tab
            Tab("Fridge", systemImage: "refrigerator.fill", value: .fridge) {
                FridgeView()
            }

            // Metrics Tab
            Tab("Metrics", systemImage: "chart.bar.fill", value: .metrics) {
                WeeklyProgressView()
            }
        }
        .sheet(isPresented: $showVendorDetail) {
            if let vendor = selectedVendor {
                VendorDetailCard(
                    vendor: vendor,
                    menuItems: menuItems,
                    onClose: {
                        showVendorDetail = false
                        selectedVendor = nil
                    },
                    onViewFullMenu: {
                        // Navigate to full menu screen
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .interactiveDismissDisabled(false)
            }
        }
        .overlay {
            // Profile Menu Overlay (Gen Z Redesign)
            if showLogoutMenu {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        HapticFeedback.light()
                        withAnimation(.springBouncy) {
                            showLogoutMenu = false
                        }
                    }

                VStack {
                    HStack {
                        VStack(spacing: 0) {
                            // Profile Header
                            HStack(spacing: Spacing.md) {
                                Image("profilepic")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.brandHotPink, lineWidth: 2))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(authManager.currentUser?.phoneNumber ?? "User")
                                        .font(.heading3)
                                        .foregroundColor(.brandBlack)

                                    Text("campus meals member")
                                        .font(.caption)
                                        .foregroundColor(.brandGray)
                                }

                                Spacer()
                            }
                            .padding(Spacing.lg)
                            .background(Color.brandLightGray.opacity(0.3))

                            // Menu Items - Squad Up & Eat + Existing
                            VStack(spacing: 0) {
                                // My Profile (NEW)
                                MenuButton(
                                    icon: "person.circle.fill",
                                    title: "my profile",
                                    iconColor: .brandCoral
                                ) {
                                    HapticFeedback.light()
                                    showLogoutMenu = false
                                    showProfile = true
                                }

                                Divider().padding(.leading, 60)

                                // Match Invites (NEW)
                                HStack {
                                    MenuButton(
                                        icon: "envelope.fill",
                                        title: "match invites",
                                        iconColor: .brandHotPink
                                    ) {
                                        HapticFeedback.light()
                                        showLogoutMenu = false
                                        showMatchInvites = true
                                    }

                                    if pendingInvitesCount > 0 {
                                        Text("\(pendingInvitesCount)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.brandHotPink)
                                            .clipShape(Capsule())
                                            .offset(x: -20)
                                    }
                                }

                                Divider().padding(.leading, 60)

                                // Squad Stories (NEW)
                                MenuButton(
                                    icon: "film.fill",
                                    title: "squad stories",
                                    iconColor: .brandPurple
                                ) {
                                    HapticFeedback.light()
                                    showLogoutMenu = false
                                    showEpisodeFeed = true
                                }

                                Divider().padding(.leading, 60)

                                // My Fridge
                                MenuButton(
                                    icon: "refrigerator",
                                    title: "my fridge",
                                    iconColor: .brandPurple
                                ) {
                                    HapticFeedback.light()
                                    showLogoutMenu = false
                                    showFridge = true
                                }

                                Divider().padding(.leading, 60)

                                // My Progress
                                MenuButton(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "my progress",
                                    iconColor: .brandGolden
                                ) {
                                    HapticFeedback.light()
                                    showLogoutMenu = false
                                    showWeeklyProgress = true
                                }

                                Divider().padding(.leading, 60)

                                // Browse
                                MenuButton(
                                    icon: "square.grid.2x2",
                                    title: "browse",
                                    iconColor: .brandHotPink
                                ) {
                                    HapticFeedback.light()
                                    showLogoutMenu = false
                                    showSocialFeed = true
                                }
                            }
                        }
                        .frame(width: 280)
                        .background(Color.white)
                        .cornerRadius(Spacing.cardCornerRadius)
                        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
                        .padding(.leading, Spacing.lg)
                        .padding(.top, 100)

                        Spacer()
                    }

                    Spacer()
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .task {
            await setupHomeScreen()
        }
        .fullScreenCover(isPresented: $showFoodSearch) {
            FoodIntentSearchView(onIntentSelected: { intent in
                handleFoodIntent(intent)
            })
        }
        .fullScreenCover(isPresented: $showProfile) {
            Text("Profile View - Coming Soon")
                .font(.title)
                .foregroundColor(.brandBlack)
        }
        .fullScreenCover(isPresented: $showMatchInvites) {
            Text("Match Invites View - Coming Soon")
                .font(.title)
                .foregroundColor(.brandBlack)
        }
        .fullScreenCover(isPresented: $showEpisodeFeed) {
            Text("Episode Feed - Coming Soon")
                .font(.title)
                .foregroundColor(.brandBlack)
        }
        .fullScreenCover(isPresented: $showCreateMatch) {
            Text("Create Match - Coming Soon")
                .font(.title)
                .foregroundColor(.brandBlack)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    HapticFeedback.medium()
                    showCreateMatch = true
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.brandHotPink, Color.brandCoral],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.brandHotPink.opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Browse View (Map)
    private var browseView: some View {
        ZStack {
            // Full-screen Map (iOS 17+ API)
            Map(position: .constant(.region(region))) {
                UserAnnotation()

                ForEach(vendorService.vendors) { vendor in
                    Annotation(vendor.name, coordinate: CLLocationCoordinate2D(latitude: vendor.latitude, longitude: vendor.longitude)) {
                        VendorMapBubble(vendor: vendor, citiBikeBlue: citiBikeBlue)
                            .onTapGesture {
                                handleVendorTap(vendor)
                            }
                    }
                }
            }
            .mapControlVisibility(.hidden)
            .ignoresSafeArea()

            // Overlay UI
            VStack(spacing: 0) {
                // Top Search Bar
                searchBar

                Spacer()

                // Bottom Sheets (only when needed)
                if showFoodResults {
                    foodResultsCard
                        .transition(.move(edge: .bottom))
                }
            }
        }
    }

    // MARK: - AI Placeholder View
    private var aiPlaceholderView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("AI View - Coming Soon")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Top Search Bar (Liquid Glass Style)
    private var searchBar: some View {
        // LIQUID GLASS SEARCH BAR
        Button {
            HapticFeedback.light()
            showFoodSearch = true
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                Text("search for food...")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md + 2)
        }
        .buttonStyle(.glass)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }

    // MARK: - Category Filter Pills (Corner iOS Style)
    private var categoryFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                CategoryPill(icon: "fork.knife", label: "restaurant", isSelected: false) {
                    HapticFeedback.selection()
                    // Filter restaurants
                }

                CategoryPill(icon: "cup.and.saucer.fill", label: "café", isSelected: false) {
                    HapticFeedback.selection()
                    // Filter cafes
                }

                CategoryPill(icon: "wineglass", label: "bar", isSelected: false) {
                    HapticFeedback.selection()
                    // Filter bars
                }

                CategoryPill(icon: "bag.fill", label: "shop", isSelected: false) {
                    HapticFeedback.selection()
                    // Filter shops
                }

                CategoryPill(icon: "square.grid.2x2", label: "browse", isSelected: false) {
                    HapticFeedback.selection()
                    showSocialFeed = true
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Old Bottom Action Card (REMOVED - Not in Corner iOS)
    private var bottomActionCard: some View {
        VStack(spacing: Spacing.lg) {
            // Drag Handle (iOS standard)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.brandGray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, Spacing.sm)

            // Header
            HStack {
                Text("discover nearby")
                    .font(.displayLarge)
                    .foregroundColor(.brandBlack)

                Spacer()

                // Browse Button - Hot Pink CTA
                Button(action: {
                    HapticFeedback.medium()
                    withAnimation(.springBouncy) {
                        showSocialFeed = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.labelSmall)
                        Text("browse")
                            .font(.labelSmall)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.brandHotPink, Color.brandCoral],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.brandHotPink.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)

            // Quick Actions - Modern Card Style
            VStack(spacing: Spacing.md) {
                // My Progress
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.springBouncy) {
                        showWeeklyProgress = true
                    }
                }) {
                    HStack(spacing: Spacing.md) {
                        // Icon Circle
                        ZStack {
                            Circle()
                                .fill(Color.brandGolden.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title3)
                                .foregroundColor(.brandGolden)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("my progress")
                                .font(.body)
                                .foregroundColor(.brandBlack)
                                .fontWeight(.semibold)

                            Text("track your meals & goals")
                                .font(.caption)
                                .foregroundColor(.brandGray)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.brandGray)
                    }
                    .padding(Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 4)
                    )
                }

                // My Fridge
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.springBouncy) {
                        showFridge = true
                    }
                }) {
                    HStack(spacing: Spacing.md) {
                        // Icon Circle
                        ZStack {
                            Circle()
                                .fill(Color.brandPurple.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "refrigerator")
                                .font(.title3)
                                .foregroundColor(.brandPurple)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("my fridge")
                                .font(.body)
                                .foregroundColor(.brandBlack)
                                .fontWeight(.semibold)

                            Text("manage ingredients & recipes")
                                .font(.caption)
                                .foregroundColor(.brandGray)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.brandGray)
                    }
                    .padding(Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 4)
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding(.bottom, Spacing.xxl)
        .background(
            Color.white
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }


    // MARK: - Setup
    private func setupHomeScreen() async {
        print("🏠 HomeScreen.setupHomeScreen called")

        locationManager.checkCurrentStatus()
        locationManager.startUpdatingLocation()

        // Wait a bit for location to update
        try? await Task.sleep(nanoseconds: 500_000_000)

        if let location = locationManager.currentLocation ?? CLLocationManager().location {
            print("   ✅ Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            userLocation = location
            region.center = location.coordinate
        } else {
            print("   ⚠️ No location available, using default NYU location")
            // Use NYU Washington Square as default
            let defaultLocation = CLLocation(latitude: 40.7295, longitude: -73.9965)
            userLocation = defaultLocation
            region.center = defaultLocation.coordinate
        }

        await fetchVendors()

        // Get user name from auth
        if authManager.currentUser?.phoneNumber != nil {
            // Extract name or use phone for greeting
            userName = "there"
        }

        print("🏠 HomeScreen setup complete, vendors count: \(vendorService.vendors.count)")
    }

    private func fetchVendors() async {
        print("🔄 HomeScreen.fetchVendors called")

        // Always use a location - fallback to NYU if needed
        let location = userLocation ?? CLLocation(latitude: 40.7295, longitude: -73.9965)
        print("   Using location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        await vendorService.fetchVendors(near: location, category: .all, radius: 5.0)

        print("   After fetch: vendorService.vendors.count = \(vendorService.vendors.count)")
    }

    private func recenterMap() {
        guard let location = userLocation ?? locationManager.currentLocation else {
            print("⚠️ No location available to recenter")
            return
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = location.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }

        print("📍 Map recentered to: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    private func handleVendorTap(_ vendor: Vendor) {
        Task {
            selectedVendor = vendor
            await loadMenuItems(for: vendor)

            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showVendorDetail = true
                }
            }
        }
    }

    private func loadMenuItems(for vendor: Vendor) async {
        guard let vendorId = vendor.id else {
            // Fallback to sample data if no vendor ID
            menuItems = generateSampleMenuItems(for: vendor)
            return
        }

        let items = await menuService.fetchMenuItems(for: vendorId)
        if items.isEmpty {
            // If no items in Firestore, use sample data
            menuItems = generateSampleMenuItems(for: vendor)
        } else {
            menuItems = items
        }
    }

    private func generateSampleMenuItems(for vendor: Vendor) -> [MenuItem] {
        let vendorId = vendor.id ?? ""
        let cuisine = vendor.cuisine?.lowercased() ?? ""
        let category = vendor.category

        // Generate menu based on category and cuisine
        if category == .cafes || cuisine.contains("coffee") {
            return [
                MenuItem(vendorId: vendorId, name: "Espresso", description: "Rich and bold single shot", price: 3.50, imageURL: "https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=400", category: "Coffee", isPopular: true, isNew: false, likedByFriends: ["Sarah"], dietaryTags: []),
                MenuItem(vendorId: vendorId, name: "Cappuccino", description: "Espresso with steamed milk and foam", price: 4.75, imageURL: "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400", category: "Coffee", isPopular: true, isNew: false, likedByFriends: ["Mike"], dietaryTags: []),
                MenuItem(vendorId: vendorId, name: "Croissant", description: "Buttery flaky French pastry", price: 4.25, imageURL: "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400", category: "Pastries", isPopular: false, isNew: false, likedByFriends: ["Emma"], dietaryTags: ["Vegetarian"]),
                MenuItem(vendorId: vendorId, name: "Avocado Toast", description: "Smashed avocado on sourdough with seeds", price: 9.50, imageURL: "https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=400", category: "Food", isPopular: true, isNew: false, likedByFriends: ["Sarah", "Emma"], dietaryTags: ["Vegetarian"])
            ]
        }

        if category == .groceries || cuisine.contains("grocery") {
            return [
                MenuItem(vendorId: vendorId, name: "Organic Bananas", description: "Fresh organic bananas, per lb", price: 0.79, imageURL: "https://images.unsplash.com/photo-1603833665858-e61d17a86224?w=400", category: "Produce", isPopular: true, isNew: false, likedByFriends: ["Jake"], dietaryTags: ["Vegan"]),
                MenuItem(vendorId: vendorId, name: "Greek Yogurt", description: "Low-fat Greek yogurt, 32oz", price: 5.99, imageURL: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400", category: "Dairy", isPopular: true, isNew: false, likedByFriends: ["Sarah", "Mike"], dietaryTags: ["Vegetarian"]),
                MenuItem(vendorId: vendorId, name: "Everything Bagels", description: "Fresh baked bagels, pack of 6", price: 4.49, imageURL: "https://images.unsplash.com/photo-1551106652-a5bcf4b29ab6?w=400", category: "Bakery", isPopular: false, isNew: false, likedByFriends: [], dietaryTags: ["Vegetarian"]),
                MenuItem(vendorId: vendorId, name: "Almond Butter", description: "Creamy almond butter, 16oz", price: 8.99, imageURL: "https://images.unsplash.com/photo-1571308020795-8c0e6e646144?w=400", category: "Spreads", isPopular: true, isNew: false, likedByFriends: ["Emma"], dietaryTags: ["Vegan"])
            ]
        }

        if cuisine.contains("italian") || cuisine.contains("pizza") {
            return [
                MenuItem(vendorId: vendorId, name: "Margherita Pizza", description: "Fresh mozzarella, basil, tomato sauce", price: 14.99, imageURL: "https://images.unsplash.com/photo-1604068549290-dea0e4a305ca?w=400", category: "Pizza", isPopular: true, isNew: false, likedByFriends: ["Sarah", "Mike"], dietaryTags: ["Vegetarian"]),
                MenuItem(vendorId: vendorId, name: "Pepperoni Pizza", description: "Classic pepperoni with mozzarella", price: 16.99, imageURL: "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400", category: "Pizza", isPopular: true, isNew: false, likedByFriends: ["Mike", "Jake"], dietaryTags: []),
                MenuItem(vendorId: vendorId, name: "Caesar Salad", description: "Romaine, parmesan, croutons, Caesar dressing", price: 9.99, imageURL: "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400", category: "Salads", isPopular: false, isNew: false, likedByFriends: ["Emma"], dietaryTags: ["Vegetarian"]),
                MenuItem(vendorId: vendorId, name: "Tiramisu", description: "Classic Italian coffee-flavored dessert", price: 7.99, imageURL: "https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400", category: "Desserts", isPopular: true, isNew: false, likedByFriends: ["Sarah"], dietaryTags: ["Vegetarian"])
            ]
        }

        if cuisine.contains("japanese") || cuisine.contains("sushi") {
            return [
                MenuItem(vendorId: vendorId, name: "Spicy Tuna Roll", description: "Fresh tuna with spicy mayo", price: 12.99, imageURL: "https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400", category: "Sushi", isPopular: true, isNew: false, likedByFriends: ["Sarah", "Emma"], dietaryTags: []),
                MenuItem(vendorId: vendorId, name: "California Roll", description: "Crab, avocado, cucumber", price: 10.99, imageURL: "https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?w=400", category: "Sushi", isPopular: true, isNew: false, likedByFriends: ["Mike"], dietaryTags: []),
                MenuItem(vendorId: vendorId, name: "Miso Soup", description: "Traditional Japanese soup with tofu", price: 4.99, imageURL: "https://images.unsplash.com/photo-1606491048652-b0e3e6a2099b?w=400", category: "Soups", isPopular: false, isNew: false, likedByFriends: [], dietaryTags: ["Vegetarian"]),
                MenuItem(vendorId: vendorId, name: "Salmon Sashimi", description: "Fresh Norwegian salmon, 6 pieces", price: 15.99, imageURL: "https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400", category: "Sashimi", isPopular: true, isNew: false, likedByFriends: ["Jake", "Sarah"], dietaryTags: [])
            ]
        }

        if cuisine.contains("mexican") {
            return [
                MenuItem(vendorId: vendorId, name: "Chicken Burrito", description: "Grilled chicken, rice, beans, salsa", price: 11.99, imageURL: "https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=400", category: "Burritos", isPopular: true, isNew: false, likedByFriends: ["Mike", "Jake"], dietaryTags: []),
                MenuItem(vendorId: vendorId, name: "Fish Tacos", description: "Grilled fish, cabbage slaw, chipotle sauce", price: 13.99, imageURL: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=400", category: "Tacos", isPopular: true, isNew: false, likedByFriends: ["Sarah"], dietaryTags: []),
                MenuItem(vendorId: vendorId, name: "Guacamole & Chips", description: "Fresh guacamole with tortilla chips", price: 7.99, imageURL: "https://images.unsplash.com/photo-1534939561126-855b8675edd7?w=400", category: "Appetizers", isPopular: false, isNew: false, likedByFriends: ["Emma"], dietaryTags: ["Vegan"]),
                MenuItem(vendorId: vendorId, name: "Carnitas Bowl", description: "Slow-cooked pork, rice, beans, toppings", price: 12.99, imageURL: "https://images.unsplash.com/photo-1604467707321-70d5ac45adda?w=400", category: "Bowls", isPopular: true, isNew: false, likedByFriends: ["Mike", "Sarah"], dietaryTags: [])
            ]
        }

        if cuisine.contains("burger") || cuisine.contains("american") {
            return [
                MenuItem(vendorId: vendorId, name: "Classic Burger", description: "Angus beef, lettuce, tomato, onion", price: 10.99, imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400", category: "Burgers", isPopular: true, isNew: false, likedByFriends: ["Mike", "Jake"], dietaryTags: []),
                MenuItem(vendorId: vendorId, name: "Bacon Cheeseburger", description: "Double patty, bacon, cheddar cheese", price: 13.99, imageURL: "https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400", category: "Burgers", isPopular: true, isNew: false, likedByFriends: ["Sarah", "Mike"], dietaryTags: []),
                MenuItem(vendorId: vendorId, name: "French Fries", description: "Crispy golden fries with sea salt", price: 4.99, imageURL: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400", category: "Sides", isPopular: true, isNew: false, likedByFriends: ["Jake"], dietaryTags: ["Vegetarian"]),
                MenuItem(vendorId: vendorId, name: "Milkshake", description: "Vanilla, chocolate, or strawberry", price: 5.99, imageURL: "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400", category: "Drinks", isPopular: false, isNew: false, likedByFriends: ["Emma"], dietaryTags: ["Vegetarian"])
            ]
        }

        if cuisine.contains("salad") || cuisine.contains("healthy") {
            return [
                MenuItem(vendorId: vendorId, name: "Kale Caesar", description: "Kale, parmesan, avocado, Caesar dressing", price: 11.99, imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400", category: "Salads", isPopular: true, isNew: false, likedByFriends: ["Sarah", "Emma"], dietaryTags: ["Vegetarian"]),
                MenuItem(vendorId: vendorId, name: "Chicken Power Bowl", description: "Grilled chicken, quinoa, veggies, tahini", price: 13.99, imageURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400", category: "Bowls", isPopular: true, isNew: false, likedByFriends: ["Sarah"], dietaryTags: []),
                MenuItem(vendorId: vendorId, name: "Acai Bowl", description: "Acai, granola, banana, berries, honey", price: 9.99, imageURL: "https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400", category: "Bowls", isPopular: false, isNew: false, likedByFriends: ["Emma"], dietaryTags: ["Vegetarian"]),
                MenuItem(vendorId: vendorId, name: "Green Juice", description: "Kale, spinach, apple, lemon, ginger", price: 7.99, imageURL: "https://images.unsplash.com/photo-1610970881699-44a5587cabec?w=400", category: "Drinks", isPopular: true, isNew: false, likedByFriends: ["Sarah", "Emma"], dietaryTags: ["Vegan"])
            ]
        }

        // Default restaurant menu
        return [
            MenuItem(vendorId: vendorId, name: "House Special", description: "Chef's signature dish of the day", price: 16.99, imageURL: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400", category: "Entrees", isPopular: true, isNew: false, likedByFriends: ["Sarah", "Mike"], dietaryTags: []),
            MenuItem(vendorId: vendorId, name: "Grilled Chicken", description: "Marinated chicken breast with vegetables", price: 14.99, imageURL: "https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=400", category: "Entrees", isPopular: true, isNew: false, likedByFriends: ["Mike"], dietaryTags: []),
            MenuItem(vendorId: vendorId, name: "Garden Salad", description: "Mixed greens, tomatoes, cucumbers, vinaigrette", price: 8.99, imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400", category: "Salads", isPopular: false, isNew: false, likedByFriends: ["Emma"], dietaryTags: ["Vegan"]),
            MenuItem(vendorId: vendorId, name: "Chocolate Cake", description: "Rich chocolate layer cake with frosting", price: 6.99, imageURL: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400", category: "Desserts", isPopular: true, isNew: false, likedByFriends: ["Sarah", "Emma"], dietaryTags: ["Vegetarian"])
        ]
    }

    // MARK: - Food Results Card

    private var foodResultsCard: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header with intent and close button
                    HStack {
                        if let intent = selectedIntent {
                            HStack(spacing: 8) {
                                Text(intent.emoji)
                                    .font(.system(size: 20))

                                Text(intent.displayText)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }

                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showFoodResults = false
                                selectedIntent = nil
                                foodResults = []
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Results or Uber-style skeleton shimmer
                    if isLoadingResults {
                        // Uber Eats-style shimmer loading
                        VStack(spacing: 16) {
                            ForEach(0..<4, id: \.self) { _ in
                                UberListItemSkeleton()
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // Actual results
                        ForEach(foodResults.prefix(10)) { result in
                            FoodResultCardCompact(result: result, citiBikeBlue: citiBikeBlue)
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
                .padding(.bottom, 34)
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
        .background(
            Color.white
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }


    // MARK: - Handle Food Intent

    private func handleFoodIntent(_ intent: FoodIntent) {
        guard let location = userLocation ?? locationManager.currentLocation else {
            print("❌ No location available")
            return
        }

        print("\n🔍 handleFoodIntent: \(intent.displayText)")
        selectedIntent = intent
        foodResults = [] // Clear previous results
        isLoadingResults = true

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showFoodResults = true
        }

        print("   ⏳ Shimmer should now be visible (isLoadingResults = true)")

        Task {
            let searchService = FoodSearchService.shared
            await searchService.search(intent: intent, userLocation: location)

            await MainActor.run {
                print("   ✅ Search complete, hiding shimmer")
                foodResults = searchService.results
                print("   📊 Results count: \(searchService.results.count)")
                isLoadingResults = false
            }
        }
    }
}

// MARK: - Vendor Map Bubble (Corner iOS Food Photo Style)
struct VendorMapBubble: View {
    let vendor: Vendor
    let citiBikeBlue: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            // Circular Food Photo (Corner iOS Style) - CACHED
            CachedAsyncImage(urlString: vendor.finalImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } placeholder: {
                placeholderView
            }

            // White border for visibility on map
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 50, height: 50)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

            // Liquid Glass badge with cuisine type
            Text(shortName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .glassEffect(in: Capsule())
                .offset(y: 30)
        }
    }

    // Placeholder view with category icon
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brandHotPink, Color.brandCoral],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)

            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundColor(.white)
        }
    }

    // Get icon based on vendor category
    private var categoryIcon: String {
        switch vendor.category {
        case .restaurants:
            if let cuisine = vendor.cuisine?.lowercased() {
                if cuisine.contains("italian") || cuisine.contains("pizza") {
                    return "fork.knife"
                } else if cuisine.contains("burger") || cuisine.contains("american") {
                    return "fork.knife"
                } else if cuisine.contains("salad") || cuisine.contains("bowl") {
                    return "leaf.fill"
                } else {
                    return "fork.knife"
                }
            }
            return "fork.knife"
        case .cafes:
            return "cup.and.saucer.fill"
        case .groceries:
            return "cart.fill"
        case .desserts:
            return "birthday.cake.fill"
        case .convenience:
            return "bag.fill"
        case .alcohol:
            return "wineglass.fill"
        case .all:
            return "fork.knife"
        }
    }

    // Shorten name for display
    private var shortName: String {
        let name = vendor.name
        if name.count > 12 {
            return String(name.prefix(10)) + "..."
        }
        return name
    }
}

// MARK: - Compact Food Result Card (for HomeScreen bottom sheet)

struct FoodResultCardCompact: View {
    let result: FoodResult
    let citiBikeBlue: Color

    var body: some View {
        HStack(spacing: 14) {
            // Vendor image - CACHED
            CachedAsyncImage(urlString: result.vendor.finalImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(10)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .cornerRadius(10)
            }

            // Vendor info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.vendor.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)

                Text(result.matchReason)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                if result.matchScore > 80 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)

                        Text("Great match · \(Int(result.matchScore))%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(result.walkTime)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)

                Text("min walk")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Category Pill Component (Corner iOS Style)
struct CategoryPill: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .brandBlack : .brandGray)

                Text(label)
                    .font(.body)
                    .foregroundColor(isSelected ? .brandBlack : .brandGray)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Menu Button Component (Profile Menu)
struct MenuButton: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.body)
                    .foregroundColor(.brandBlack)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.brandGray)
            }
            .padding(Spacing.lg)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    HomeScreen()
}
