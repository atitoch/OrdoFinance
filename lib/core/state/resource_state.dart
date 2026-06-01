import 'package:flutter/foundation.dart';

@immutable
class ResourceState<T> {
  const ResourceState({
    required this.items,
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
  });

  factory ResourceState.initial() => const ResourceState(items: []);

  final List<T> items;
  final bool isLoading;
  final bool isSyncing;
  final Object? error;

  bool get hasError => error != null;
  bool get isEmpty => items.isEmpty;

  ResourceState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isSyncing,
    Object? error,
    bool clearError = false,
  }) {
    return ResourceState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : error ?? this.error,
    );
  }
}
