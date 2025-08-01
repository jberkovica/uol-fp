/// Background music track model
class BackgroundMusicTrack {
  final String filename;
  final String displayName;
  final String url;
  final String coverImage;

  BackgroundMusicTrack({
    required this.filename,
    required this.displayName,
    required this.url,
    required this.coverImage,
  });

  /// Create BackgroundMusicTrack from JSON response
  factory BackgroundMusicTrack.fromJson(Map<String, dynamic> json) {
    return BackgroundMusicTrack(
      filename: json['filename'] as String,
      displayName: json['display_name'] as String,
      url: json['url'] as String,
      coverImage: json['cover_image'] as String,
    );
  }

  /// Convert BackgroundMusicTrack to JSON
  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'display_name': displayName,
      'url': url,
      'cover_image': coverImage,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundMusicTrack &&
          runtimeType == other.runtimeType &&
          filename == other.filename;

  @override
  int get hashCode => filename.hashCode;
}

/// Response model for background music tracks list
class BackgroundMusicResponse {
  final List<BackgroundMusicTrack> tracks;
  final int total;

  BackgroundMusicResponse({
    required this.tracks,
    required this.total,
  });

  /// Create BackgroundMusicResponse from JSON response
  factory BackgroundMusicResponse.fromJson(Map<String, dynamic> json) {
    return BackgroundMusicResponse(
      tracks: (json['tracks'] as List<dynamic>)
          .map((trackJson) => BackgroundMusicTrack.fromJson(trackJson as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}