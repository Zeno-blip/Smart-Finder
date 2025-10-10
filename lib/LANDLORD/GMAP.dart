import 'package:flutter/material.dart';
import 'package:smart_finder/CHAT.dart';
import 'APARTMENT.dart';
import 'Roominfo.dart';
import 'package:smart_finder/TOUR.dart';

class Gmap extends StatefulWidget {
  const Gmap({super.key, required this.roomId});
  final String roomId;

  @override
  State<Gmap> createState() => _GmapState();
}

class _GmapState extends State<Gmap> {
  final List<String> _roomImages = [
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
            // Map + back
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
                          MaterialPageRoute(builder: (_) => const Apartment()),
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

            // Thumbnails
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Tour(
                                  initialIndex: index,
                                  roomId: widget.roomId, // pass it
                                  titleHint: "Lopers Apartment",
                                  addressHint: "Brgy. Gravahan Alvaran St.",
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: imageHeight,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: (isHovered || isSelected)
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

            // Info + actions
            Container(
              color: const Color(0xFF5A7689),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lopers Apartment",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Brgy. Gravahan Alvaran St.",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                        4,
                        (_) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                      const Icon(
                        Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "(4.8) ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Previews",
                        style: TextStyle(color: Colors.white70),
                      ),
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
                    "Cozy 3rd floor room at SmartFinder Apartment in Matina, Davao City. "
                    "Comes with a single bed, table, chair, and Wi-Fi.",
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
                                builder: (_) => const Chat(
                                  image: "assets/images/landlord.png",
                                  name: "Landlord Name",
                                  messages: null,
                                ),
                              ),
                            );
                          },
                          child: const Text("Contact Landlord"),
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
                                builder: (_) => Roominfo(roomId: widget.roomId),
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
