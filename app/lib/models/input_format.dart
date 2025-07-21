enum InputFormat { 
  image, 
  audio, 
  text 
}

extension InputFormatExtension on InputFormat {
  String get displayName {
    switch (this) {
      case InputFormat.image:
        return 'Image';
      case InputFormat.audio:
        return 'Audio';
      case InputFormat.text:
        return 'Text';
    }
  }
}