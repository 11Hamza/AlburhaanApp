import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/books_provider.dart';
import '../providers/content_provider.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'loans_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    LoansScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load books
    final booksProvider = context.read<BooksProvider>();
    await booksProvider.loadBooks();

    // Load filters in background
    booksProvider.loadFilters();

    // Preload videos and ebooks for instant tab switching
    // This is a backup in case splash screen preload didn't complete
    context.read<ContentProvider>().preloadAll();

    // Load account summary
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isGuest) {
      authProvider.fetchSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          // Restrict loans tab for guests
          if (index == 2 && authProvider.isGuest) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login to view your loans'),
              ),
            );
            return;
          }
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: (authProvider.summary?.loansOverdue ?? 0) > 0,
              label: Text('${authProvider.summary?.loansOverdue ?? 0}'),
              child: const Icon(Icons.book_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: (authProvider.summary?.loansOverdue ?? 0) > 0,
              label: Text('${authProvider.summary?.loansOverdue ?? 0}'),
              child: const Icon(Icons.book),
            ),
            label: 'Loans',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
