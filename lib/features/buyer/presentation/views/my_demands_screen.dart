import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/custom_search_bar.dart';
import '../../../../core/presentation/widgets/filter_chips_list.dart';
import '../../../../core/presentation/widgets/demand_card.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../state/demand_provider.dart';
import '../../../account/presentation/state/app_state_provider.dart';

class MyDemandsScreen extends StatefulWidget {
  const MyDemandsScreen({super.key});

  @override
  State<MyDemandsScreen> createState() => _MyDemandsScreenState();
}

class _MyDemandsScreenState extends State<MyDemandsScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'Active';

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final currentUser = context.watch<AuthProvider>().currentUser;
    final allDemands = context.watch<DemandProvider>().demands;

    // Filter demands for current user
    final myDemands = allDemands.where((d) => d.buyerId == currentUser?.id).toList();

    // Apply search and status filters
    final filteredDemands = myDemands.where((demand) {
      final matchesSearch = demand.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesStatus = false;
      if (_selectedStatus == 'Active') {
        matchesStatus = demand.status == DemandStatus.active;
      } else if (_selectedStatus == 'Expired') {
        matchesStatus = demand.status == DemandStatus.expired;
      } else if (_selectedStatus == 'Fulfilled') {
        matchesStatus = demand.status == DemandStatus.fulfilled;
      }

      return matchesSearch && matchesStatus;
    }).toList();

    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Demands', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: CustomSearchBar(
              hintText: 'Search demands...',
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilterChipsList(
              categories: const ['Active', 'Fulfilled', 'Expired'],
              selectedCategory: _selectedStatus,
              onSelected: (category) => setState(() => _selectedStatus = category),
              languageCode: languageCode,
            ),
          ),
          Expanded(
            child: filteredDemands.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.assignment_outlined,
                    title: 'No demands found',
                    subtitle: 'Try adjusting your filters or create a new demand.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDemands.length,
                    itemBuilder: (context, index) {
                      final demand = filteredDemands[index];
                      return DemandCard(
                        demand: demand,
                        currencyFormat: currencyFormat,
                        onTap: () {
                          // Navigate to DemandOffersScreen (Phase 2)
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
