import 'package:flutter/material.dart';
import 'curved_bottom_nav_with_fab.dart';

/// Example implementation of CurvedBottomNavWithFAB
/// 
/// This shows how to use the curved bottom navigation bar with FAB
/// in your screens (Student, Teacher, etc.)
class CurvedBottomNavExample extends StatefulWidget {
  const CurvedBottomNavExample({super.key});

  @override
  State<CurvedBottomNavExample> createState() => _CurvedBottomNavExampleState();
}

class _CurvedBottomNavExampleState extends State<CurvedBottomNavExample> {
  int _currentIndex = 0;
  IconData _fabIcon = Icons.qr_code_scanner_rounded;

  // Define your navigation items (must be even number for symmetry)
  final List<NavBarItem> _navItems = const [
    NavBarItem(icon: Icons.home_rounded, label: 'Home'),
    NavBarItem(icon: Icons.calendar_today_rounded, label: 'Schedule'),
    NavBarItem(icon: Icons.bar_chart_rounded, label: 'Stats'),
    NavBarItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  // FAB icons that cycle on press
  final List<IconData> _fabIcons = [
    Icons.qr_code_scanner_rounded,
    Icons.refresh_rounded,
    Icons.menu_rounded,
    Icons.share_rounded,
  ];

  int _fabIconIndex = 0;

  void _handleNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // You can add page navigation logic here
    print('Navigated to index: $index');
  }

  void _handleFABPressed() {
    setState(() {
      _fabIconIndex = (_fabIconIndex + 1) % _fabIcons.length;
      _fabIcon = _fabIcons[_fabIconIndex];
    });
    
    // Add your FAB action here (e.g., open QR scanner, create post, etc.)
    print('FAB pressed! Current icon: $_fabIcon');
    
    // Example: Show dialog or navigate
    _showFABActionDialog();
  }

  void _showFABActionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_fabIcon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('FAB Action'),
          ],
        ),
        content: Text(
          'You pressed the FAB!\nCurrent action: ${_getFABActionName()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getFABActionName() {
    switch (_fabIcon) {
      case Icons.qr_code_scanner_rounded:
        return 'Scan QR Code';
      case Icons.refresh_rounded:
        return 'Refresh';
      case Icons.menu_rounded:
        return 'Menu';
      case Icons.share_rounded:
        return 'Share';
      default:
        return 'Action';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curved Bottom Nav Example'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _navItems[_currentIndex].icon,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _navItems[_currentIndex].label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Selected Index: $_currentIndex',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _handleFABPressed,
              icon: Icon(_fabIcon),
              label: Text('Cycle FAB Icon (${_getFABActionName()})'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedBottomNavWithFAB(
        currentIndex: _currentIndex,
        onTap: _handleNavTap,
        items: _navItems,
        onFABPressed: _handleFABPressed,
        fabIcon: _fabIcon,
        fabTooltip: _getFABActionName(),
      ),
    );
  }
}

