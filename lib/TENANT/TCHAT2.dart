import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_finder/CHAT.dart';
import 'TLOGIN.dart';
import 'TAPARTMENT.dart';
import 'TPROFILE.dart';
import 'TSETTINGS.dart';
import 'TMYROOM.dart'; // ✅ Added MyRoom import

class TenantListChat extends StatefulWidget {
  const TenantListChat({super.key});

  @override
  State<TenantListChat> createState() => _TenantListChatState();
}

class _TenantListChatState extends State<TenantListChat> {
  int _selectedNavIndex = 1; // Default to 'Message' tab

  final List<Map<String, dynamic>> chats = [
    {
      'name': 'John Doe',
      'message': 'Hey, how are you?',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'unreadCount': 2,
      'isOnline': true,
      'image': 'assets/images/mykel.png',
    },
    {
      'name': 'Jane Smith',
      'message': 'Let’s meet tomorrow.',
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'unreadCount': 0,
      'isOnline': false,
      'image': 'assets/images/jhose.png',
    },
    {
      'name': 'Alex Johnson',
      'message': 'Got the files you sent.',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'unreadCount': 5,
      'isOnline': true,
      'image': 'assets/images/totski.png',
    },
    {
      'name': 'Emily Davis',
      'message': 'See you at the event!',
      'time': DateTime.now().subtract(const Duration(minutes: 15)),
      'unreadCount': 0,
      'isOnline': true,
      'image': 'assets/images/Josil.png',
    },
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredChats = chats.where((chat) {
      final nameLower = chat['name'].toLowerCase();
      final messageLower = chat['message'].toLowerCase();
      final searchLower = searchQuery.toLowerCase();
      return nameLower.contains(searchLower) ||
          messageLower.contains(searchLower);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'CHAT',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF04395E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search chats...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: filteredChats.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 72, color: Colors.black),
              itemBuilder: (context, index) {
                final chat = filteredChats[index];
                final bool isUnread = chat['unreadCount'] > 0;

                return ListTile(
                  tileColor: const Color(0xFFD9D9D9),
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade300,
                        child: ClipOval(
                          child: Image.asset(
                            chat['image'],
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                          ),
                        ),
                      ),
                      if (chat['isOnline'])
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    chat['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat['message'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread ? Colors.black : Colors.grey[600],
                      fontWeight: isUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: SizedBox(
                    height: 48,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(chat['time']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              chat['unreadCount'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Chat(
                          messages: [], // Placeholder messages
                          image: chat['image'] as String,
                          name: chat['name'] as String,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ✅ Updated Bottom Navigation Bar (copied from first code)
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedNavIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _selectedNavIndex) return; // Prevent reload
          setState(() {
            _selectedNavIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TenantApartment()),
            );
          } else if (index == 1) {
            // Already here
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TenantProfile()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TenantSettings()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyRoom()),
            );
          } else if (index == 5) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginT()),
              (route) => false,
            );
          }
        },
        items: [
          _buildNavItem(Icons.apartment, "Apartment", 0),
          _buildNavItem(Icons.message, "Message", 1),
          _buildNavItem(Icons.person, "Profile", 2),
          _buildNavItem(Icons.settings, "Settings", 3),
          _buildNavItem(Icons.door_front_door, "My Room", 4), // 🚪 Added
          _buildNavItem(Icons.logout, "Logout", 5),
        ],
      ),
    );
  }

  // ✅ Custom Nav Item with underline indicator
  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    bool isSelected = _selectedNavIndex == index;
    return BottomNavigationBarItem(
      icon: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: isSelected ? 20 : 0,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(icon),
        ],
      ),
      label: label,
    );
  }
}
