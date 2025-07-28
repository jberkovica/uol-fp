import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Constants for kid profile features like colors and genres
class KidProfileConstants {
  // Hair Colors - child-friendly palette
  static const Map<String, Color> hairColors = {
    'brown': Color(0xFF8B4513),
    'blonde': Color(0xFFFFDB58),
    'black': Color(0xFF2F2F2F),
    'red': Color(0xFFDC143C),
    'auburn': Color(0xFFA0522D),
    'grey': Color(0xFF808080),
    'white': Color(0xFFF5F5F5),
    'blue': Color(0xFF4169E1),
    'pink': Color(0xFFFF69B4),
    'purple': Color(0xFF9370DB),
    'green': Color(0xFF32CD32),
  };

  // Skin Colors - inclusive and respectful palette
  static const Map<String, Color> skinColors = {
    'light': Color(0xFFFBE7D1),
    'medium': Color(0xFFE8B894),
    'tan': Color(0xFFD2A679),
    'olive': Color(0xFFC4A47C),
    'brown': Color(0xFFA0714B),
    'dark': Color(0xFF7B4E3A),
    'deep': Color(0xFF5D3A29),
  };

  // Eye Colors - natural and fantasy options
  static const Map<String, Color> eyeColors = {
    'brown': Color(0xFF654321),
    'blue': Color(0xFF4169E1),
    'green': Color(0xFF228B22),
    'hazel': Color(0xFF8E7618),
    'grey': Color(0xFF708090),
    'amber': Color(0xFFFFBF00),
    'violet': Color(0xFF8A2BE2),
    'emerald': Color(0xFF50C878),
  };

  // Hair Length options
  static const List<String> hairLengths = [
    'very_short',
    'short',
    'medium',
    'long',
    'very_long',
  ];

  // Gender options (inclusive)
  static const List<String> genderOptions = [
    'girl',
    'boy',
    'non_binary',
    'prefer_not_to_say',
  ];

  // Story Genres - age-appropriate categories
  static const List<String> storyGenres = [
    'adventure',
    'fantasy',
    'friendship',
    'family',
    'animals',
    'magic',
    'space',
    'underwater',
    'forest',
    'fairy_tale',
    'superhero',
    'dinosaurs',
    'pirates',
    'princess',
    'dragons',
    'robots',
    'mystery',
    'funny',
    'educational',
    'bedtime',
  ];

  // Get localized genre names (placeholder - will be implemented with proper localization)
  static String getGenreDisplayName(String genre) {
    switch (genre) {
      case 'adventure':
        return 'Adventure';
      case 'fantasy':
        return 'Fantasy';
      case 'friendship':
        return 'Friendship';
      case 'family':
        return 'Family';
      case 'animals':
        return 'Animals';
      case 'magic':
        return 'Magic';
      case 'space':
        return 'Space';
      case 'underwater':
        return 'Underwater';
      case 'forest':
        return 'Forest';
      case 'fairy_tale':
        return 'Fairy Tale';
      case 'superhero':
        return 'Superhero';
      case 'dinosaurs':
        return 'Dinosaurs';
      case 'pirates':
        return 'Pirates';
      case 'princess':
        return 'Princess';
      case 'dragons':
        return 'Dragons';
      case 'robots':
        return 'Robots';
      case 'mystery':
        return 'Mystery';
      case 'funny':
        return 'Funny';
      case 'educational':
        return 'Educational';
      case 'bedtime':
        return 'Bedtime Stories';
      default:
        return genre;
    }
  }

  // Get hair length display name
  static String getHairLengthDisplayName(String hairLength) {
    switch (hairLength) {
      case 'very_short':
        return 'Very Short';
      case 'short':
        return 'Short';
      case 'medium':
        return 'Medium';
      case 'long':
        return 'Long';
      case 'very_long':
        return 'Very Long';
      default:
        return hairLength;
    }
  }

  // Get gender display name
  static String getGenderDisplayName(String gender) {
    switch (gender) {
      case 'girl':
        return 'Girl';
      case 'boy':
        return 'Boy';
      case 'non_binary':
        return 'Non-binary';
      case 'prefer_not_to_say':
        return 'Prefer not to say';
      default:
        return gender;
    }
  }

  // Get color name display
  static String getColorDisplayName(String colorKey, String type) {
    switch (type) {
      case 'hair':
        switch (colorKey) {
          case 'brown': return 'Brown';
          case 'blonde': return 'Blonde';
          case 'black': return 'Black';
          case 'red': return 'Red';
          case 'auburn': return 'Auburn';
          case 'grey': return 'Grey';
          case 'white': return 'White';
          case 'blue': return 'Blue';
          case 'pink': return 'Pink';
          case 'purple': return 'Purple';
          case 'green': return 'Green';
          default: return colorKey;
        }
      case 'skin':
        switch (colorKey) {
          case 'light': return 'Light';
          case 'medium': return 'Medium';
          case 'tan': return 'Tan';
          case 'olive': return 'Olive';
          case 'brown': return 'Brown';
          case 'dark': return 'Dark';
          case 'deep': return 'Deep';
          default: return colorKey;
        }
      case 'eye':
        switch (colorKey) {
          case 'brown': return 'Brown';
          case 'blue': return 'Blue';
          case 'green': return 'Green';
          case 'hazel': return 'Hazel';
          case 'grey': return 'Grey';
          case 'amber': return 'Amber';
          case 'violet': return 'Violet';
          case 'emerald': return 'Emerald';
          default: return colorKey;
        }
      default:
        return colorKey;
    }
  }
}