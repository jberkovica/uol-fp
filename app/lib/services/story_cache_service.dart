import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story.dart';
import '../services/logging_service.dart';

/// Clean, event-driven story cache service with real-time Supabase subscriptions
class StoryCacheService {
  static final _logger = LoggingService.getLogger('StoryCacheService');
  static final Map<String, List<Story>> _cache = {};
  static final Map<String, StreamSubscription> _subscriptions = {};
  static final Map<String, StreamController<List<Story>>> _controllers = {};
  static DateTime? _lastCacheUpdate;
  
  /// Get stories for a kid with real-time updates
  static Stream<List<Story>> getStoriesStream(String kidId) {
    _logger.i('Creating stories stream for kid: $kidId');
    
    // Create controller if it doesn't exist
    if (!_controllers.containsKey(kidId)) {
      _controllers[kidId] = StreamController<List<Story>>.broadcast();
      _setupRealtimeSubscription(kidId);
    }
    
    // Return cached data immediately if available
    if (_cache.containsKey(kidId)) {
      _controllers[kidId]!.add(_cache[kidId]!);
    } else {
      // Load initial data
      _loadInitialData(kidId);
    }
    
    return _controllers[kidId]!.stream;
  }
  
  /// Setup Supabase real-time subscription for a kid's stories
  static void _setupRealtimeSubscription(String kidId) {
    _logger.i('Setting up real-time subscription for kid: $kidId');
    
    try {
      final subscription = Supabase.instance.client
          .from('stories')
          .stream(primaryKey: ['id'])
          .eq('kid_id', kidId)
          .listen((data) {
            // Convert to Story objects
            final stories = data.map((item) => Story.fromJson(item)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by newest first
            
            // Update cache
            _cache[kidId] = stories;
            _lastCacheUpdate = DateTime.now();
            
            _logger.d('Real-time update: ${stories.length} stories for kid: $kidId');
            
            // Notify listeners
            if (_controllers.containsKey(kidId)) {
              _controllers[kidId]!.add(stories);
            }
          },
          onError: (error) {
            _logger.e('Real-time subscription error for kid $kidId: $error');
          });
      
      _subscriptions[kidId] = subscription;
      _logger.i('Real-time subscription active for kid: $kidId');
      
    } catch (e) {
      _logger.e('Failed to setup real-time subscription for kid $kidId: $e');
      // Fallback to polling if real-time fails
      _setupPollingFallback(kidId);
    }
  }
  
  /// Load initial data from API
  static Future<void> _loadInitialData(String kidId) async {
    try {
      final response = await Supabase.instance.client
          .from('stories')
          .select()
          .eq('kid_id', kidId)
          .order('created_at', ascending: false);
      
      final stories = (response as List)
          .map((item) => Story.fromJson(item))
          .toList();
      
      _cache[kidId] = stories;
      _lastCacheUpdate = DateTime.now();
      
      if (stories.isNotEmpty) {
        _logger.d('Loaded ${stories.length} stories for kid: $kidId');
      }
      
      // Notify listeners
      if (_controllers.containsKey(kidId)) {
        _controllers[kidId]!.add(stories);
      }
      
    } catch (e) {
      _logger.e('Failed to load initial data for kid $kidId: $e');
      
      // Notify listeners of empty state
      if (_controllers.containsKey(kidId)) {
        _controllers[kidId]!.add([]);
      }
    }
  }
  
  /// Fallback polling mechanism if real-time fails
  static void _setupPollingFallback(String kidId) {
    _logger.w('Setting up polling fallback for kid: $kidId');
    
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_controllers.containsKey(kidId)) {
        timer.cancel();
        return;
      }
      
      _loadInitialData(kidId);
    });
  }
  
  /// Get cached stories synchronously (for immediate UI updates)
  static List<Story> getCachedStories(String kidId) {
    return _cache[kidId] ?? [];
  }
  
  /// Dispose resources for a specific kid
  static void dispose(String kidId) {
    _subscriptions[kidId]?.cancel();
    _subscriptions.remove(kidId);
    
    _controllers[kidId]?.close();
    _controllers.remove(kidId);
    
    _cache.remove(kidId);
  }
  
  /// Dispose all resources
  static void disposeAll() {
    _logger.i('Disposing all story cache resources');
    
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    
    _cache.clear();
  }
  
  
  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'cached_kids': _cache.keys.length,
      'active_subscriptions': _subscriptions.keys.length,
      'active_controllers': _controllers.keys.length,
      'last_update': _lastCacheUpdate?.toIso8601String(),
      'cache_size': _cache.values.fold(0, (sum, stories) => sum + stories.length),
    };
  }
}