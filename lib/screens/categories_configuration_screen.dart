import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../widgets/category_name_prompt.dart';
import '../widgets/delete_category_prompt.dart';

class CategoriesConfigurationScreen extends StatelessWidget {
  const CategoriesConfigurationScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final categories = List<String>.of(controller.categories)
          ..sort(
            (a, b) => normalizeLatinText(
              l10n.categoryLabel(a),
            ).compareTo(normalizeLatinText(l10n.categoryLabel(b))),
          );
        final displayCategories = categories.map(l10n.categoryLabel).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.categoriesTab),
            actions: [
              IconButton(
                tooltip: l10n.addCategory,
                onPressed: controller.hasReachedCategoryLimit
                    ? null
                    : () async {
                        final name = await showCategoryNamePrompt(
                          context: context,
                          title: l10n.addCategory,
                          existingCategories: displayCategories,
                        );
                        if (name == null || !context.mounted) {
                          return;
                        }

                        final addedCategory = await controller.addCategory(name);
                        if (addedCategory != null || !context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.maxCategoriesReached(maxCategoryCount),
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: categories.isEmpty
              ? Center(child: Text(l10n.emptyCategories))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final localizedLabel = l10n.categoryLabel(category);

                    return Card(
                      key: ValueKey(category),
                      child: ListTile(
                        title: Text(localizedLabel),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final renamedCategory = await showCategoryNamePrompt(
                                context: context,
                                title: l10n.editCategory,
                                existingCategories: displayCategories,
                                initialValue: localizedLabel,
                                excludedCategory: localizedLabel,
                              );
                              if (renamedCategory != null) {
                                await controller.renameCategory(
                                  currentName: category,
                                  newName: renamedCategory,
                                );
                              }
                              return;
                            }

                            final usage = controller.getCategoryUsage(category);
                            if (usage == null) {
                              return;
                            }

                            final shouldDelete = await showDeleteCategoryPrompt(
                              context: context,
                              categoryLabel: localizedLabel,
                              usage: usage,
                            );
                            if (!shouldDelete) {
                              return;
                            }

                            await controller.deleteCategoryAndUsages(category);
                          },
                          itemBuilder: (menuContext) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text(l10n.edit),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Theme.of(menuContext).colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.delete,
                                    style: TextStyle(
                                      color: Theme.of(menuContext).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
