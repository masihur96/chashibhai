import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1100;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 40 : 20),
          child: FadeTransition(
            opacity: _animationController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDesktop),
                const SizedBox(height: 32),
                _buildStatsGrid(constraints.maxWidth),
                const SizedBox(height: 40),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildRecentActivity()),
                      const SizedBox(width: 32),
                      Expanded(flex: 1, child: _buildSystemHealth()),
                    ],
                  )
                else ...[
                  _buildRecentActivity(),
                  const SizedBox(height: 32),
                  _buildSystemHealth(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: GoogleFonts.outfit(
                    fontSize: isDesktop ? 32 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back, Admin. Here is what is happening today.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isDesktop ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Today, ${DateTime.now().day} ${_getMonth(DateTime.now().month)}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildStatsGrid(double maxWidth) {
    int crossAxisCount;
    
    if (maxWidth > 1100) {
      crossAxisCount = 4;
    } else if (maxWidth > 768) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 180, // Fixed height to prevent RenderFlex overflow
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStatCard('Total Users', '1,245', '+12% this week', Icons.people_alt_rounded, const Color(0xFF4F46E5), true);
        } else if (index == 1) {
          return _buildStatCard('Active Orders', '342', '+5.2% this week', Icons.shopping_bag_rounded, const Color(0xFF10B981), true);
        } else if (index == 2) {
          return _buildStatCard('Total Escrow', '৳ 4.5M', '+2.4% this week', Icons.account_balance_wallet_rounded, const Color(0xFFF59E0B), true);
        } else {
          return _buildStatCard('Open Disputes', '12', '-3.1% this week', Icons.gavel_rounded, const Color(0xFFEF4444), false);
        }
      },
    );
  }

  Widget _buildStatCard(String title, String value, String trend, IconData icon, Color color, bool isPositive) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: isPositive ? Colors.green : Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trend.split(' ').first,
                            style: TextStyle(
                              color: isPositive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisExtent: 90,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final isWarning = index % 3 == 0;
              final isSuccess = index % 2 == 0 && !isWarning;
              
              final iconColor = isWarning ? Colors.orange : (isSuccess ? Colors.green : Colors.blue);
              final iconData = isWarning ? Icons.warning_amber_rounded : (isSuccess ? Icons.check_circle_outline_rounded : Icons.person_add_outlined);
              
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade50,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                  title: Text(
                    isWarning ? 'Dispute on #${1024 + index}' : (isSuccess ? 'Payment for #${2040 + index}' : 'New user (Farmer)'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${index + 1} hours ago',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: Colors.grey.shade300),
                      minimumSize: const Size(60, 36),
                    ),
                    child: Text(
                      'Review',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Health',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildHealthIndicator('Server Status', 'Operational', Colors.green, 1.0),
          const SizedBox(height: 20),
          _buildHealthIndicator('Database Load', '42%', Colors.blue, 0.42),
          const SizedBox(height: 20),
          _buildHealthIndicator('Active Connections', '8,432', Colors.orange, 0.75),
          const SizedBox(height: 20),
          _buildHealthIndicator('Storage Usage', '68%', Colors.purple, 0.68),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('View Detailed Analytics'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.grey.shade50,
                foregroundColor: Colors.black87,
                elevation: 0,
                side: BorderSide(color: Colors.grey.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String label, String value, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
