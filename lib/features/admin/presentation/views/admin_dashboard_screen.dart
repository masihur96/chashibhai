import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard Overview', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Welcome back, Admin. Here is what is happening today.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                shrinkWrap: true,
                childAspectRatio: 2.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(context, 'Total Users', '1,245', Icons.people, Colors.blue),
                  _buildStatCard(context, 'Active Orders', '342', Icons.shopping_cart, Colors.green),
                  _buildStatCard(context, 'Total Escrow', '৳ 4.5M', Icons.lock, Colors.orange),
                  _buildStatCard(context, 'Open Disputes', '12', Icons.warning_amber_rounded, Colors.red),
                ],
              );
            },
          ),
          const SizedBox(height: 48),
          Text('Recent Platform Activity', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: const Text('New user verification request (Farmer)'),
                  subtitle: Text('${index + 1} hours ago'),
                  trailing: TextButton(onPressed: () {}, child: const Text('Review')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
