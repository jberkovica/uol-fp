import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Test to ensure all ARB files have the same keys and complete translations
void main() {
  group('Translation Completeness Tests', () {
    late Map<String, dynamic> enTranslations;
    late Map<String, dynamic> lvTranslations;
    late Map<String, dynamic> ruTranslations;
    late Map<String, dynamic> esTranslations;
    late Map<String, dynamic> frTranslations;
    
    setUpAll(() async {
      // Load all ARB files
      final enFile = File('lib/l10n/app_en.arb');
      final lvFile = File('lib/l10n/app_lv.arb');
      final ruFile = File('lib/l10n/app_ru.arb');
      final esFile = File('lib/l10n/app_es.arb');
      final frFile = File('lib/l10n/app_fr.arb');
      
      expect(enFile.existsSync(), isTrue, reason: 'English ARB file must exist');
      expect(lvFile.existsSync(), isTrue, reason: 'Latvian ARB file must exist');
      expect(ruFile.existsSync(), isTrue, reason: 'Russian ARB file must exist');
      expect(esFile.existsSync(), isTrue, reason: 'Spanish ARB file must exist');
      expect(frFile.existsSync(), isTrue, reason: 'French ARB file must exist');
      
      enTranslations = jsonDecode(await enFile.readAsString());
      lvTranslations = jsonDecode(await lvFile.readAsString());
      ruTranslations = jsonDecode(await ruFile.readAsString());
      esTranslations = jsonDecode(await esFile.readAsString());
      frTranslations = jsonDecode(await frFile.readAsString());
    });
    
    test('All ARB files should have same translation keys', () {
      // Filter out metadata keys (starting with @)
      final enKeys = enTranslations.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toSet();
      final lvKeys = lvTranslations.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toSet();
      final ruKeys = ruTranslations.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toSet();
      final esKeys = esTranslations.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toSet();
      final frKeys = frTranslations.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toSet();
      
      // Find missing keys for all languages
      final missingInLv = enKeys.difference(lvKeys);
      final missingInRu = enKeys.difference(ruKeys);
      final missingInEs = enKeys.difference(esKeys);
      final missingInFr = enKeys.difference(frKeys);
      
      // Report detailed results
      if (missingInLv.isNotEmpty) {
        print('⚠️  Missing keys in Latvian: ${missingInLv.join(', ')}');
      }
      if (missingInRu.isNotEmpty) {
        print('⚠️  Missing keys in Russian: ${missingInRu.join(', ')}');
      }
      if (missingInEs.isNotEmpty) {
        print('⚠️  Missing keys in Spanish: ${missingInEs.join(', ')}');
      }
      if (missingInFr.isNotEmpty) {
        print('⚠️  Missing keys in French: ${missingInFr.join(', ')}');
      }
      
      expect(missingInLv, isEmpty, reason: 'Latvian translations are missing keys');
      expect(missingInRu, isEmpty, reason: 'Russian translations are missing keys');
      expect(missingInEs, isEmpty, reason: 'Spanish translations are missing keys');
      expect(missingInFr, isEmpty, reason: 'French translations are missing keys');
      expect(enKeys, equals(lvKeys), reason: 'Latvian keys should match English keys');
      expect(enKeys, equals(ruKeys), reason: 'Russian keys should match English keys');
      expect(enKeys, equals(esKeys), reason: 'Spanish keys should match English keys');
      expect(enKeys, equals(frKeys), reason: 'French keys should match English keys');
    });
    
    test('No translation values should be empty or same as English', () {
      final failures = <String>[];
      
      for (final key in enTranslations.keys) {
        if (key.startsWith('@') || key == '@@locale') continue;
        
        final enValue = enTranslations[key] as String?;
        final lvValue = lvTranslations[key] as String?;
        final ruValue = ruTranslations[key] as String?;
        final esValue = esTranslations[key] as String?;
        final frValue = frTranslations[key] as String?;
        
        if (enValue == null || enValue.isEmpty) continue;
        
        // Check Latvian
        if (lvValue == null || lvValue.isEmpty) {
          failures.add('Latvian translation for "$key" is empty');
        } else if (lvValue == enValue && !_isTechnicalString(enValue) && !_isLanguageName(key)) {
          failures.add('Latvian translation for "$key" is same as English: "$enValue"');
        }
        
        // Check Russian
        if (ruValue == null || ruValue.isEmpty) {
          failures.add('Russian translation for "$key" is empty');
        } else if (ruValue == enValue && !_isTechnicalString(enValue) && !_isLanguageName(key)) {
          failures.add('Russian translation for "$key" is same as English: "$enValue"');
        }
        
        // Check Spanish
        if (esValue == null || esValue.isEmpty) {
          failures.add('Spanish translation for "$key" is empty');
        } else if (esValue == enValue && !_isTechnicalString(enValue) && !_isLanguageName(key) && !_isLegitimatelyIdentical(key, enValue)) {
          failures.add('Spanish translation for "$key" is same as English: "$enValue"');
        }
        
        // Check French
        if (frValue == null || frValue.isEmpty) {
          failures.add('French translation for "$key" is empty');
        } else if (frValue == enValue && !_isTechnicalString(enValue) && !_isLanguageName(key) && !_isLegitimatelyIdentical(key, enValue)) {
          failures.add('French translation for "$key" is same as English: "$enValue"');
        }
      }
      
      if (failures.isNotEmpty) {
        print('Translation Issues Found:');
        for (final failure in failures) {
          print('  - $failure');
        }
      }
      
      expect(failures, isEmpty, reason: 'Found ${failures.length} translation issues');
    });
    
    test('All locale files should have proper metadata', () {
      expect(enTranslations['@@locale'], equals('en'));
      expect(lvTranslations['@@locale'], equals('lv'));
      expect(ruTranslations['@@locale'], equals('ru'));
      expect(esTranslations['@@locale'], equals('es'));
      expect(frTranslations['@@locale'], equals('fr'));
    });
    
    test('Should generate localization coverage report', () {
      final enKeys = enTranslations.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toSet();
      final lvKeys = lvTranslations.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toSet();
      final ruKeys = ruTranslations.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toSet();
      final esKeys = esTranslations.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toSet();
      final frKeys = frTranslations.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toSet();
          
      final totalKeys = enKeys.length;
      final lvCoverage = (lvKeys.length / totalKeys * 100).toStringAsFixed(1);
      final ruCoverage = (ruKeys.length / totalKeys * 100).toStringAsFixed(1);
      final esCoverage = (esKeys.length / totalKeys * 100).toStringAsFixed(1);
      final frCoverage = (frKeys.length / totalKeys * 100).toStringAsFixed(1);
      
      print('📊 Localization Coverage Report:');
      print('   English: $totalKeys keys (baseline)');
      print('   Latvian: ${lvKeys.length} keys ($lvCoverage% coverage)');
      print('   Russian: ${ruKeys.length} keys ($ruCoverage% coverage)');
      print('   Spanish: ${esKeys.length} keys ($esCoverage% coverage)');
      print('   French: ${frKeys.length} keys ($frCoverage% coverage)');
      
      // This test always passes but generates useful info
      expect(totalKeys, greaterThan(0));
    });
  });
}

/// Check if a string is technical and doesn't need translation
bool _isTechnicalString(String value) {
  // URLs, emails, numbers, etc.
  final technicalPatterns = [
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
  
  // Common technical values that shouldn't be translated
  final technicalValues = {
    'prefer_not_to_say',
    'background_music_url',
    'background_music_filename', 
    'background-music',
    'pt', 'px', 'em', 'rem',  // CSS units
    'json', 'xml', 'html',    // Data formats
    'utf-8', 'base64',        // Encodings
    'http', 'https', 'ftp',   // Protocols
    'main', 'test', 'debug',  // Common identifiers
  };
  
  if (technicalValues.contains(value.toLowerCase())) {
    return true;
  }
  
  return technicalPatterns.any((pattern) => pattern.hasMatch(value));
}

/// Check if a value can legitimately be the same across languages due to Latin roots or international adoption
bool _isLegitimatelyIdentical(String key, String value) {
  // Words that are commonly the same across multiple languages
  final internationalWords = {
    'robots': ['es', 'en'],     // "Robots" is the same in Spanish and English
    'pirates': ['fr', 'en'],    // "Pirates" is the same in French and English  
    'dragons': ['fr', 'en'],    // "Dragons" is the same in French and English
  };
  
  // Extract the base word from genre keys
  String baseWord = key.startsWith('genre') ? key.substring(5).toLowerCase() : key.toLowerCase();
  
  return internationalWords.containsKey(baseWord) || internationalWords.containsKey(value.toLowerCase());
}

/// Check if a key is a language name that should keep native script
bool _isLanguageName(String key) {
  const languageKeys = ['english', 'russian', 'latvian', 'spanish', 'french'];
  return languageKeys.contains(key);
}