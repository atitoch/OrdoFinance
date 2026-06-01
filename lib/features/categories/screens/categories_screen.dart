import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/category.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ordo_app_bar.dart';
import '../../../shared/widgets/resource_status_banner.dart';
import '../../../shared/widgets/ordo_button.dart';
import '../providers/categories_provider.dart';
import '../widgets/category_form_sheet.dart';
import '../widgets/category_row.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: OrdoAppBar(
          title: 'Categorías',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.gray900),
              onPressed: () => _showCategorySheet(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: AppColors.white,
              child: TabBar(
                labelStyle: GoogleFonts.instrumentSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: GoogleFonts.instrumentSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: AppColors.gray900,
                unselectedLabelColor: AppColors.gray500,
                indicatorColor: AppColors.gray900,
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: 'Gasto'),
                  Tab(text: 'Ingreso'),
                ],
              ),
            ),
            ResourceStatusBanner(
              isLoading: categoriesState.isLoading,
              isSyncing: categoriesState.isSyncing,
              error: categoriesState.error,
              onRetry: () => ref.read(categoriesProvider.notifier).refresh(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _CategoryList(
                    categories: ref.watch(expenseCategoriesProvider),
                    isLoading: categoriesState.isLoading,
                  ),
                  _CategoryList(
                    categories: ref.watch(incomeCategoriesProvider),
                    isLoading: categoriesState.isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.categories, required this.isLoading});

  final List<Category> categories;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading && categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBlock(height: 56),
            SizedBox(height: 8),
            SkeletonBlock(height: 56),
            SizedBox(height: 8),
            SkeletonBlock(height: 56),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return _EmptyCategories(onCreate: () => _showCategorySheet(context));
    }

    final rows = _buildRows(categories);

    return ReorderableListView.builder(
      padding: EdgeInsets.zero,
      buildDefaultDragHandles: false,
      itemCount: rows.length,
      onReorder: (oldIndex, newIndex) {},
      itemBuilder: (context, index) {
        final row = rows[index];
        final category = row.category;
        final child = InkWell(
          key: ValueKey(category.id),
          onTap: () => _showCategorySheet(context, category: category),
          child: CategoryRow(category: category, indent: row.indent),
        );

        if (category.isSystem) {
          return child;
        }

        return Dismissible(
          key: ValueKey('dismiss-${category.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppColors.expense,
            child: const Icon(Icons.delete_outline, color: AppColors.white),
          ),
          onDismissed: (_) {
            ref.read(categoriesProvider.notifier).deleteCategory(category.id);
          },
          child: child,
        );
      },
    );
  }

  List<_CategoryRowData> _buildRows(List<Category> categories) {
    final parents = categories.where((category) => category.parentId == null);
    final children = categories.where((category) => category.parentId != null);
    final rows = <_CategoryRowData>[];

    for (final parent in parents) {
      rows.add(_CategoryRowData(parent));
      final childRows = children.where((child) => child.parentId == parent.id);
      rows.addAll(
        childRows.map((child) => _CategoryRowData(child, indent: 16)),
      );
    }

    final orphanChildren = children.where(
      (child) => !categories.any((category) => category.id == child.parentId),
    );
    rows.addAll(orphanChildren.map(_CategoryRowData.new));

    return rows;
  }
}

class _CategoryRowData {
  const _CategoryRowData(this.category, {this.indent = 0});

  final Category category;
  final double indent;
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_outlined, size: 48, color: AppColors.gray300),
          const SizedBox(height: 16),
          Text(
            'Sin categorías',
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray900,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca + para crear una',
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray500,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: OrdoButton.outlined(
              label: 'Crear categoría',
              onPressed: onCreate,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCategorySheet(BuildContext context, {Category? category}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CategoryFormSheet(category: category),
  );
}
