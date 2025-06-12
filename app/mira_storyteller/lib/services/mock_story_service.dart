import 'dart:async';
import 'dart:math';

import '../models/story.dart';

/// A mock implementation of the future AI story service
/// This class provides mock data and simulates network delays
/// to help with UI development before backend integration
class MockStoryService {
  // Singleton instance
  static final MockStoryService _instance = MockStoryService._internal();
  
  // Factory constructor
  factory MockStoryService() => _instance;
  
  // Private constructor
  MockStoryService._internal();
  
  // Mock data storage
  final List<Story> _stories = [];
  
  // Controllers to simulate real-time updates
  final _pendingStoriesController = StreamController<List<Story>>.broadcast();
  final _approvedStoriesController = StreamController<List<Story>>.broadcast();
  
  // Stream getters
  Stream<List<Story>> get pendingStoriesStream => _pendingStoriesController.stream;
  Stream<List<Story>> get approvedStoriesStream => _approvedStoriesController.stream;
  
  // Initialize with some mock data
  void initialize() {
    if (_stories.isEmpty) {
      _addMockStories();
    }
    _updateStreams();
  }
  
  // Get pending stories
  Future<List<Story>> getPendingStories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _stories.where((story) => story.status == StoryStatus.pending).toList();
  }
  
  // Get approved stories
  Future<List<Story>> getApprovedStories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _stories.where((story) => story.status == StoryStatus.approved).toList();
  }
  
  // Generate a new story from an image
  Future<Story> generateStoryFromImage(String childName, {String? imageUrl}) async {
    // Simulate AI processing time
    await Future.delayed(const Duration(seconds: 3));
    
    // Create a new story with random content
    final newStory = Story(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      title: _generateRandomTitle(),
      content: _generateRandomContent(),
      imageUrl: imageUrl ?? 'https://source.unsplash.com/random/300x200/?${_getRandomImageTopic()}',
      createdAt: DateTime.now(),
      childName: childName,
      status: StoryStatus.pending,
    );
    
    // Add to our mock database
    _stories.add(newStory);
    _updateStreams();
    
    return newStory;
  }
  
  // Approve a story
  Future<void> approveStory(String storyId, {String? feedback}) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Find and update the story
    final storyIndex = _stories.indexWhere((story) => story.id == storyId);
    if (storyIndex != -1) {
      _stories[storyIndex] = _stories[storyIndex].copyWith(status: StoryStatus.approved);
      _updateStreams();
    }
  }
  
  // Reject a story
  Future<void> rejectStory(String storyId, {String? feedback}) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Find and update the story
    final storyIndex = _stories.indexWhere((story) => story.id == storyId);
    if (storyIndex != -1) {
      _stories[storyIndex] = _stories[storyIndex].copyWith(status: StoryStatus.rejected);
      _updateStreams();
    }
  }
  
  // Generate audio for a story
  Future<String> generateAudioForStory(String storyId) async {
    // Simulate audio generation
    await Future.delayed(const Duration(seconds: 2));
    
    // Return a mock audio URL (would be a real URL in production)
    return 'https://example.com/audio/$storyId.mp3';
  }
  
  // Clear all stories (for testing)
  Future<void> clearAllStories() async {
    _stories.clear();
    _updateStreams();
  }
  
  // Add some predefined stories
  void _addMockStories() {
    // Approved stories
    _stories.addAll([
      Story(
        id: 'story_001',
        title: 'Froggy\'s Adventure',
        content: 'Froggy was a tiny green frog. He lived on a big lily pad in a quiet pond. One day, Froggy decided to explore beyond his lily pad. He hopped to a nearby rock, then to the shore. Along the way, Froggy met a friendly butterfly who showed him beautiful flowers at the pond\'s edge. Froggy had never seen such colorful plants before! When the sun began to set, Froggy hopped all the way back to his lily pad. He was happy to be home, but excited for more adventures tomorrow.',
        imageUrl: 'https://source.unsplash.com/random/300x200/?frog',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        childName: 'Lea',
        status: StoryStatus.approved,
      ),
      Story(
        id: 'story_002',
        title: 'Luna\'s Magical Night',
        content: 'Luna the cat liked to watch the moon. Every night, she would sit by the window and stare at the bright, round moon in the sky. One night, Luna saw something strange – the moon was glowing even brighter than usual! Suddenly, Luna felt herself floating up, up, up toward the ceiling. She was flying! Luna flew out the window and up toward the moon. When she reached it, she found it was made of soft, white cheese. Luna took a small bite, purred with delight, and then flew back home to tell her friends about her amazing adventure.',
        imageUrl: 'https://source.unsplash.com/random/300x200/?cat,moon',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        childName: 'Lea',
        status: StoryStatus.approved,
      ),
    ]);
    
    // Pending stories
    _stories.addAll([
      Story(
        id: 'story_003',
        title: 'Robot\'s First Day',
        content: 'Beep was a small robot who lived in a toy shop. He had never been outside before. One day, a little girl named Maya bought him and took him home. Beep was nervous about leaving the toy shop, but also excited for his new adventure. At Maya\'s house, Beep met other toys – a teddy bear, a toy car, and a doll. They all welcomed him warmly. That night, when Maya went to sleep, the toys showed Beep around the house. They played games, told stories, and had a wonderful time. Beep was happy in his new home with his new friends.',
        imageUrl: 'https://source.unsplash.com/random/300x200/?robot,toy',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        childName: 'Lea',
        status: StoryStatus.pending,
      ),
    ]);
  }
  
  // Update the stream controllers with fresh data
  void _updateStreams() {
    final pendingStories = _stories.where((story) => story.status == StoryStatus.pending).toList();
    final approvedStories = _stories.where((story) => story.status == StoryStatus.approved).toList();
    
    _pendingStoriesController.add(pendingStories);
    _approvedStoriesController.add(approvedStories);
  }
  
  // Generate a random story title
  String _generateRandomTitle() {
    final adjectives = ['Amazing', 'Magical', 'Wonderful', 'Exciting', 'Funny', 'Mysterious'];
    final nouns = ['Adventure', 'Journey', 'Discovery', 'Day', 'Dream', 'Secret'];
    final characters = ['Dragon', 'Princess', 'Robot', 'Astronaut', 'Wizard', 'Bunny', 'Puppy'];
    
    final random = Random();
    final useCharacter = random.nextBool();
    
    if (useCharacter) {
      final character = characters[random.nextInt(characters.length)];
      final noun = nouns[random.nextInt(nouns.length)];
      return 'The $character\'s $noun';
    } else {
      final adjective = adjectives[random.nextInt(adjectives.length)];
      final noun = nouns[random.nextInt(nouns.length)];
      return 'The $adjective $noun';
    }
  }
  
  // Generate random story content
  String _generateRandomContent() {
    final storyParts = [
      'Once upon a time, in a place not so far away, there was a curious little character who loved to explore.',
      'Every day, they would venture out into the world, looking for new friends and exciting discoveries.',
      'One particular morning, something unusual happened. They found a mysterious object that sparkled in the sunlight.',
      'What could it be? They carefully picked it up and examined it from all sides.',
      'Just then, a friendly animal appeared and explained that the object was magical!',
      'Together, they discovered that the object could grant one small wish each day.',
      'They decided to use their first wish to help others in their community.',
      'Everyone was so grateful, and they all celebrated with a big party.',
      'From that day on, our character learned that the greatest joy comes from sharing and helping others.',
      'The end... until the next adventure!',
    ];
    
    return storyParts.join(' ');
  }
  
  // Get a random image topic for placeholder images
  String _getRandomImageTopic() {
    final topics = ['fairy tale', 'children book', 'cartoon', 'fantasy', 'adventure', 'animal'];
    return topics[Random().nextInt(topics.length)];
  }
  
  // Close streams on app termination
  void dispose() {
    _pendingStoriesController.close();
    _approvedStoriesController.close();
  }
}
