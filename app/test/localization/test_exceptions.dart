/// Centralized exception management system for localization tests
/// 
/// This file contains all the patterns and rules for what strings should be
/// excluded from localization requirements. This helps maintain consistency
/// across all localization tests and makes it easy to add new exceptions.

/// Configuration for translation completeness test exceptions
class TranslationExceptions {
  /// Words that are legitimately the same across multiple languages
  /// due to Latin roots or international adoption
  static const Map<String, List<String>> internationalWords = {
    'robots': ['es', 'en'],     // "Robots" is the same in Spanish and English
    'pirates': ['fr', 'en'],    // "Pirates" is the same in French and English  
    'dragons': ['fr', 'en'],    // "Dragons" is the same in French and English
    // Add more as discovered, with proper justification
  };

  /// Language name keys that should keep their native script
  static const Set<String> languageNameKeys = {
    'english', 'russian', 'latvian', 'spanish', 'french'
  };

  /// Technical values that don't need translation
  static const Set<String> technicalValues = {
    // Database and API fields
    'prefer_not_to_say',
    'background_music_url',
    'background_music_filename', 
    'background-music',
    'created_at', 'updated_at', 'user_id', 'story_id',
    
    // CSS and styling units
    'pt', 'px', 'em', 'rem', '%',
    
    // Data formats and encodings
    'json', 'xml', 'html', 'utf-8', 'base64', 'mime_type',
    
    // Protocols
    'http', 'https', 'ftp', 'ws', 'wss',
    
    // Common technical identifiers
    'main', 'test', 'debug', 'error', 'warning', 'info',
  };

  /// Regex patterns for technical strings
  static final List<RegExp> technicalPatterns = [
    RegExp(r'^https?://'),                    // URLs
    RegExp(r'^[0-9]+$'),                     // Numbers only
    RegExp(r'^#[0-9A-Fa-f]{6}$'),           // Hex colors
    RegExp(r'^[a-zA-Z0-9._%+-]+@'),         // Emails
    RegExp(r'^/[a-zA-Z0-9/_-]*$'),          // Paths
    RegExp(r'^[A-Z_][A-Z0-9_]*$'),          // Constants
    RegExp(r'^[a-z_]+[a-z0-9_]*$'),         // Database field names (snake_case)
    RegExp(r'^[a-zA-Z0-9_-]+\.[a-z]+$'),    // Filenames with extensions
    RegExp(r'^\.[a-z0-9]+$'),               // File extensions (.jpg, .png)
    RegExp(r'^[a-z]+://'),                  // Protocol schemes
    RegExp(r'^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$'), // Domain names
  ];
}

/// Configuration for hardcoded strings test exceptions  
class HardcodedStringExceptions {
  /// Check if a string should be skipped from hardcoded string detection
  static bool shouldSkipString(String value, String context) {
    // Skip very short strings
    if (value.length < 3) return true;
    
    // Configuration and technical identifiers
    if (isConfigurationString(value, context)) return true;
    if (isDatabaseOrApiString(value, context)) return true;
    if (isAssetOrFileString(value, context)) return true;
    if (isDebugOrLogString(value, context)) return true;
    if (isPlatformOrTechnicalString(value, context)) return true;
    
    return false;
  }

  /// Firebase/Supabase configuration strings
  static bool isConfigurationString(String value, String context) {
    // Firebase/Supabase configuration patterns
    if (RegExp(r'^https?://').hasMatch(value)) return true;
    if (RegExp(r'^[a-zA-Z0-9._%+-]+@').hasMatch(value)) return true;
    if (RegExp(r'^[a-z]+://').hasMatch(value)) return true;
    if (RegExp(r'^[a-zA-Z0-9-]+\.firebaseapp\.com$').hasMatch(value)) return true;
    if (RegExp(r'^[a-zA-Z0-9-]+\.firebasestorage\.app$').hasMatch(value)) return true;
    if (RegExp(r'^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return true;
    if (RegExp(r'^[A-Za-z0-9_-]{20,}$').hasMatch(value)) return true;
    if (RegExp(r'^[0-9]+:[0-9]+:[a-zA-Z0-9:]+$').hasMatch(value)) return true;
    
    // File paths in config
    if (value.contains('firebase_options.dart') || value.contains('supabase_config.dart')) return true;
    
    return false;
  }

  /// Database field names and API parameters
  static bool isDatabaseOrApiString(String value, String context) {
    // Snake_case database fields
    if (RegExp(r'^[a-z_]+[a-z0-9_]*$').hasMatch(value) && value.contains('_')) return true;
    
    // Known database/API terms
    final dbApiTerms = {
      'background_music_url', 'background_music_filename', 'background-music',
      'prefer_not_to_say', 'created_at', 'updated_at', 'user_id', 'story_id',
      'json', 'xml', 'html', 'utf-8', 'base64', 'mime_type'
    };
    
    return dbApiTerms.contains(value.toLowerCase());
  }

  /// Asset paths, filenames, and file-related strings
  static bool isAssetOrFileString(String value, String context) {
    // Asset and file paths
    if (value.startsWith('assets/') || value.startsWith('images/') || value.startsWith('audio/')) return true;
    if (RegExp(r'^\$[a-zA-Z_][a-zA-Z0-9_]*\$').hasMatch(value)) return true;
    
    // File extensions and filenames
    if (RegExp(r'^\.[a-z0-9]+$').hasMatch(value)) return true;
    if (RegExp(r'^[a-zA-Z0-9_-]+\.[a-z]+$').hasMatch(value)) return true;
    
    // File-related context
    if (context.contains('assets') || context.contains('fileName') || context.contains('imagePath')) return true;
    
    return false;
  }

  /// Debug output, logging, and development strings
  static bool isDebugOrLogString(String value, String context) {
    // Debug and logging context
    if (context.contains('print(') || context.contains('log(') || context.contains('debug')) return true;
    if (value.startsWith('🚨') || value.startsWith('⚠️') || value.startsWith('📊') || value.startsWith('✅')) return true;
    if (value.contains('ERROR:') || value.contains('WARNING:') || value.contains('INFO:')) return true;
    
    // Debug terms
    final debugTerms = {
      'main', 'test', 'debug', 'error', 'warning', 'info', 'trace',
      'stdout', 'stderr', 'console', 'exception', 'stack trace'
    };
    
    return debugTerms.contains(value.toLowerCase());
  }

  /// Platform-specific identifiers and technical constants
  static bool isPlatformOrTechnicalString(String value, String context) {
    // Platform identifiers
    final platformTerms = {
      'ios', 'android', 'web', 'macos', 'windows', 'linux',
      'release', 'production', 'development', 'staging'
    };
    
    if (platformTerms.contains(value.toLowerCase())) return true;
    
    // Technical constants
    if (RegExp(r'^[A-Z_][A-Z0-9_]*$').hasMatch(value)) return true;
    if (RegExp(r'^[0-9]+$').hasMatch(value)) return true;
    if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) return true;
    
    // CSS/styling units
    final cssUnits = {'pt', 'px', 'em', 'rem', '%'};
    if (cssUnits.contains(value.toLowerCase())) return true;
    
    // Protocol terms
    final protocolTerms = {'http', 'https', 'ftp', 'ws', 'wss'};
    if (protocolTerms.contains(value.toLowerCase())) return true;
    
    // Code structure context
    if (context.contains('class ') || context.contains('enum ')) return true;
    if (context.contains(': $value') && RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(value)) return true;
    
    return false;
  }
}

/// Documentation for exception categories
class ExceptionDocumentation {
  static const String overview = '''
# Localization Test Exception Categories

This document explains why certain strings are excluded from localization requirements.

## Translation Completeness Exceptions

### 1. Language Names
**Rule**: Language names like "Español", "Français" remain the same across languages.
**Rationale**: These are proper nouns in their native scripts.
**Examples**: english, spanish, french, russian, latvian

### 2. International Words  
**Rule**: Some words are identical across languages due to Latin roots.
**Rationale**: These have been adopted internationally without translation.
**Examples**: "robots" (ES/EN), "pirates" (FR/EN), "dragons" (FR/EN)

### 3. Technical Strings
**Rule**: Technical identifiers, URLs, and system values don't need translation.
**Rationale**: These are not user-facing or are technical specifications.
**Examples**: URLs, email addresses, database field names, file extensions

## Hardcoded Strings Exceptions

### 1. Configuration Strings
**Categories**: Firebase config, Supabase URLs, API keys, domain names
**Rationale**: These are system configuration values, not user-facing text.
**Risk**: Low - users never see these values directly.

### 2. Database/API Strings  
**Categories**: Field names, parameter keys, technical identifiers
**Rationale**: These are backend communication protocols.
**Risk**: Low - internal system communication only.

### 3. Asset/File Strings
**Categories**: File paths, extensions, MIME types
**Rationale**: These are file system references, not UI text.
**Risk**: Low - file system operations are language-neutral.

### 4. Debug/Logging Strings
**Categories**: Console output, error messages in logs, development info
**Rationale**: These are for developers, not end users.
**Risk**: Medium - some error messages might reach users in production.

### 5. Platform/Technical Strings
**Categories**: Platform names, CSS units, protocol names, constants
**Rationale**: These are technical specifications or industry standards.
**Risk**: Low - standardized technical terminology.

## Maintenance Guidelines

1. **Conservative Approach**: When in doubt, include rather than exclude
2. **Regular Review**: Review exceptions quarterly for false negatives
3. **Documentation**: Always document why something is excluded
4. **User Impact**: Consider if users might ever see the string
5. **False Positives**: Better to have false positives than miss real issues
''';
}