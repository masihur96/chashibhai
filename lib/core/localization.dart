import 'package:flutter/material.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'app_title': 'ChashiBhai',
      'available_supplies': 'Available Supplies',
      'view_all': 'View All',
      'search_placeholder': 'Search products...',
      'no_products': 'No products found',
      'categories': 'Categories',
      'notifications': 'Notifications',
      'settings': 'Settings',
      'profile': 'My Profile',
      'transactions': 'Transactions',
      'wallet': 'My Wallet',
      'help_support': 'Help & Support',
      'about': 'About ChashiBhai',
      'sign_out': 'Sign Out',
      'edit_profile': 'Edit Profile',
      'save_changes': 'Save Changes',
      'language': 'App Language',
      'push_notifications': 'Push Notifications',
      'biometric': 'Biometric Login',
      'order_delivered': 'Order Delivered',
      'payment_received': 'Payment Received',
      'price_alert': 'Price Alert',
      'welcome_promo': 'Welcome to ChashiBhai!',
      'cat_all': 'All',
      'cat_veg': 'Vegetables',
      'cat_fruits': 'Fruits',
      'cat_grains': 'Grains',
      'cat_spices': 'Spices',
    },
    'bn': {
      'app_title': 'চাষীভাই',
      'available_supplies': 'উপলব্ধ পণ্যসমূহ',
      'view_all': 'সব দেখুন',
      'search_placeholder': 'পণ্য খুঁজুন...',
      'no_products': 'কোন পণ্য পাওয়া যায়নি',
      'categories': 'বিভাগসমূহ',
      'notifications': 'নোটিফিকেশন',
      'settings': 'সেটিংস',
      'profile': 'আমার প্রোফাইল',
      'transactions': 'লেনদেন',
      'wallet': 'আমার ওয়ালেট',
      'help_support': 'সাহায্য এবং সমর্থন',
      'about': 'চাষীভাই সম্পর্কে',
      'sign_out': 'সাইন আউট',
      'edit_profile': 'প্রোফাইল সংশোধন',
      'save_changes': 'পরিবর্তন সংরক্ষণ করুন',
      'language': 'অ্যাপের ভাষা',
      'push_notifications': 'পুশ নোটিফিকেশন',
      'biometric': 'বায়োমেট্রিক লগইন',
      'order_delivered': 'অর্ডার ডেলিভারি হয়েছে',
      'payment_received': 'পেমেন্ট গ্রহণ করা হয়েছে',
      'price_alert': 'মূল্য সতর্কতা',
      'welcome_promo': 'চাষীভাই-এ স্বাগতম!',
      'cat_all': 'সব',
      'cat_veg': 'শাকসবজি',
      'cat_fruits': 'ফলমূল',
      'cat_grains': 'শস্যদানা',
      'cat_spices': 'মসলা',
    },
  };

  static String translate(BuildContext context, String key) {
    // This is a simplified helper. In a full app, we'd use a provider or InheritedWidget.
    // For now, we'll provide a way to access it via context later or through a provider.
    return translations['en']?[key] ?? key;
  }
}

extension LocalizationExtension on String {
  String tr(String locale) {
    return AppTranslations.translations[locale]?[this] ?? this;
  }
}
