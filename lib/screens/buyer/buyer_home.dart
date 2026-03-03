import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/product_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_details.dart';
import 'post_demand_screen.dart';
import 'category_products_screen.dart';

class BuyerHomeScreen extends ConsumerWidget {
  const BuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                   _buildSearchBar(ref),
                  const SizedBox(height: 20),
                  _buildCategories(ref, selectedCategory),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Supplies',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsScreen(category: selectedCategory),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (products.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: products[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(product: products[index]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PostDemandScreen()),
            );
          },
          backgroundColor: const Color(0xFF2E7D32),
          label: const Text('Call Price (Demand)', style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.campaign, color: Colors.white),
        ),

    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          Column(
            children: [
              Text(
                'Current City',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
              ),

              Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Dhaka, BD',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        decoration: const InputDecoration(
          hintText: 'Search products (Potato, Onion...)',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCategories(WidgetRef ref, String selectedCategory) {
    final categories = ['All', 'Vegetables', 'Fruits', 'Grains', 'Spices'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return GestureDetector(
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = category;
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
