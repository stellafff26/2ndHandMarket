# Campus Second-Hand Market

A modern campus second-hand marketplace mobile application built with Flutter and Firebase, designed for university students to buy and sell items safely within their own campus community.

## Core Features

### Authentication
- Firebase Email & Password Authentication
- University selection during registration
- User profile data stored in Firebase


### Homepage & Product browsing
- Browse all available listings
- Filter products by:
  - Category
  - University
- Keyword-based product search
- Product category icons synchronized with Insights dashboard


### Product Detail
- View:
  - Product image
  - Price
  - Description
  - University
  - Category
- Buy Now purchase flow
- Sold products are automatically disabled and displayed as: `Item Sold Out`


### Upload Product
Users can upload products with:
- Product image
- Product name
- Description
- Price
- Category

University information is automatically filled from the user profile.


### AI Features (Gemini API - gemini-2.5-flash)

#### AI Auto-fill
After uploading a product image, users can tap: `Auto-fill with AI`

The AI automatically generates:
- Product title
- Description
- Category


#### AI Smart Reply
Inside chat rooms, users can generate instant reply suggestions.

The AI:
- Reads recent chat history as context
- Identifies whether the user is a buyer or seller
- Generates concise and natural responses
- Adapts replies for campus marketplace conversations
  - meetup location suggestions
  - time arrangement
  - confirmation replies

### Data Visualization Dashboard

Insights dashboard includes:
- Total product listings
- Product distribution by category
- Matching category visualization icons


### Real-time Messaging

#### Product-based Chat
- Buyers and sellers can communicate directly for a specific item
- Each chat room is linked to its corresponding product


#### Chat Features
- Real-time messaging
- Message timestamps
- Opponent username display
- Direct product navigation from chat header

Users can tap the product card at the top of the chat room to instantly return to the Product Detail page.


### Notification (Inbox)
- Centralized conversation management
- Stores all historical buyer & seller chats
- Easy access to previous conversations
- A red dot appears when a new message is received and disappears once the message is read
- Bottom navigation bar Inbox icon displays a numbered unread message badge 
- Chats with unread messages are highlighted with a red dot and bolded text inside the Inbox list
- Opening a chat automatically marks messages as read and instantly updates unread counters


### Profile Page
Users can:
- View account information
- Manage uploaded products
- View favourites
- Access bought items
- Access sold items
- View dashboard analytics


### Favourites
- Save products using ❤️ button
- Remove saved products anytime
- Direct navigation to latest Product Detail page


### Bought Items Integration
Added dedicated Bought button support.

After purchasing a sold item:
- The system automatically retrieves buyer/seller IDs
- Users are redirected to a dedicated OrderChatScreen
- Simplifies post-purchase communication

### Sold Items Integration
Added dedicated Sold button support.

After an item is sold:
- Sellers can directly access the dedicated OrderChatScreen
- The system automatically retrieves the corresponding buyer information
- Simplifies after-sale communication and meetup arrangement


### Public User Profile

Users can tap another person's username inside chat rooms to access their public profile.

The public profile displays:
- User's name and university
- All products currently listed by that user


### Payment Workflow

```text
Buy Now → Confirm Payment → Payment Successful → Order Chat
```


### App Flow

```text
Register
   ↓
Login
   ↓
Homepage
   ├── Browse Products
   ├── Search / Filter
   └── Upload Product
            ↓
      Product Detail
            ↓
         Buy Now
            ↓
          Payment
            ↓
   Payment Successful
            ↓
   Real-time Order Chat

Profile Page
├── My Listings
├── Favourites
├── Bought Items
├── Inbox
└── Insights Dashboard

Chat System
├── Product Navigation
├── AI Smart Reply
└── Public User Profile
```


## Tech Stack

### Frontend
- Flutter

### Backend & Services
- Firebase Authentication
- Cloud Firestore
- Firebase Storage

### AI Integration
- Gemini API (`gemini-2.5-flash`)


## Setup Guide

### Prerequisites
- Flutter SDK installed 
- VS Code Flutter & Dart extensions installed
- Android Studio installed with Android emulator 

### Create the Flutter project
Open PowerShell in the folder where you want the project:
```
flutter create campuswap
cd campuswap
```

### Install dependencies
```
flutter pub get
```

### Connect Flutter to Firebase
```
dart pub global activate flutterfire_cli
flutterfire configure
```

### Run the app
Start your Android emulator, then:
```
flutter run
```
