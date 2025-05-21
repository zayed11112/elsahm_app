import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  Category? _selectedCategory;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Category? get selectedCategory => _selectedCategory;

  void setSelectedCategory(Category category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // جلب الأقسام من Supabase
      final categoriesData = await _categoryService.getCategories();

      // تحويل البيانات إلى كائنات Category
      _categories =
          categoriesData.map((data) => Category.fromSupabase(data)).toList();

      print('تم جلب ${_categories.length} قسم من Supabase');
    } catch (e) {
      _error = 'فشل في جلب الفئات: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(String name, String iconName, String iconUrl) async {
    try {
      final newCategory = Category(
        name: name,
        iconName: iconName,
        iconUrl: iconUrl,
        isActive: true,
        orderIndex: _categories.length + 1,
      );

      // إضافة القسم إلى Supabase
      final success = await _categoryService.addCategory(
        name,
        iconUrl,
        orderIndex: newCategory.orderIndex,
      );

      if (success) {
        await fetchCategories();
      } else {
        throw Exception('فشل في إضافة القسم');
      }
    } catch (e) {
      _error = 'فشل في إضافة فئة: $e';
      notifyListeners();
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      if (category.id == null) {
        throw Exception('معرف الفئة غير موجود');
      }

      // تحديث القسم في Supabase
      final success = await _categoryService
          .updateCategory(int.parse(category.id!), {
            'name': category.name,
            'icon_url': category.iconUrl,
            'order_index': category.orderIndex,
            'is_active': category.isActive,
          });

      if (success) {
        await fetchCategories();
      } else {
        throw Exception('فشل في تحديث القسم');
      }
    } catch (e) {
      _error = 'فشل في تحديث الفئة: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      // حذف القسم من Supabase
      final success = await _categoryService.deleteCategory(int.parse(id));

      if (success) {
        await fetchCategories();
      } else {
        throw Exception('فشل في حذف القسم');
      }
    } catch (e) {
      _error = 'فشل في حذف الفئة: $e';
      notifyListeners();
    }
  }
}
