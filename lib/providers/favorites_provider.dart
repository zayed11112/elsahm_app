import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/apartment.dart';

class FavoritesProvider extends ChangeNotifier {
  final String _storageKey = 'favorites';
  Set<String> _favoriteIds = {};
  final List<Apartment> _favorites = [];
  bool _isLoading = false;

  // Getter methods
  Set<String> get favoriteIds => _favoriteIds;
  List<Apartment> get favorites => _favorites;
  bool get isLoading => _isLoading;

  // Constructor - load favorites from storage
  FavoritesProvider() {
    _loadFavorites();
  }

  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_storageKey) ?? [];

      _favoriteIds = favoritesJson.map((id) => id).toSet();

      // The actual Apartment objects will be loaded when needed
      // through the loadFavoriteApartments method

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _favoriteIds.toList());
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(Apartment apartment) async {
    final String apartmentId = apartment.id;

    if (_favoriteIds.contains(apartmentId)) {
      _favoriteIds.remove(apartmentId);
      _favorites.removeWhere((item) => item.id == apartmentId);
    } else {
      _favoriteIds.add(apartmentId);
      _favorites.add(apartment);
    }

    notifyListeners();
    await _saveFavorites();
    return _favoriteIds.contains(apartmentId);
  }

  // Check if an apartment is a favorite
  bool isFavorite(String apartmentId) {
    return _favoriteIds.contains(apartmentId);
  }

  // Clear all favorites
  Future<void> clearFavorites() async {
    _favoriteIds.clear();
    _favorites.clear();
    notifyListeners();
    await _saveFavorites();
  }

  // Load actual Apartment objects for the favorites
  // This would typically call a service to fetch the details
  // For now, we'll use the apartments that are added through toggleFavorite
  List<Apartment> getFavoriteApartments() {
    return _favorites;
  }
}
