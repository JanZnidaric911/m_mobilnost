// Conditional export exposing Google Maps Directions & 3D Views safely on all platforms.

export 'google_web_views_stub.dart'
    if (dart.library.js_interop) 'google_web_views_web.dart';
