import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
            tooltip: 'AI Chat Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none),
            activeIcon: Icon(Icons.mic),
            label: 'Meetings',
            tooltip: 'Meeting Recordings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'Notes',
            tooltip: 'Personal Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
            tooltip: 'App Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/chat')) return 0;
    if (location.startsWith('/meetings')) return 1;
    if (location.startsWith('/notes')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0; // Default to chat
  }

  void _onItemTapped(int index, BuildContext context) {
    // Provide haptic feedback for better user experience
    HapticFeedback.lightImpact();
    
    switch (index) {
      case 0:
        context.goNamed('chat');
        break;
      case 1:
        context.goNamed('meetings');
        break;
      case 2:
        context.goNamed('notes');
        break;
      case 3:
        context.goNamed('settings');
        break;
    }
  }
}