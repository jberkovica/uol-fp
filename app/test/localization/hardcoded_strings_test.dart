import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Test to detect hardcoded strings in the codebase that should be localized
void main() {
  group('Hardcoded Strings Detection', () {
    test('Should find hardcoded strings in widget files', () async {
      final hardcodedStrings = <String, List<String>>{};
      
      // Scan all Dart files in lib/ directory (excluding generated files)
      await _scanDirectoryForHardcodedStrings(
        Directory('lib'),
        hardcodedStrings,
      );
      
      if (hardcodedStrings.isNotEmpty) {
        print('🚨 Hardcoded strings found in ${hardcodedStrings.length} files:');
        print('');
        
        for (final entry in hardcodedStrings.entries) {
          final file = entry.key;
          final strings = entry.value;
          
          print('📁 $file:');
          for (final string in strings) {
            print('   - $string');
          }
          print('');
        }
        
        print('💡 Consider adding these strings to lib/l10n/app_en.arb and using AppLocalizations instead.');
      } else {
        print('✅ No hardcoded strings found! Great job with localization.');
      }
      
      // This test reports but doesn't fail - you can change this behavior
      // expect(hardcodedStrings, isEmpty, reason: 'Found hardcoded strings that should be localized');
    });
    
    test('Should verify AppLocalizations usage patterns', () async {
      final filesWithLocalizations = <String>[];
      final filesWithHardcodedText = <String>[];
      
      await _scanForLocalizationPatterns(
        Directory('lib/screens'),
        filesWithLocalizations,
        filesWithHardcodedText,
      );
      
      print('📊 Localization Usage Report:');
      print('   Files using AppLocalizations: ${filesWithLocalizations.length}');
      print('   Files with potential hardcoded text: ${filesWithHardcodedText.length}');
      
      if (filesWithHardcodedText.isNotEmpty) {
        print('');
        print('Files that may need localization review:');
        for (final file in filesWithHardcodedText) {
          print('   - $file');
        }
      }
      
      // This test always passes but provides useful metrics
      expect(filesWithLocalizations, isNotEmpty);
    });
  });
}

Future<void> _scanDirectoryForHardcodedStrings(
  Directory dir,
  Map<String, List<String>> hardcodedStrings,
) async {
  if (!dir.existsSync()) return;
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Skip generated files and test files
      if (entity.path.contains('generated/') ||
          entity.path.contains('l10n/') ||
          entity.path.contains('test/') ||
          entity.path.contains('.g.dart') ||
          entity.path.contains('.freezed.dart')) {
        continue;
      }
      
      await _scanFileForHardcodedStrings(entity, hardcodedStrings);
    }
  }
}

Future<void> _scanFileForHardcodedStrings(
  File file,
  Map<String, List<String>> hardcodedStrings,
) async {
  try {
    final content = await file.readAsString();
    final lines = content.split('\n');
    final relativePath = file.path.replaceAll(RegExp(r'^.*lib/'), 'lib/');
    
    final foundStrings = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lineNumber = i + 1;
      
      // Skip comments and imports
      if (line.startsWith('//') || 
          line.startsWith('import ') ||
          line.startsWith('part ') ||
          line.startsWith('*') ||
          line.contains('TODO:') ||
          line.contains('FIXME:')) {
        continue;
      }
      
      // Find string literals that might need localization
      final stringMatches = RegExp(r'''['"]([^'"]{3,})['"]''').allMatches(line);
      
      for (final match in stringMatches) {
        final stringValue = match.group(1)!;
        
        // Skip if this looks like a technical string that shouldn't be localized
        if (_shouldSkipString(stringValue, line)) {
          continue;
        }
        
        // Skip if already using localization
        if (line.contains('AppLocalizations.of(context)') ||
            line.contains('context.l10n') ||
            line.contains('.arb') ||
            line.contains('LocalizationsDelegate')) {
          continue;
        }
        
        foundStrings.add('Line $lineNumber: "$stringValue"');
      }
    }
    
    if (foundStrings.isNotEmpty) {
      hardcodedStrings[relativePath] = foundStrings;
    }
  } catch (e) {
    // Skip files that can't be read
  }
}

bool _shouldSkipString(String value, String context) {
  // Skip very short strings
  if (value.length < 3) return true;
  
  // Configuration and technical identifiers
  if (_isConfigurationString(value, context)) return true;
  if (_isDatabaseOrApiString(value, context)) return true;
  if (_isAssetOrFileString(value, context)) return true;
  if (_isDebugOrLogString(value, context)) return true;
  if (_isPlatformOrTechnicalString(value, context)) return true;
  
  return false;
}

/// Check if string is a configuration value (Firebase, Supabase, etc.)
bool _isConfigurationString(String value, String context) {
  // Firebase/Supabase configuration
  if (RegExp(r'^https?://').hasMatch(value)) return true; // URLs
  if (RegExp(r'^[a-zA-Z0-9._%+-]+@').hasMatch(value)) return true; // emails
  if (RegExp(r'^[a-z]+://').hasMatch(value)) return true; // callback schemes
  if (RegExp(r'^[a-zA-Z0-9-]+\.firebaseapp\.com$').hasMatch(value)) return true;
  if (RegExp(r'^[a-zA-Z0-9-]+\.firebasestorage\.app$').hasMatch(value)) return true;
  if (RegExp(r'^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return true; // domains
  if (RegExp(r'^[A-Za-z0-9_-]{20,}$').hasMatch(value)) return true; // API keys/tokens
  if (RegExp(r'^[0-9]+:[0-9]+:[a-zA-Z0-9:]+$').hasMatch(value)) return true; // Firebase IDs
  
  // File paths in config
  if (value.contains('firebase_options.dart') || value.contains('supabase_config.dart')) return true;
  
  return false;
}

/// Check if string is a database field or API parameter
bool _isDatabaseOrApiString(String value, String context) {
  // Database field names (snake_case)
  if (RegExp(r'^[a-z_]+[a-z0-9_]*$').hasMatch(value) && value.contains('_')) return true;
  
  // Common database/API terms
  final dbApiTerms = {
    'background_music_url', 'background_music_filename', 'background-music',
    'prefer_not_to_say', 'created_at', 'updated_at', 'user_id', 'story_id',
    'json', 'xml', 'html', 'utf-8', 'base64', 'mime_type'
  };
  
  return dbApiTerms.contains(value.toLowerCase());
}

/// Check if string is an asset path or filename
bool _isAssetOrFileString(String value, String context) {
  // Asset paths
  if (value.startsWith('assets/') || value.startsWith('images/') || value.startsWith('audio/')) return true;
  if (RegExp(r'^\$[a-zA-Z_][a-zA-Z0-9_]*\$').hasMatch(value)) return true; // template variables like $_imagePath$fileName
  
  // File extensions and MIME types
  if (RegExp(r'^\.[a-z0-9]+$').hasMatch(value)) return true; // .jpg, .png, .mp4
  if (RegExp(r'^[a-zA-Z0-9_-]+\.[a-z]+$').hasMatch(value)) return true; // filename.ext
  
  // File-related context
  if (context.contains('assets') || context.contains('fileName') || context.contains('imagePath')) return true;
  
  return false;
}

/// Check if string is debug output or logging
bool _isDebugOrLogString(String value, String context) {
  // Debug and logging patterns
  if (context.contains('print(') || context.contains('log(') || context.contains('debug')) return true;
  if (value.startsWith('🚨') || value.startsWith('⚠️') || value.startsWith('📊') || value.startsWith('✅')) return true;
  if (value.contains('ERROR:') || value.contains('WARNING:') || value.contains('INFO:')) return true;
  
  // Common debug terms
  final debugTerms = {
    'main', 'test', 'debug', 'error', 'warning', 'info', 'trace',
    'stdout', 'stderr', 'console', 'exception', 'stack trace'
  };
  
  return debugTerms.contains(value.toLowerCase());
}

/// Check if string is platform-specific or technical constant
bool _isPlatformOrTechnicalString(String value, String context) {
  // Platform identifiers
  final platformTerms = {
    'ios', 'android', 'web', 'macos', 'windows', 'linux',
    'release', 'production', 'development', 'staging'
  };
  
  if (platformTerms.contains(value.toLowerCase())) return true;
  
  // Technical constants and identifiers
  if (RegExp(r'^[A-Z_][A-Z0-9_]*$').hasMatch(value)) return true; // CONSTANTS
  if (RegExp(r'^[0-9]+$').hasMatch(value)) return true; // pure numbers
  if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) return true; // hex colors
  
  // CSS/styling units
  final cssUnits = {'pt', 'px', 'em', 'rem', '%'};
  if (cssUnits.contains(value.toLowerCase())) return true;
  
  // Protocol and encoding terms
  final protocolTerms = {'http', 'https', 'ftp', 'ws', 'wss'};
  if (protocolTerms.contains(value.toLowerCase())) return true;
  
  // Class/enum context
  if (context.contains('class ') || context.contains('enum ')) return true;
  
  // Property assignment context (key: value)
  if (context.contains(': $value') && RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(value)) return true;
  
  return false;
}

Future<void> _scanForLocalizationPatterns(
  Directory dir,
  List<String> filesWithLocalizations,
  List<String> filesWithHardcodedText,
) async {
  if (!dir.existsSync()) return;
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final content = await entity.readAsString();
        final relativePath = entity.path.replaceAll(RegExp(r'^.*lib/'), 'lib/');
        
        if (content.contains('AppLocalizations.of(context)')) {
          filesWithLocalizations.add(relativePath);
        }
        
        // Look for potential hardcoded user-facing text
        if (RegExp(r'''Text\s*\(\s*['"][^'"]{5,}['"]''').hasMatch(content) &&
            !content.contains('AppLocalizations.of(context)')) {
          filesWithHardcodedText.add(relativePath);
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }
  }
}