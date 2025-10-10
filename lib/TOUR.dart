// TOUR.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart' as pano;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'TENANT/TROOMINFO.dart';
import 'CHAT.dart';

class Tour extends StatefulWidget {
  final int initialIndex;
  final String roomId;
  final String? titleHint;
  final String? addressHint;
  final double? monthlyHint;

  const Tour({
    super.key,
    required this.initialIndex,
    required this.roomId,
    this.titleHint,
    this.addressHint,
    this.monthlyHint,
  });

  @override
  State<Tour> createState() => _TourState();
}

class _TourState extends State<Tour> {
  final _sb = Supabase.instance.client;

  final List<_NetImage> _images = [];
  final Map<String, int> _indexById = {};
  final Map<int, List<_HS>> _hotspotsByIndex = {};

  int _currentIndex = 0;
  int _hoveredIndex = -1;
  bool _showHud = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _load();
  }

  // -------- angle helpers --------
  double _degToRad(num d) => d.toDouble() * math.pi / 180.0;
  double _normLon(double r) {
    while (r > math.pi) r -= 2 * math.pi;
    while (r < -math.pi) r += 2 * math.pi;
    return r;
  }

  double _clampLat(double r) => r.clamp(-math.pi / 2, math.pi / 2);

  /// Accept degrees or radians; always return radians.
  double? _toRadiansAuto(num? v, {required bool isLat}) {
    if (v == null) return null;
    final d = v.toDouble();
    final radLimit = isLat ? (math.pi / 2 + 1e-6) : (math.pi + 1e-6);
    // If |value| looks like radians, keep it; otherwise treat as degrees.
    if (d.abs() <= radLimit) return isLat ? _clampLat(d) : _normLon(d);
    final r = _degToRad(d);
    return isLat ? _clampLat(r) : _normLon(r);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) Images
      final imgs = await _sb
          .from('room_images')
          .select('id,image_url,sort_order')
          .eq('room_id', widget.roomId)
          .order('sort_order', ascending: true);

      _images
        ..clear()
        ..addAll([
          for (final r in (imgs as List))
            _NetImage(
              id: r['id'] as String,
              url: (r['image_url'] as String?)?.trim() ?? '',
            ),
        ]);

      _indexById
        ..clear()
        ..addEntries(
          _images.asMap().entries.map((e) => MapEntry(e.value.id, e.key)),
        );

      // 2) Hotspots
      _hotspotsByIndex.clear();
      if (_images.isNotEmpty) {
        final hsRows = await _sb
            .from('hotspots')
            .select('source_image_id,target_image_id,dx,dy,label')
            .eq('room_id', widget.roomId);

        for (final r in (hsRows as List)) {
          final srcId = r['source_image_id'] as String?;
          final tgtId = r['target_image_id'] as String?;
          if (srcId == null || tgtId == null) continue;

          final srcIdx = _indexById[srcId];
          final tgtIdx = _indexById[tgtId];
          if (srcIdx == null || tgtIdx == null) continue;

          final lon = _toRadiansAuto(r['dx'] as num?, isLat: false);
          final lat = _toRadiansAuto(r['dy'] as num?, isLat: true);
          if (lon == null || lat == null) continue;

          final hs = _HS(
            longitude: _normLon(lon),
            latitude: _clampLat(lat),
            targetIndex: tgtIdx,
            label: r['label'] as String?,
          );
          _hotspotsByIndex.putIfAbsent(srcIdx, () => []).add(hs);
        }
      }

      // 3) Fallback chain if DB returned none (useful for testing)
      final hasAnyHS = _hotspotsByIndex.values.any((l) => l.isNotEmpty);
      if (!hasAnyHS && _images.length >= 2) {
        for (int i = 0; i < _images.length; i++) {
          final next = (i + 1) % _images.length;
          _hotspotsByIndex[i] = [
            _HS(
              longitude: 0.0, // front
              latitude: 0.0,
              targetIndex: next,
              label: 'Go to ${next + 1}',
            ),
          ];
        }
      }

      if (_images.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No images found for this room.';
          _currentIndex = 0;
        });
        return;
      }

      _currentIndex = _currentIndex.clamp(0, _images.length - 1);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load tour: $e';
      });
    }
  }

  void _goTo(int index) {
    setState(() {
      _currentIndex = index.clamp(0, _images.length - 1);
    });
  }

  void _next() => _goTo(_currentIndex + 1);
  void _prev() => _goTo(_currentIndex - 1);

  void _openDetails() {
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
  }

  @override
  Widget build(BuildContext context) {
    const double imageThumbHeight = 150;

    return Scaffold(
      backgroundColor: const Color(0xFF0A3D62),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : (_error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // ---- Panorama ----
                        Expanded(
                          flex: 3,
                          child: Stack(
                            children: [
                              pano.Panorama(
                                animSpeed: 0.0,
                                sensorControl: pano.SensorControl.None,
                                onTap: (_, __, ___) => _openDetails(),
                                hotspots: [
                                  for (final h
                                      in _hotspotsByIndex[_currentIndex] ??
                                          const <_HS>[])
                                    pano.Hotspot(
                                      longitude: h.longitude,
                                      latitude: h.latitude,
                                      width: 72,
                                      height: 72,
                                      widget: GestureDetector(
                                        behavior: HitTestBehavior
                                            .opaque, // makes taps easy
                                        onTap: () => _goTo(h.targetIndex),
                                        child: _marker(h.label),
                                      ),
                                    ),
                                ],
                                child: _images[_currentIndex].url.isEmpty
                                    ? Image.asset(
                                        'assets/images/roompano.png',
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        _images[_currentIndex].url,
                                        key: ValueKey(
                                          _images[_currentIndex].url,
                                        ),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                              child: Text(
                                                'Image failed to load',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                      ),
                              ),

                              // Back button
                              Positioned(
                                top: 20,
                                left: 12,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      border: Border.all(
                                        color: const Color(0xFF003049),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),

                              // HUD
                              if (_showHud)
                                Positioned(
                                  top: 20,
                                  right: 12,
                                  child: Row(
                                    children: [
                                      _hudBtn(Icons.chevron_left, _prev),
                                      const SizedBox(width: 8),
                                      _hudBtn(Icons.chevron_right, _next),
                                      const SizedBox(width: 8),
                                      _hudBtn(
                                        Icons.visibility_off,
                                        () => setState(() => _showHud = false),
                                      ),
                                    ],
                                  ),
                                ),
                              if (!_showHud)
                                Positioned(
                                  top: 20,
                                  right: 12,
                                  child: _hudBtn(
                                    Icons.visibility,
                                    () => setState(() => _showHud = true),
                                  ),
                                ),

                              // tiny debug: how many hotspots on this image
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'HS: ${(_hotspotsByIndex[_currentIndex] ?? const []).length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ---- Info & thumbs ----
                        Container(
                          color: const Color(0xFF5A7689),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(_images.length, (
                                  index,
                                ) {
                                  final isHovered = index == _hoveredIndex;
                                  final isSelected = index == _currentIndex;
                                  final url = _images[index].url;

                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                      ),
                                      child: MouseRegion(
                                        onEnter: (_) => setState(
                                          () => _hoveredIndex = index,
                                        ),
                                        onExit: (_) =>
                                            setState(() => _hoveredIndex = -1),
                                        child: GestureDetector(
                                          onTap: () => _goTo(index),
                                          child: Container(
                                            height: imageThumbHeight,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: isHovered || isSelected
                                                    ? const Color.fromARGB(
                                                        255,
                                                        27,
                                                        70,
                                                        120,
                                                      )
                                                    : Colors.white24,
                                                width: 3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              child: url.isEmpty
                                                  ? Image.asset(
                                                      'assets/images/roompano.png',
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Image.network(
                                                      url,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => const ColoredBox(
                                                            color:
                                                                Colors.black12,
                                                            child: Center(
                                                              child: Icon(
                                                                Icons
                                                                    .broken_image,
                                                              ),
                                                            ),
                                                          ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.titleHint ?? "Apartment",
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
                                    widget.addressHint ?? "—",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  SizedBox(
                                    width: 180,
                                    height: 48,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF003049,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const Chat(
                                              image:
                                                  "assets/images/roompano.png",
                                              name: "Landlord",
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
                                        backgroundColor: const Color(
                                          0xFF003049,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: _openDetails,
                                      child: const Text("More Details"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
      ),
    );
  }

  Widget _marker(String? label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        // big tap target
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black54),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
          ),
          child: const Icon(Icons.place, size: 24, color: Colors.redAccent),
        ),
      ],
    );
  }

  Widget _hudBtn(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
      ),
    );
  }
}

/* ---------- helpers ---------- */

class _NetImage {
  final String id;
  final String url;
  _NetImage({required this.id, required this.url});
}

class _HS {
  final double longitude; // radians
  final double latitude; // radians
  final int targetIndex;
  final String? label;

  _HS({
    required this.longitude,
    required this.latitude,
    required this.targetIndex,
    this.label,
  });
}
