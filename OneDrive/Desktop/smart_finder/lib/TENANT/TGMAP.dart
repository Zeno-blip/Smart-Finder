import 'package:flutter/material.dart';

import 'package:smart_finder/CHAT.dart';
import 'package:smart_finder/TENANT/TROOMINFO.dart';
import 'TAPARTMENT.dart';
import '../TOUR.dart';

class TenantGmap extends StatefulWidget {
  /// The room this map/detail page is about.
  final String roomId;

  /// Optional hints so the UI looks nice before the details page loads.
  final String? titleHint;
  final String? addressHint;
  final double? monthlyHint;

  const TenantGmap({
    super.key,
    required this.roomId,
    this.titleHint,
    this.addressHint,
    this.monthlyHint,
  });

  @override
  State<TenantGmap> createState() => _TenantGmapState();
}

class _TenantGmapState extends State<TenantGmap> {
  final List<String> _roomImages = const [
    'assets/images/roompano.png',
    'assets/images/roompano2.png',
    'assets/images/roompano3.png',
  ];

  int _hoveredIndex = -1;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const double imageHeight = 150;

    return Scaffold(
      backgroundColor: const Color(0xFF04395E),
      body: SafeArea(
        child: Column(
          children: [
            // Map + Back Button
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    child: SizedBox.expand(
                      child: Image.asset(
                        'assets/images/map.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 12,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TenantApartment(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black54, width: 1.5),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Room Thumbnails
            Container(
              color: const Color(0xFF5A7689),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: List.generate(_roomImages.length, (index) {
                  final img = _roomImages[index];
                  final isHovered = index == _hoveredIndex;
                  final isSelected = index == _selectedIndex;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hoveredIndex = index),
                        onExit: (_) => setState(() => _hoveredIndex = -1),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            // ✅ FIX: pass the required roomId + optional hints
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Tour(
                                  initialIndex: index,
                                  roomId: widget.roomId,
                                  titleHint: widget.titleHint,
                                  addressHint: widget.addressHint,
                                  monthlyHint: widget.monthlyHint,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: imageHeight,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isHovered || isSelected
                                    ? const Color.fromARGB(255, 27, 70, 120)
                                    : Colors.white24,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.asset(img, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Apartment Info Section
            Container(
              color: const Color(0xFF5A7689),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titleHint ?? "Smart-Finder Apartment",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.addressHint ?? "Brgy. Gravahan Alvaran St.",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star_border, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "(4.8) ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Previews", style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Room Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Cozy room with basic furnishings and Wi-Fi. Ideal for students and professionals.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003049),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Chat(
                                  image: "assets/images/landlord.png",
                                  name: "Mr. Landlord",
                                  messages: null,
                                ),
                              ),
                            );
                          },
                          child: const Text("Message Landlord"),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003049),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TenantRoomInfo(
                                  roomId: widget.roomId,
                                  titleHint: widget.titleHint,
                                  addressHint: widget.addressHint,
                                  monthlyHint: widget.monthlyHint,
                                ),
                              ),
                            );
                          },
                          child: const Text("More Details"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
