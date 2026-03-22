import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class PreciosScreen extends StatefulWidget {
  const PreciosScreen({super.key});

  @override
  State<PreciosScreen> createState() => _PreciosScreenState();
}

class _PreciosScreenState extends State<PreciosScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content':
          'Hola! Soy PlaniFy Precios.\nComparo precios de Disco, Tienda Inglesa, Geant y San Roque.\n\n¿En que te puedo ayudar?',
      'type': 'text',
    },
  ];

  final List<Map<String, String>> _historial = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  static const _sugerencias = [
    '¿Donde conviene comprar leche?',
    '¿Cual es el super mas barato?',
    'Compara precio de pollo',
  ];

  static const _localButtons = [
    _LocalButton(
      label: 'Supers cercanos',
      icon: Icons.local_grocery_store,
      querySuper: 'supermercados',
      queryWaze: 'supermercado',
    ),
    _LocalButton(
      label: 'Farmacias cerca',
      icon: Icons.local_pharmacy,
      querySuper: 'farmacias',
      queryWaze: 'farmacia',
    ),
    _LocalButton(
      label: 'Todos los locales',
      icon: Icons.store,
      querySuper: 'supermercados+farmacias',
      queryWaze: 'tienda',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar([String? texto]) async {
    final query = (texto ?? _controller.text).trim();
    if (query.isEmpty || _loading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': query, 'type': 'text'});
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply =
          await ApiService().consultarPrecios(query, List.from(_historial));
      _historial.add({'role': 'user', 'content': query});
      setState(() {
        _messages.add(
            {'role': 'assistant', 'content': reply, 'type': 'text'});
        _historial.add({'role': 'assistant', 'content': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Error al conectar. Intenta de nuevo.',
          'type': 'text',
        });
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  // ---------------------------------------------------------------------------
  // Locales cercanos
  // ---------------------------------------------------------------------------
  Future<Position?> _obtenerUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Activa la ubicacion en tu dispositivo.'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permiso de ubicacion denegado.'),
              backgroundColor: AppColors.surface,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Permiso de ubicacion denegado permanentemente. Habilitalo en Configuracion.'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
        );
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Overpass API — lugar más cercano
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>?> _buscarLugarCercano(
      double lat, double lng, String tipo) async {
    final tags = {
      'supermercados': '(node["shop"="supermarket"](around:2000,$lat,$lng);'
          'way["shop"="supermarket"](around:2000,$lat,$lng);)',
      'farmacias': '(node["amenity"="pharmacy"](around:2000,$lat,$lng);'
          'way["amenity"="pharmacy"](around:2000,$lat,$lng);)',
      'supermercados+farmacias':
          '(node["shop"="supermarket"](around:2000,$lat,$lng);'
          'way["shop"="supermarket"](around:2000,$lat,$lng);'
          'node["amenity"="pharmacy"](around:2000,$lat,$lng);'
          'way["amenity"="pharmacy"](around:2000,$lat,$lng);)',
    };
    final tagQuery = tags[tipo] ?? tags['supermercados+farmacias']!;
    final query = '[out:json][timeout:15];$tagQuery;out body center 20;';

    try {
      final res = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            body: query,
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final elements = (data['elements'] as List<dynamic>?) ?? [];
      if (elements.isEmpty) return null;

      double? minDist;
      Map<String, dynamic>? nearest;
      for (final el in elements) {
        final elLat =
            (el['lat'] ?? el['center']?['lat']) as double?;
        final elLng =
            (el['lon'] ?? el['center']?['lon']) as double?;
        if (elLat == null || elLng == null) continue;
        final d = _haversine(lat, lng, elLat, elLng);
        if (minDist == null || d < minDist) {
          minDist = d;
          nearest = Map<String, dynamic>.from(el as Map);
          nearest['_dist_km'] = d;
          nearest['_lat'] = elLat;
          nearest['_lng'] = elLng;
        }
      }
      return nearest;
    } catch (_) {
      return null;
    }
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLng / 2), 2);
    return R * 2 * math.asin(math.sqrt(a));
  }

  // ---------------------------------------------------------------------------
  // OSRM — distancia y tiempo en auto
  // ---------------------------------------------------------------------------
  Future<Map<String, double>?> _osrmTiempo(
      double fromLat, double fromLng, double toLat, double toLng) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$fromLng,$fromLat;$toLng,$toLat?overview=false',
      );
      final res =
          await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;
      final route =
          (data['routes'] as List).first as Map<String, dynamic>;
      return {
        'distancia_km':
            (route['distance'] as num).toDouble() / 1000,
        'tiempo_auto_min':
            ((route['duration'] as num).toDouble() / 60)
                .ceilToDouble(),
      };
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Buscar y mostrar locales en el chat
  // ---------------------------------------------------------------------------
  Future<void> _buscarYMostrarLocales(_LocalButton btn) async {
    if (_loading) return;

    setState(() {
      _messages
          .add({'role': 'user', 'content': btn.label, 'type': 'text'});
      _messages
          .add({'role': 'assistant', 'content': '', 'type': 'loading'});
      _loading = true;
    });
    _scrollToBottom();

    final pos = await _obtenerUbicacion();
    if (pos == null) {
      setState(() {
        _messages[_messages.length - 1] = {
          'role': 'assistant',
          'content':
              'No pude obtener tu ubicacion. Habilita los permisos e intenta de nuevo.',
          'type': 'text',
        };
        _loading = false;
      });
      return;
    }

    final lat = pos.latitude;
    final lng = pos.longitude;

    final lugar =
        await _buscarLugarCercano(lat, lng, btn.querySuper);

    double distKm = 0;
    int tiempoPieMin = 0;
    int tiempoAutoMin = 0;
    String nombre = 'Sin datos';
    String direccion = '';
    double? placeLat;
    double? placeLng;

    if (lugar != null) {
      placeLat = lugar['_lat'] as double;
      placeLng = lugar['_lng'] as double;
      distKm = lugar['_dist_km'] as double;

      final tags =
          (lugar['tags'] as Map<String, dynamic>?) ?? {};
      nombre =
          (tags['name'] as String?) ?? 'Local sin nombre';
      final street = tags['addr:street'] as String? ?? '';
      final number =
          tags['addr:housenumber'] as String? ?? '';
      direccion = [street, number]
          .where((s) => s.isNotEmpty)
          .join(' ');
      if (direccion.isEmpty) direccion = 'Direccion no disponible';

      final routeInfo =
          await _osrmTiempo(lat, lng, placeLat!, placeLng!);
      if (routeInfo != null) {
        distKm = routeInfo['distancia_km']!;
        tiempoAutoMin =
            routeInfo['tiempo_auto_min']!.toInt();
      } else {
        tiempoAutoMin = (distKm / 30 * 60).ceil();
      }
      tiempoPieMin = (distKm / 5 * 60).ceil();
    }

    // Si encontramos el lugar específico, navegar directo a sus coordenadas.
    // Si no, abrir búsqueda genérica centrada en el usuario.
    final String gmapsUrl;
    final String wazeUrl;
    if (placeLat != null && placeLng != null) {
      gmapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$placeLat,$placeLng&travelmode=driving';
      wazeUrl = 'https://waze.com/ul?ll=$placeLat,$placeLng&navigate=yes';
    } else {
      gmapsUrl = 'https://www.google.com/maps/search/${btn.querySuper}/@$lat,$lng,15z';
      wazeUrl = 'https://waze.com/ul?q=${btn.queryWaze}&ll=$lat,$lng&navigate=yes';
    }

    setState(() {
      _messages[_messages.length - 1] = {
        'role': 'assistant',
        'type': 'location',
        'content': '',
        'locationData': {
          'nombre': nombre,
          'direccion': direccion,
          'distancia_km': distKm,
          'tiempo_auto_min': tiempoAutoMin,
          'tiempo_pie_min': tiempoPieMin,
          'gmaps_url': gmapsUrl,
          'waze_url': wazeUrl,
          'tiene_lugar': lugar != null,
          'tipo_label': btn.label,
        },
      };
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Precios'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.cardBorder),
        ),
      ),
      body: Column(
        children: [
          // Botones de locales cercanos
          _buildLocalButtons(),

          // Chat list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _loading) {
                  return const _TypingBubble();
                }
                final msg = _messages[index];
                final type = msg['type'] as String? ?? 'text';
                final isUser = msg['role'] == 'user';

                if (type == 'location') {
                  return _LocationCard(
                    locationData:
                        msg['locationData'] as Map<String, dynamic>,
                  );
                }

                return _ChatBubble(
                  content: msg['content'] as String? ?? '',
                  isUser: isUser,
                );
              },
            ),
          ),

          // Sugerencias (solo al inicio)
          if (_messages.length == 1)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sugerencias
                    .map(
                      (s) => GestureDetector(
                        onTap: () => _enviar(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.cardBorder),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border:
                  Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Pregunta sobre precios...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _enviar(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loading ? null : _enviar,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _loading
                          ? AppColors.accent.withOpacity(0.4)
                          : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _loading
                          ? Icons.hourglass_empty
                          : Icons.arrow_upward,
                      color: AppColors.background,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: _localButtons
            .map(
              (btn) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: btn == _localButtons.last ? 0 : 8,
                  ),
                  child: GestureDetector(
                    onTap: () => _buscarYMostrarLocales(btn),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(btn.icon,
                              color: AppColors.accent, size: 18),
                          const SizedBox(height: 4),
                          Text(
                            btn.label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// =============================================================================
// Data class para botones de locales
// =============================================================================
class _LocalButton {
  final String label;
  final IconData icon;
  final String querySuper;
  final String queryWaze;

  const _LocalButton({
    required this.label,
    required this.icon,
    required this.querySuper,
    required this.queryWaze,
  });
}

// =============================================================================
// Location Card — muestra lugar cercano + botones Maps/Waze
// =============================================================================
class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> locationData;

  const _LocationCard({required this.locationData});

  @override
  Widget build(BuildContext context) {
    final tieneLugar = locationData['tiene_lugar'] as bool? ?? false;
    final nombre = locationData['nombre'] as String? ?? '';
    final direccion = locationData['direccion'] as String? ?? '';
    final distKm =
        (locationData['distancia_km'] as num?)?.toDouble() ?? 0;
    final tiempoAuto =
        locationData['tiempo_auto_min'] as int? ?? 0;
    final tiempoPie =
        locationData['tiempo_pie_min'] as int? ?? 0;
    final gmapsUrl = locationData['gmaps_url'] as String? ?? '';
    final wazeUrl = locationData['waze_url'] as String? ?? '';
    final tipoLabel =
        locationData['tipo_label'] as String? ?? 'Locales';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: AppColors.accent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    tieneLugar
                        ? 'MAS CERCANO'
                        : tipoLabel.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            // Lugar info
            if (tieneLugar) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
                child: Text(
                  direccion,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.straighten,
                      label: '${distKm.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.directions_car,
                      label: '$tiempoAuto min',
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.directions_walk,
                      label: '$tiempoPie min',
                    ),
                  ],
                ),
              ),
            ],

            // Divider
            Container(
              margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
              height: 1,
              color: AppColors.cardBorder,
            ),

            // Botones Maps / Waze
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _MapButton(
                      icon: Icons.map,
                      label: 'Google Maps',
                      color: const Color(0xFF4285F4),
                      url: gmapsUrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MapButton(
                      icon: Icons.directions,
                      label: 'Waze',
                      color: const Color(0xFF33CCFF),
                      url: wazeUrl,
                    ),
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String url;

  const _MapButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Chat Bubble
// =============================================================================
class _ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const _ChatBubble({required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.cardBorder),
        ),
        child: isUser
            ? Text(
                content,
                style: const TextStyle(
                  color: AppColors.background,
                  fontSize: 14,
                  height: 1.45,
                ),
              )
            : MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                  strong: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  em: const TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                  tableHead: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  tableBody: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                  tableBorder: TableBorder.all(
                    color: AppColors.cardBorder,
                    width: 1,
                  ),
                  tableHeadAlign: TextAlign.left,
                  tableCellsPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  tableColumnWidth: const FlexColumnWidth(),
                  h1: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  listBullet: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  code: const TextStyle(
                    color: AppColors.accent,
                    backgroundColor: Color(0xFF1E293B),
                    fontSize: 12,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  blockquotePadding: const EdgeInsets.all(8),
                  blockquoteDecoration: BoxDecoration(
                    border: const Border(
                      left:
                          BorderSide(color: AppColors.accent, width: 3),
                    ),
                    color: AppColors.accent.withOpacity(0.05),
                  ),
                ),
                shrinkWrap: true,
              ),
      ),
    );
  }
}

// =============================================================================
// Typing Bubble
// =============================================================================
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Text(
          'Buscando lugar cercano...',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
