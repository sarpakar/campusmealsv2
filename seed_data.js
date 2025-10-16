#!/usr/bin/env node

/**
 * Campus Meals - Firestore Seed Data Script
 * Populates database with sample vendors, posts, and videos
 *
 * Usage:
 *   npm install firebase-admin
 *   node seed_data.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./Campusmealsv2/campusmeals-firebase-key.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'campusmealsv2-bd20b'
});

const db = admin.firestore();

// Sample vendor data near NYU
const vendors = [
  {
    id: 'veselka1',
    name: 'Veselka',
    category: 'restaurants',
    cuisine: 'Ukrainian Diner',
    image_url: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
    rating: 4.5,
    review_count: 1200,
    delivery_time: '20-30 min',
    delivery_fee: 2.99,
    minimum_order: 15.00,
    price_range: '$$',
    latitude: 40.7295,
    longitude: -73.9965,
    address: '144 2nd Ave, New York, NY 10003',
    is_open: true,
    tags: ['Fast Delivery', 'Popular', 'Ukrainian']
  },
  {
    id: 'shakeshack1',
    name: 'Shake Shack',
    category: 'restaurants',
    cuisine: 'Burgers & Fries',
    image_url: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
    rating: 4.3,
    review_count: 2500,
    delivery_time: '15-25 min',
    delivery_fee: 1.99,
    minimum_order: 10.00,
    price_range: '$$',
    latitude: 40.7410,
    longitude: -73.9896,
    address: 'Madison Square Park, NY 10010',
    is_open: true,
    tags: ['Fast Food', 'Popular', 'Burgers']
  },
  {
    id: 'traderjoes1',
    name: "Trader Joe's",
    category: 'groceries',
    cuisine: 'Grocery Store',
    image_url: 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800&q=80',
    rating: 4.6,
    review_count: 890,
    delivery_time: '30-45 min',
    delivery_fee: 0,
    minimum_order: 25.00,
    price_range: '$',
    latitude: 40.7324,
    longitude: -73.9977,
    address: '142 E 14th St, New York, NY 10003',
    is_open: true,
    tags: ['Free Delivery', 'Organic', 'Groceries']
  },
  {
    id: 'bluebottle1',
    name: 'Blue Bottle Coffee',
    category: 'cafes',
    cuisine: 'Specialty Coffee',
    image_url: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80',
    rating: 4.4,
    review_count: 650,
    delivery_time: '10-20 min',
    delivery_fee: 2.49,
    minimum_order: 5.00,
    price_range: '$$',
    latitude: 40.7280,
    longitude: -73.9950,
    address: '450 W 15th St, New York, NY 10011',
    is_open: true,
    tags: ['Coffee', 'Specialty', 'Quick']
  },
  {
    id: 'levainbakery1',
    name: 'Levain Bakery',
    category: 'desserts',
    cuisine: 'Bakery',
    image_url: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=800&q=80',
    rating: 4.7,
    review_count: 1800,
    delivery_time: '15-25 min',
    delivery_fee: 3.99,
    minimum_order: 8.00,
    price_range: '$$',
    latitude: 40.7290,
    longitude: -73.9920,
    address: '351 Amsterdam Ave, New York, NY 10024',
    is_open: true,
    tags: ['Cookies', 'Desserts', 'Famous']
  }
];

// Sample social posts
const posts = [
  {
    userId: 'user_001',
    userName: 'Sarah Chen',
    timestamp: admin.firestore.Timestamp.fromDate(new Date('2025-10-14T08:30:00')),
    location: 'East Village, NYC',
    restaurantName: 'Veselka',
    restaurantRating: 9.2,
    mealType: 'breakfast',
    foodPhotos: [
      'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800'
    ],
    notes: 'Best Ukrainian breakfast near NYU! The challah French toast is incredible.',
    dietTags: ['vegetarian', 'highProtein'],
    likes: 214,
    comments: 6,
    bookmarks: 250,
    isLikedByCurrentUser: false,
    isBookmarkedByCurrentUser: false
  },
  {
    userId: 'user_002',
    userName: 'Mike Rodriguez',
    timestamp: admin.firestore.Timestamp.fromDate(new Date('2025-10-13T12:15:00')),
    location: 'Union Square, NYC',
    restaurantName: 'Shake Shack',
    restaurantRating: 8.8,
    mealType: 'lunch',
    foodPhotos: [
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800'
    ],
    notes: 'Classic ShackBurger never disappoints. The cheese fries are a must!',
    dietTags: [],
    likes: 189,
    comments: 12,
    bookmarks: 95,
    isLikedByCurrentUser: false,
    isBookmarkedByCurrentUser: false
  },
  {
    userId: 'user_003',
    userName: 'Emma Liu',
    timestamp: admin.firestore.Timestamp.fromDate(new Date('2025-10-12T16:45:00')),
    location: 'Greenwich Village, NYC',
    restaurantName: 'Blue Bottle Coffee',
    restaurantRating: 9.0,
    mealType: 'snack',
    foodPhotos: [
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800'
    ],
    notes: 'Perfect study spot! The new oat milk latte is amazing.',
    dietTags: ['vegan'],
    likes: 156,
    comments: 8,
    bookmarks: 180,
    isLikedByCurrentUser: false,
    isBookmarkedByCurrentUser: false
  },
  {
    userId: 'user_004',
    userName: 'Jake Thompson',
    timestamp: admin.firestore.Timestamp.fromDate(new Date('2025-10-11T19:20:00')),
    location: 'West Village, NYC',
    restaurantName: 'Levain Bakery',
    restaurantRating: 9.5,
    mealType: 'dessert',
    foodPhotos: [
      'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=800'
    ],
    notes: 'These chocolate chip cookies are LEGENDARY. Worth the 20min wait!',
    dietTags: ['vegetarian'],
    likes: 302,
    comments: 24,
    bookmarks: 410,
    isLikedByCurrentUser: false,
    isBookmarkedByCurrentUser: false
  },
  {
    userId: 'user_005',
    userName: 'Olivia Park',
    timestamp: admin.firestore.Timestamp.fromDate(new Date('2025-10-10T13:00:00')),
    location: 'Union Square, NYC',
    restaurantName: "Trader Joe's",
    restaurantRating: 8.5,
    mealType: 'groceries',
    foodPhotos: [
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800'
    ],
    notes: 'Meal prep Sunday! Got everything I need for healthy dinners this week.',
    dietTags: ['healthy', 'vegan'],
    likes: 87,
    comments: 3,
    bookmarks: 62,
    isLikedByCurrentUser: false,
    isBookmarkedByCurrentUser: false
  }
];

// Sample TikTok videos for restaurants
const restaurantVideos = [
  {
    restaurant_id: 'levainbakery1',
    video_count: 3,
    videos: [
      {
        platform: 'tiktok',
        url: 'https://www.tiktok.com/@levainbakery/video/7234567890',
        video_id: '7234567890',
        thumbnail_url: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&q=80',
        title: 'The World Famous Chocolate Chip Cookie',
        views: 1250000
      },
      {
        platform: 'tiktok',
        url: 'https://www.tiktok.com/@levainbakery/video/7234567891',
        video_id: '7234567891',
        thumbnail_url: 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=400&q=80',
        title: 'Watch How We Make 6oz Cookies',
        views: 850000
      },
      {
        platform: 'instagram',
        url: 'https://www.instagram.com/reel/abc123/',
        video_id: 'abc123',
        thumbnail_url: 'https://images.unsplash.com/photo-1481070555726-e2fe8357725c?w=400&q=80',
        title: 'Behind the Scenes at Levain',
        views: 420000
      }
    ]
  },
  {
    restaurant_id: 'shakeshack1',
    video_count: 2,
    videos: [
      {
        platform: 'tiktok',
        url: 'https://www.tiktok.com/@shakeshack/video/7234567892',
        video_id: '7234567892',
        thumbnail_url: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80',
        title: 'How to Make a ShackBurger',
        views: 2100000
      },
      {
        platform: 'youtube',
        url: 'https://www.youtube.com/watch?v=xyz789',
        video_id: 'xyz789',
        thumbnail_url: 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=400&q=80',
        title: 'Shake Shack Kitchen Tour',
        views: 950000
      }
    ]
  },
  {
    restaurant_id: 'veselka1',
    video_count: 2,
    videos: [
      {
        platform: 'tiktok',
        url: 'https://www.tiktok.com/@veselkanyc/video/7234567893',
        video_id: '7234567893',
        thumbnail_url: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
        title: 'Ukrainian Breakfast in NYC',
        views: 680000
      },
      {
        platform: 'tiktok',
        url: 'https://www.tiktok.com/@veselkanyc/video/7234567894',
        video_id: '7234567894',
        thumbnail_url: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400&q=80',
        title: 'Making Pierogi from Scratch',
        views: 520000
      }
    ]
  }
];

async function seedDatabase() {
  console.log('\n🌱 Starting database seeding...\n');

  try {
    // Seed vendors
    console.log('📍 Seeding vendors...');
    for (const vendor of vendors) {
      await db.collection('vendors').doc(vendor.id).set(vendor);
      console.log(`   ✅ Added vendor: ${vendor.name}`);
    }
    console.log(`   📊 Total vendors added: ${vendors.length}\n`);

    // Seed posts
    console.log('📸 Seeding social posts...');
    for (const post of posts) {
      await db.collection('posts').add(post);
      console.log(`   ✅ Added post by ${post.userName} at ${post.restaurantName}`);
    }
    console.log(`   📊 Total posts added: ${posts.length}\n`);

    // Seed restaurant videos
    console.log('🎥 Seeding restaurant videos...');
    for (const videoDoc of restaurantVideos) {
      await db.collection('restaurant_videos').add(videoDoc);
      console.log(`   ✅ Added ${videoDoc.video_count} videos for restaurant: ${videoDoc.restaurant_id}`);
    }
    console.log(`   📊 Total video collections added: ${restaurantVideos.length}\n`);

    console.log('✅ Database seeding completed successfully!\n');
    console.log('📋 Summary:');
    console.log(`   - ${vendors.length} vendors`);
    console.log(`   - ${posts.length} social posts`);
    console.log(`   - ${restaurantVideos.length} video collections`);
    console.log(`   - ${restaurantVideos.reduce((sum, doc) => sum + doc.video_count, 0)} total videos\n`);

  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }

  process.exit(0);
}

// Run seeding
seedDatabase();
