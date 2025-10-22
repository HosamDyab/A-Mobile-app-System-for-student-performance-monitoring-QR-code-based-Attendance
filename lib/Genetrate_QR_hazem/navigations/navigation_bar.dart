/*import 'package:flutter/material.dart';

/// Flutter code sample for [NavigationBar].

void main() => runApp(const NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: NavigationExample());
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;
  NavigationDestinationLabelBehavior labelBehavior = NavigationDestinationLabelBehavior.alwaysShow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        labelBehavior:  labelBehavior = NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.qr_code_2_outlined,color:Color.fromRGBO(212, 115, 17, 1)),
            icon: Icon(Icons.qr_code_2_outlined,color:Color.fromRGBO(114, 107, 101, 1)), label: 'QR Scan',enabled:true ,),
          NavigationDestination(
            selectedIcon: Icon(Icons.data_thresholding,color:Color.fromRGBO(212, 115, 17, 1)),icon: Icon(Icons.data_thresholding,color:Color.fromRGBO(114, 107, 101, 1)), label: 'Dashboard'),
          NavigationDestination(
            selectedIcon: Icon(Icons.person,color:Color.fromRGBO(212, 115, 17, 1)),
            icon: Icon(Icons.person_outline,color:Color.fromRGBO(114, 107, 101, 1)),
            label: 'Profile',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Label behavior: ${labelBehavior.name}'),
            const SizedBox(height: 10),
            OverflowBar(
              spacing: 10.0,
              overflowAlignment: OverflowBarAlignment.center,
              overflowSpacing: 10.0,
              children: <Widget>[
               
              ],
            ),
          ],
        ),
      ),
    );
  }
}*/