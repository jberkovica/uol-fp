import '../repositories/story_repository.dart';
import '../repositories/kid_repository.dart';
import '../models/story.dart';
import '../models/kid.dart';
import '../services/logging_service.dart';

/// Simple data service that coordinates repositories
/// This is a lightweight coordinator, not a complex state manager
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal() : _storyRepository = StoryRepository(),
                           _kidRepository = KidRepository();
  
  /// Constructor with optional dependency injection for testing
  DataService._withRepositories({
    StoryRepository? storyRepository,
    KidRepository? kidRepository,
  }) : _storyRepository = storyRepository ?? StoryRepository(),
       _kidRepository = kidRepository ?? KidRepository();
  
  static final _logger = LoggingService.getLogger('DataService');
  
  // Repository instances - can be injected for testing
  final StoryRepository _storyRepository;
  final KidRepository _kidRepository;
  
  // Current user ID
  String? _currentUserId;
  
  /// Initialize the service with user context
  void initialize(String userId) {
    _logger.i('Initializing DataService for user: $userId');
    _currentUserId = userId;
  }
  
  /// Get current user ID
  String? get currentUserId => _currentUserId;
  
  // ===== Story Operations =====
  
  /// Get stories for a specific kid as a Future
  Future<List<Story>> getStoriesForKid(String kidId) {
    return _storyRepository.getStoriesForKid(kidId);
  }
  
  /// Get stories for a specific kid as a Stream
  /// Perfect for StreamBuilder widget
  Stream<List<Story>> getStoriesStream(String kidId) {
    return _storyRepository.getStoriesStream(kidId);
  }
  
  /// Get a single story by ID
  Future<Story> getStoryById(String storyId) {
    return _storyRepository.getStoryById(storyId);
  }
  
  /// Toggle favorite status for a story
  Future<Story> toggleStoryFavorite(String storyId, bool isFavorite) {
    return _storyRepository.toggleStoryFavorite(storyId, isFavorite);
  }
  
  // ===== Kid Operations =====
  
  /// Get all kids for the current user as a Future
  Future<List<Kid>> getKidsForCurrentUser() {
    if (_currentUserId == null) {
      _logger.e('No current user ID set');
      return Future.value([]);
    }
    return _kidRepository.getKidsForUser(_currentUserId!);
  }
  
  /// Get all kids for the current user as a Stream
  /// Perfect for StreamBuilder widget
  Stream<List<Kid>> getKidsStream() {
    if (_currentUserId == null) {
      _logger.e('No current user ID set');
      return Stream.value([]);
    }
    return _kidRepository.getKidsStream(_currentUserId!);
  }
  
  /// Create a new kid profile
  Future<Kid> createKid({
    required String name,
    required int age,
    String? gender,
    String avatarType = 'profile1',
    List<String> favoriteGenres = const [],
    String? parentNotes,
    String preferredLanguage = 'en',
  }) {
    if (_currentUserId == null) {
      throw Exception('No current user ID set');
    }
    
    return _kidRepository.createKid(
      userId: _currentUserId!,
      name: name,
      age: age,
      gender: gender,
      avatarType: avatarType,
      favoriteGenres: favoriteGenres,
      parentNotes: parentNotes,
      preferredLanguage: preferredLanguage,
    );
  }
  
  /// Update a kid profile
  Future<Kid> updateKid({
    required String kidId,
    required String name,
    required int age,
    String? gender,
    String? avatarType,
    List<String>? favoriteGenres,
    String? parentNotes,
    String? preferredLanguage,
  }) {
    return _kidRepository.updateKid(
      kidId: kidId,
      name: name,
      age: age,
      gender: gender,
      avatarType: avatarType,
      favoriteGenres: favoriteGenres,
      parentNotes: parentNotes,
      preferredLanguage: preferredLanguage,
    );
  }
  
  /// Delete a kid profile
  Future<void> deleteKid(String kidId) {
    return _kidRepository.deleteKid(kidId);
  }
  
  // ===== Cache Management =====
  
  /// Clear all cached data
  void clearAllCache() {
    _logger.i('Clearing all caches');
    StoryRepository.clearCache();
    KidRepository.clearCache();
  }
  
  /// Clear story cache for a specific kid
  void clearStoryCache(String kidId) {
    _storyRepository.clearKidCache(kidId);
  }
  
  /// Clear kid cache
  void clearKidCache() {
    KidRepository.clearCache();
  }
  
  // ===== Lifecycle Management =====
  
  /// Clean up resources when user logs out
  void dispose() {
    _logger.i('Disposing DataService resources');
    _currentUserId = null;
    clearAllCache();
  }
}

/// Global instance for easy access
/// Initialize in main.dart when user authenticates
final dataService = DataService();