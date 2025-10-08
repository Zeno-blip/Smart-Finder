import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_finder/CHAT.dart';

// ✅ Import all other pages for navigation
import 'package:smart_finder/LANDLORD/DASHBOARD.dart';
import 'package:smart_finder/LANDLORD/APARTMENT.dart';
import 'package:smart_finder/LANDLORD/TOTALROOM.dart';
import 'package:smart_finder/LANDLORD/LSETTINGS.dart';
import 'package:smart_finder/LANDLORD/LOGIN.dart';
import 'package:smart_finder/LANDLORD/TIMELINE.dart';
import 'package:smart_finder/LANDLORD/TENANTS.dart';

class ListChat extends StatefulWidget {
  const ListChat({super.key});

  @override
  State<ListChat> createState() => _ListChatState();
}

class _ListChatState extends State<ListChat> {
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
  int _selectedIndex = 4; // ✅ Message tab selected by default

  // ✅ Navigation handler (copied from Tenants)
  void _onNavTap(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Timeline()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Apartment()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Tenants()),
      );
    } else if (index == 4) {
      // Current page → Message
    } else if (index == 5) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TotalRoom()),
      );
    } else if (index == 6) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandlordSettings()),
      );
    } else if (index == 7) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

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
        title: const Text(
          'CHAT',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF04395E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // ✅ remove back button
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
                          messages: chat['message'],
                          image: chat['image'],
                          name: chat['name'],
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

      // ✅ Bottom Navigation Bar (copied from Tenants)
      bottomNavigationBar: Container(
        color: Colors.white,
        height: 60,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(8, (index) {
              IconData icon;
              String label;
              switch (index) {
                case 0:
                  icon = Icons.dashboard;
                  label = "Dashboard";
                  break;
                case 1:
                  icon = Icons.view_timeline_outlined;
                  label = "Timeline";
                  break;
                case 2:
                  icon = Icons.apartment;
                  label = "Apartment";
                  break;
                case 3:
                  icon = Icons.group;
                  label = "Tenants";
                  break;
                case 4:
                  icon = Icons.message;
                  label = "Message";
                  break;
                case 5:
                  icon = Icons.door_front_door;
                  label = "Rooms";
                  break;
                case 6:
                  icon = Icons.settings;
                  label = "Settings";
                  break;
                case 7:
                  icon = Icons.logout;
                  label = "Logout";
                  break;
                default:
                  icon = Icons.circle;
                  label = "";
              }

              bool isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () => _onNavTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      Icon(
                        icon,
                        color: isSelected ? Colors.black : Colors.black54,
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
