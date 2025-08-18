import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story.dart';
import '../constants/api_constants.dart';
import '../services/logging_service.dart';

/// Clean repository pattern for story data management
/// Follows single responsibility principle - only fetches and returns data
class StoryRepository {
  static final _logger = LoggingService.getLogger('StoryRepository');
  
  // Dependencies - can be injected for testing
  final http.Client _httpClient;
  final SupabaseClient? _supabaseClient;
  
  // Simple in-memory cache with TTL
  static final Map<String, CachedData<List<Story>>> _cache = {};
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  /// Constructor with optional dependency injection for testing
  StoryRepository({
    http.Client? httpClient,
    SupabaseClient? supabaseClient,
  }) : _httpClient = httpClient ?? http.Client(),
        _supabaseClient = supabaseClient;
  
  // Singleton stream controllers - one per kidId
  static final Map<String, StreamController<List<Story>>> _streamControllers = {};
  // Realtime subscriptions for cache invalidation - one per kidId
  static final Map<String, RealtimeChannel> _realtimeSubscriptions = {};
  // Reference counting for stream cleanup
  static final Map<String, int> _streamRefCounts = {};
  // Debounce timers to prevent excessive API calls
  static final Map<String, Timer> _debounceTimers = {};
  
  /// Fetch stories for a specific kid
  /// Returns a Future that completes with the story list
  Future<List<Story>> getStoriesForKid(String kidId) async {
    try {
      // Check cache first
      final cached = _cache[kidId];
      if (cached != null && !cached.isExpired) {
        // Return cached data silently
        return cached.data;
      }
      
      // Fetch from backend
      final url = Uri.parse('${ApiConstants.baseUrl}/stories/kid/$kidId');
      _logger.d('Fetching stories from backend: $url');
      
      final response = await _httpClient.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30)); // Increased timeout for AI processing phases
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stories = (data['stories'] as List)
            .map((item) => Story.fromJson(item))
            .toList();
        
        // Update cache
        _cache[kidId] = CachedData(stories);
        
        _logger.i('Fetched ${stories.length} stories for kid: $kidId');
        return stories;
      } else {
        _logger.e('Failed to fetch stories: ${response.statusCode}');
        throw Exception('Failed to fetch stories: ${response.statusCode}');
      }
    } catch (e) {
      // During AI processing, timeout errors are expected - log as debug instead of error
      if (e.toString().contains('TimeoutException')) {
        _logger.d('Story fetch timeout during AI processing (expected): $e');
      } else {
        _logger.e('Error fetching stories for kid $kidId: $e');
      }
      
      // Return cached data if available, even if expired
      final cached = _cache[kidId];
      if (cached != null) {
        _logger.w('Returning expired cache due to error');
        return cached.data;
      }
      
      throw e;
    }
  }
  
  /// Get a stream of stories for a kid
  /// Uses singleton pattern to avoid duplicate subscriptions
  Stream<List<Story>> getStoriesStream(String kidId) {
    // Get or create singleton stream controller for this kidId
    if (!_streamControllers.containsKey(kidId)) {
      _logger.i('Creating new stream controller for kid: $kidId');
      _streamControllers[kidId] = StreamController<List<Story>>.broadcast();
      _streamRefCounts[kidId] = 0;
      
      // Setup realtime subscription once
      _setupRealtimeSubscription(kidId);
    }
    
    // Increment reference count
    _streamRefCounts[kidId] = (_streamRefCounts[kidId] ?? 0) + 1;
    
    // Always emit fresh data when stream is accessed
    // This ensures returning to an existing kid shows current data
    _emitInitialData(kidId);
    
    final controller = _streamControllers[kidId]!;
    
    return controller.stream.handleError((error) {
      // During AI processing, timeout errors are expected - log as debug instead of error
      if (error.toString().contains('TimeoutException')) {
        _logger.d('Stream timeout during AI processing (expected): $error');
      } else {
        _logger.e('Stream error for kid $kidId: $error');
      }
    });
  }
  
  /// Emit initial data to stream
  void _emitInitialData(String kidId) async {
    try {
      final stories = await getStoriesForKid(kidId);
      final controller = _streamControllers[kidId];
      if (controller != null && !controller.isClosed) {
        controller.add(stories);
      }
    } catch (e) {
      final controller = _streamControllers[kidId];
      if (controller != null && !controller.isClosed) {
        controller.addError(e);
      }
    }
  }
  
  /// Get a single story by ID
  Future<Story> getStoryById(String storyId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/stories/$storyId');
      _logger.d('Fetching story by ID: $storyId');
      
      final response = await _httpClient.get(url).timeout(const Duration(seconds: 30)); // Increased timeout for AI processing phases
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Story.fromJson(data);
      } else {
        throw Exception('Failed to get story: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching story $storyId: $e');
      throw e;
    }
  }
  
  /// Toggle favorite status for a story
  Future<Story> toggleStoryFavorite(String storyId, bool isFavorite) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/stories/$storyId/favourite');
      _logger.d('Toggling favorite for story: $storyId to $isFavorite');
      
      final response = await _httpClient.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'is_favourite': isFavorite}),
      ).timeout(const Duration(seconds: 30)); // Increased timeout for AI processing phases
      
      if (response.statusCode == 200) {
        // Handle different response formats from backend
        if (response.body.isEmpty) {
          // Backend returns empty body, fetch fresh story data
          _logger.d('Empty response body, fetching fresh story data');
          final story = await getStoryById(storyId);
          _updateStoryInCache(story);
          return story;
        }
        
        final data = json.decode(response.body);
        Story story;
        
        // Handle both {'story': {...}} and direct story object formats
        if (data is Map<String, dynamic> && data.containsKey('story')) {
          story = Story.fromJson(data['story']);
        } else if (data is Map<String, dynamic>) {
          story = Story.fromJson(data);
        } else {
          throw Exception('Unexpected response format');
        }
        
        // Update cache if exists
        _updateStoryInCache(story);
        
        return story;
      } else {
        throw Exception('Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error toggling favorite for story $storyId: $e');
      throw e;
    }
  }
  
  /// Update a story in all cached lists
  void _updateStoryInCache(Story updatedStory) {
    for (final entry in _cache.entries) {
      final stories = entry.value.data;
      final index = stories.indexWhere((s) => s.id == updatedStory.id);
      if (index != -1) {
        stories[index] = updatedStory;
        _logger.d('Updated story ${updatedStory.id} in cache for kid ${entry.key}');
      }
    }
  }
  
  /// Setup realtime subscription for a kid's stories
  void _setupRealtimeSubscription(String kidId) {
    // Avoid duplicate subscriptions
    if (_realtimeSubscriptions.containsKey(kidId)) {
      _logger.d('Realtime subscription already exists for kid: $kidId');
      return;
    }
    
    _logger.i('Setting up realtime subscription for kid: $kidId');
    
    final supabase = _supabaseClient ?? Supabase.instance.client;
    final channel = supabase
      .channel('stories_$kidId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all, // Listen for INSERT, UPDATE, DELETE
        schema: 'public', 
        table: 'stories',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'kid_id',
          value: kidId,
        ),
        callback: (payload) async {
          _logger.i('Realtime event received for kid $kidId: ${payload.eventType}');
          
          // Clear cache to force fresh fetch when we do update
          clearKidCache(kidId);
          
          // Debounce: Cancel previous timer and start new one
          _debounceTimers[kidId]?.cancel();
          _debounceTimers[kidId] = Timer(const Duration(seconds: 2), () async {
            _logger.d('Debounced update triggered for kid: $kidId');
            
            // Emit fresh data to singleton stream
            final controller = _streamControllers[kidId];
            if (controller != null && !controller.isClosed) {
              try {
                final stories = await getStoriesForKid(kidId);
                controller.add(stories);
                _logger.i('Stream updated with ${stories.length} stories for kid: $kidId');
              } catch (e) {
                // During AI processing, timeout errors are expected - log as debug instead of error
                if (e.toString().contains('TimeoutException')) {
                  _logger.d('Realtime update timeout during AI processing (expected): $e');
                } else {
                  _logger.e('Error fetching stories after realtime update: $e');
                  controller.addError(e);
                }
              }
            } else {
              _logger.w('Stream controller not available for kid: $kidId');
            }
            
            // Clean up timer reference
            _debounceTimers.remove(kidId);
          });
        },
      )
      .subscribe();
      
    _realtimeSubscriptions[kidId] = channel;
    _logger.i('Realtime subscription active for kid: $kidId');
  }
  
  /// Release a stream reference and cleanup if no more references
  void releaseStream(String kidId) {
    final currentCount = _streamRefCounts[kidId] ?? 0;
    if (currentCount > 0) {
      _streamRefCounts[kidId] = currentCount - 1;
      
      // If no more references, cleanup
      if (_streamRefCounts[kidId] == 0) {
        _cleanupStreamAndSubscription(kidId);
      }
    }
  }
  
  /// Cleanup both stream and realtime subscription for a kid
  void _cleanupStreamAndSubscription(String kidId) {
    _logger.i('Cleaning up stream and subscription for kid: $kidId');
    
    // Cleanup debounce timer
    final timer = _debounceTimers.remove(kidId);
    if (timer != null) {
      timer.cancel();
    }
    
    // Cleanup stream controller
    final controller = _streamControllers.remove(kidId);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    
    // Cleanup realtime subscription
    final channel = _realtimeSubscriptions.remove(kidId);
    if (channel != null) {
      channel.unsubscribe();
    }
    
    // Remove ref count
    _streamRefCounts.remove(kidId);
  }
  
  /// Clear all cached data
  static void clearCache() {
    _cache.clear();
    _logger.i('Story cache cleared');
  }
  
  /// Clear cache for a specific kid
  void clearKidCache(String kidId) {
    _cache.remove(kidId);
    _logger.d('Cache cleared for kid: $kidId');
  }
  
  // ===== TEST HELPER METHODS =====
  
  /// Get reference count for testing purposes
  @visibleForTesting
  static int getStreamRefCount(String kidId) {
    return _streamRefCounts[kidId] ?? 0;
  }
  
  /// Force cache expiration for testing
  @visibleForTesting
  static void forceCacheExpiration(String kidId) {
    final cached = _cache[kidId];
    if (cached != null) {
      // Create expired cache entry
      _cache[kidId] = CachedData._withTimestamp(
        cached.data, 
        DateTime.now().subtract(const Duration(hours: 1))
      );
    }
  }
  
  /// Cleanup all resources (call when app is disposed)
  void dispose() {
    _logger.i('Disposing StoryRepository and cleaning up all resources');
    
    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    
    // Close all stream controllers
    for (final controller in _streamControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _streamControllers.clear();
    
    // Cleanup all realtime subscriptions
    for (final channel in _realtimeSubscriptions.values) {
      channel.unsubscribe();
    }
    _realtimeSubscriptions.clear();
    
    // Clear reference counts
    _streamRefCounts.clear();
  }
}

/// Simple cache wrapper with TTL
class CachedData<T> {
  final T data;
  final DateTime timestamp;
  
  CachedData(this.data) : timestamp = DateTime.now();
  
  /// Constructor for testing with custom timestamp
  CachedData._withTimestamp(this.data, this.timestamp);
  
  bool get isExpired => 
      DateTime.now().difference(timestamp) > StoryRepository._cacheTTL;
}