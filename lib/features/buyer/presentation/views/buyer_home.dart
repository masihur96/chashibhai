import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../state/product_provider.dart';
import '../../../group/presentation/state/group_provider.dart';
import '../state/demand_provider.dart';
import '../../../wallet/presentation/state/order_provider.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../../core/presentation/widgets/product_card.dart';
import '../../../../core/presentation/widgets/custom_search_bar.dart';
import '../../../../core/presentation/widgets/filter_chips_list.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import './product_details.dart';
import './post_demand_screen.dart';
import './category_products_screen.dart';
import './notification_screen.dart';
import '../../../group/presentation/views/groups_list_screen.dart';
import '../../../group/presentation/views/group_detail_screen.dart';
import '../../../../core/utils/localization.dart';
import '../../../../core/models/models.dart';
import '../../../account/presentation/views/profile_screen.dart';
import './buyer_orders_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(),
          const GroupsListScreen(),
          const BuyerOrdersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: 'home'.tr(languageCode),
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: 'orders'.tr(languageCode),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: 'profile'.tr(languageCode),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PostDemandScreen()),
                );
              },
              backgroundColor: const Color(0xFF2E7D32),
              label: const Text('Call Price (Demand)', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.campaign, color: Colors.white),
            )
          : null,
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final products = context.watch<ProductProvider>().filteredProducts;
    final selectedCategory = context.watch<ProductProvider>().selectedCategory;
    final myGroups = context.watch<GroupProvider>().getMyGroups(context.watch<AuthProvider>().currentUser?.id);

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CustomSearchBar(
                hintText: 'search_placeholder'.tr(languageCode),
                onChanged: (value) => context.read<ProductProvider>().setSearchQuery(value),
              ),
              const SizedBox(height: 20),
              FilterChipsList(
                categories: const ['All', 'Vegetables', 'Fruits', 'Grains', 'Spices'],
                selectedCategory: selectedCategory,
                onSelected: (category) => context.read<ProductProvider>().setSelectedCategory(category),
                languageCode: languageCode,
                categoryTranslationKeys: const {
                  'All': 'cat_all',
                  'Vegetables': 'cat_veg',
                  'Fruits': 'cat_fruits',
                  'Grains': 'cat_grains',
                  'Spices': 'cat_spices',
                },
              ),
              const SizedBox(height: 20),

              // My Groups strip
              if (myGroups.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Buying Groups',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsListScreen())),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: myGroups.length,
                    itemBuilder: (context, index) {
                      return _buildGroupChip(context, myGroups[index]);
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                _buildJoinGroupBanner(context),
                const SizedBox(height: 20),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'available_supplies'.tr(languageCode),
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
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
                    child: Text('view_all'.tr(languageCode)),
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
                          'no_products'.tr(languageCode),
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
                      currencyFormat: NumberFormat.currency(symbol: '৳', decimalDigits: 0),
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
    );
  }

  Widget _buildGroupChip(BuildContext context, BuyingGroup group) {
    final progress = group.filledQuantity / group.targetQuantity;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id))),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.groups, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(group.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 4),
              Text(group.productName, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
              const SizedBox(height: 4),
              Text('${(progress * 100).toInt()}% filled', style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],)
        ),

    );
  }

  Widget _buildJoinGroupBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsListScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.groups_outlined, color: Theme.of(context).colorScheme.onPrimary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Join a Buying Group', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSecondaryContainer, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Pool with others to unlock bulk discounts from farmers!', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
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
              Text('Current City', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Dhaka, BD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                },
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Removed _buildSearchBar and _buildCategories as they use reusable core widgets
}
