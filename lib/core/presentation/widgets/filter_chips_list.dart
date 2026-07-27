import 'package:flutter/material.dart';
import '../../utils/localization.dart';

class FilterChipsList extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onSelected;
  final Map<String, String>? categoryTranslationKeys;
  final String languageCode;

  const FilterChipsList({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    this.categoryTranslationKeys,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          
          final labelText = categoryTranslationKeys != null 
            ? (categoryTranslationKeys![category] ?? category).tr(languageCode) 
            : category;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(labelText),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSelected(category);
                }
              },
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }
}
