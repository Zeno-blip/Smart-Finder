import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart';

class EditTour extends StatefulWidget {
  const EditTour({super.key});

  @override
  State<EditTour> createState() => _EditTourState();
}

class _EditTourState extends State<EditTour> {
  // Current selected panorama
  String _selectedImage = "assets/images/roompano.png";

  // Hotspots grouped by image
  final Map<String, List<Map<String, dynamic>>> _hotspotsByImage = {};

  // Available panorama images
  final List<String> _availableImages = [
    "assets/images/roompano.png",
    "assets/images/roompano2.png",
    "assets/images/roompano3.png",
  ];

  @override
  Widget build(BuildContext context) {
    // Get hotspots only for the current selected image
    List<Map<String, dynamic>> currentHotspots =
        _hotspotsByImage[_selectedImage] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF003B5C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003B5C),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "LABELED HOTSPOT",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
      ),
      body: Column(
        children: [
          // Panorama Viewer
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Panorama(
                    animSpeed: 0.0,
                    sensitivity: 1.0,
                    hotspots: currentHotspots.map((spot) {
                      return Hotspot(
                        latitude: spot["lat"],
                        longitude: spot["lon"],
                        width: 80,
                        height: 80,
                        widget: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              spot["lon"] += details.delta.dx * 0.1;
                              spot["lat"] -= details.delta.dy * 0.1;

                              if (spot["lat"] > 90) spot["lat"] = 90;
                              if (spot["lat"] < -90) spot["lat"] = -90;
                              if (spot["lon"] > 180) spot["lon"] -= 360;
                              if (spot["lon"] < -180) spot["lon"] += 360;
                            });
                          },
                          onTap: () {
                            if (spot["label"].isNotEmpty &&
                                spot["target"] != null &&
                                spot["target"].toString().isNotEmpty) {
                              setState(() {
                                _selectedImage = spot["target"];
                              });
                            } else {
                              _editHotspot(spot);
                            }
                          },
                          onLongPress: () {
                            if (spot["label"].isNotEmpty &&
                                spot["target"] != null &&
                                spot["target"].toString().isNotEmpty) {
                              _editHotspot(spot);
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              if (spot["label"].isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    spot["label"],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    child: Image.asset(_selectedImage),
                  ),
                ),

                // Add Hotspot button
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: FloatingActionButton(
                      backgroundColor: Colors.blue,
                      onPressed: _addHotspot,
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Thumbnails (with border)
          Container(
            color: const Color(0xFF6B8591),
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _availableImages.map((img) => _thumbnail(img)).toList(),
            ),
          ),

          // Save button
          Container(
            width: double.infinity,
            color: const Color(0xFF6B8591),
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003B5C),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                debugPrint("Hotspots by image: $_hotspotsByImage");
              },
              child: const Text(
                "SAVE",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Add hotspot to the current image
  void _addHotspot() {
    setState(() {
      _hotspotsByImage.putIfAbsent(_selectedImage, () => []);
      _hotspotsByImage[_selectedImage]!.add({
        "lat": 0.0,
        "lon": 0.0,
        "label": "",
        "target": null,
      });
    });
  }

  /// Edit hotspot (with delete button)
  void _editHotspot(Map<String, dynamic> spot) {
    TextEditingController controller = TextEditingController(
      text: spot["label"],
    );

    String? selectedTarget = spot["target"];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Hotspot"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Enter label"),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedTarget,
              decoration: const InputDecoration(
                labelText: "Navigate to",
                border: OutlineInputBorder(),
              ),
              items: _availableImages.map((img) {
                return DropdownMenuItem(
                  value: img,
                  child: Text(img.split("/").last),
                );
              }).toList(),
              onChanged: (value) {
                selectedTarget = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _hotspotsByImage[_selectedImage]?.remove(spot);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                spot["label"] = controller.text;
                spot["target"] = selectedTarget;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// Thumbnail with border
  Widget _thumbnail(String imagePath) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedImage = imagePath;
        });
      },
      child: Container(
        width: 150,
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _selectedImage == imagePath
                ? Colors.blueAccent
                : const Color.fromARGB(
                    255,
                    255,
                    255,
                    255,
                  ), // gray when not selected
            width: 3,
          ),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
