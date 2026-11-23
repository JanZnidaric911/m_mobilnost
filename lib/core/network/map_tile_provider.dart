// Exposes an overridable flutter_map TileProvider for offline/test tile rendering.

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides an optional custom [TileProvider] (null uses flutter_map default).
final mapTileProviderProvider = Provider<TileProvider?>((ref) => null);
