// Platform-specific ad service implementation
// This file exports the correct implementation based on the target platform

export 'ad_service_stub.dart'
    if (dart.library.io) 'ad_service_native.dart';
