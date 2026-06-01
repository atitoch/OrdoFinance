import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

Color parseCategoryColor(String value) {
  final normalized = value.trim().replaceFirst('#', '');
  final hex = switch (normalized.length) {
    6 => 'FF$normalized',
    8 => normalized,
    _ => null,
  };

  if (hex == null) {
    return AppColors.gray600;
  }

  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? AppColors.gray600 : Color(parsed);
}

IconData parseCategoryIcon(String value) {
  return _materialIconNames[value.trim().toLowerCase()] ??
      Icons.category_outlined;
}

const _materialIconNames = <String, IconData>{
  // Finance & accounts
  'account_balance': Icons.account_balance_outlined,
  'bank': Icons.account_balance_outlined,
  'cash': Icons.payments_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'savings': Icons.savings_outlined,
  'investment': Icons.show_chart_outlined,
  'income': Icons.trending_up_outlined,
  'trending_up': Icons.trending_up_outlined,
  'transfer': Icons.swap_horiz,

  // Work & business
  'briefcase': Icons.business_center_outlined,
  'business': Icons.business_center_outlined,
  'salary': Icons.work_outline,
  'work': Icons.work_outline,
  'freelance': Icons.laptop_outlined,
  'office': Icons.corporate_fare_outlined,

  // Food & drink
  'food': Icons.restaurant_outlined,
  'restaurant': Icons.restaurant_outlined,
  'utensils': Icons.restaurant_outlined,
  'groceries': Icons.shopping_basket_outlined,
  'shopping_cart': Icons.shopping_cart_outlined,
  'coffee': Icons.local_cafe_outlined,
  'fastfood': Icons.fastfood_outlined,
  'pizza': Icons.local_pizza_outlined,
  'cake': Icons.cake_outlined,
  'bar': Icons.local_bar_outlined,

  // Transport
  'car': Icons.directions_car_outlined,
  'directions_car': Icons.directions_car_outlined,
  'transport': Icons.directions_bus_outlined,
  'bus': Icons.directions_bus_outlined,
  'train': Icons.train_outlined,
  'taxi': Icons.local_taxi_outlined,
  'bike': Icons.pedal_bike_outlined,
  'flight': Icons.flight_outlined,
  'travel': Icons.flight_outlined,
  'boat': Icons.directions_boat_outlined,

  // Health & wellness
  'health': Icons.local_hospital_outlined,
  'medical': Icons.local_hospital_outlined,
  'heart': Icons.favorite_outline,
  'favorite': Icons.favorite_outline,
  'gym': Icons.fitness_center_outlined,
  'spa': Icons.spa_outlined,
  'pharmacy': Icons.local_pharmacy_outlined,
  'psychology': Icons.psychology_outlined,

  // Home & utilities
  'home': Icons.home_outlined,
  'utilities': Icons.bolt_outlined,
  'bolt': Icons.bolt_outlined,
  'autorenew': Icons.autorenew,
  'plumbing': Icons.plumbing_outlined,
  'cleaning': Icons.cleaning_services_outlined,
  'furniture': Icons.chair_outlined,
  'tools': Icons.handyman_outlined,

  // Entertainment & leisure
  'entertainment': Icons.movie_outlined,
  'movie': Icons.movie_outlined,
  'music': Icons.music_note_outlined,
  'headphones': Icons.headphones_outlined,
  'game': Icons.sports_esports_outlined,
  'sports': Icons.sports_outlined,
  'streaming': Icons.live_tv_outlined,
  'tv': Icons.tv_outlined,
  'theater': Icons.theater_comedy_outlined,

  // Shopping & personal
  'shopping': Icons.shopping_bag_outlined,
  'clothes': Icons.checkroom_outlined,
  'beauty': Icons.face_outlined,
  'gifts': Icons.card_giftcard_outlined,
  'gift': Icons.card_giftcard_outlined,

  // Education
  'education': Icons.school_outlined,
  'book': Icons.menu_book_outlined,
  'library': Icons.local_library_outlined,

  // Tech & subscriptions
  'phone': Icons.phone_outlined,
  'smartphone': Icons.smartphone_outlined,
  'internet': Icons.wifi_outlined,
  'subscription': Icons.subscriptions_outlined,
  'cloud': Icons.cloud_outlined,

  // Kids & family
  'child': Icons.child_care_outlined,
  'family': Icons.family_restroom_outlined,
  'stroller': Icons.stroller_outlined,

  // Pets
  'pet': Icons.pets_outlined,
  'pets': Icons.pets_outlined,

  // Social & charity
  'donation': Icons.volunteer_activism_outlined,
  'charity': Icons.volunteer_activism_outlined,
  'social': Icons.people_outline,

  // Taxes & insurance
  'tax': Icons.receipt_long_outlined,
  'insurance': Icons.security_outlined,

  // Travel & accommodation
  'hotel': Icons.hotel_outlined,
  'vacation': Icons.beach_access_outlined,
  'map': Icons.map_outlined,

  // Other
  'category': Icons.category_outlined,
  'other': Icons.more_horiz,
};
