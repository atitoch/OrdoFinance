import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/resource_state.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/local/local_categories_repository.dart';
import '../data/categories_repository.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return LocalCategoriesRepository();
});

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, ResourceState<Category>>((ref) {
      return CategoriesNotifier(ref.watch(categoriesRepositoryProvider));
    });

final categoriesListProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesProvider).items;
});

final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  return ref
      .watch(categoriesListProvider)
      .where(
        (category) =>
            category.type == CategoryType.expense ||
            category.type == CategoryType.both,
      )
      .toList(growable: false);
});

final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  return ref
      .watch(categoriesListProvider)
      .where(
        (category) =>
            category.type == CategoryType.income ||
            category.type == CategoryType.both,
      )
      .toList(growable: false);
});

class CategoriesNotifier extends StateNotifier<ResourceState<Category>> {
  CategoriesNotifier(this._repository)
    : super(ResourceState<Category>.initial()) {
    refresh();
  }

  final CategoriesRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: state.items.isEmpty,
      isSyncing: state.items.isNotEmpty,
      clearError: true,
    );
    try {
      final categories = await _repository.getAll();
      state = ResourceState(items: categories);
    } catch (error) {
      state = state.copyWith(isLoading: false, isSyncing: false, error: error);
    }
  }

  Future<void> addCategory(Category category) async {
    final previous = state;
    state = state.copyWith(
      items: [...state.items, category],
      isSyncing: true,
      clearError: true,
    );
    try {
      final created = await _repository.create(category);
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == category.id) created else item,
        ],
        isSyncing: false,
      );
    } catch (error) {
      state = previous.copyWith(error: error);
    }
  }

  Future<void> updateCategory(Category category) async {
    final previous = state;
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == category.id) category else item,
      ],
      isSyncing: true,
      clearError: true,
    );
    try {
      final updated = await _repository.update(category);
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == updated.id) updated else item,
        ],
        isSyncing: false,
      );
    } catch (error) {
      state = previous.copyWith(error: error);
    }
  }

  Future<void> deleteCategory(String id) async {
    final previous = state;
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(growable: false),
      isSyncing: true,
      clearError: true,
    );
    try {
      await _repository.delete(id);
      state = state.copyWith(isSyncing: false);
    } catch (error) {
      state = previous.copyWith(error: error);
    }
  }
}
