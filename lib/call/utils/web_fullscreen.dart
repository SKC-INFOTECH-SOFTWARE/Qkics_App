// Conditional export: dart.library.html is only available on the web target.
// On mobile/desktop the stub is used; on web the real implementation is used.
export 'web_fullscreen_stub.dart'
    if (dart.library.html) 'web_fullscreen_impl.dart';
