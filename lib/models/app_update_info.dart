import 'dart:convert';

class AppUpdateInfo {
  final String latestVersion;
  final int buildNumber;
  final String releaseDate;
  final String title;
  final List<String> releaseNotes;
  final String downloadUrl;
  final String? fallbackBrowserUrl;
  final int fileSizeBytes;
  final bool isMandatory;
  final String? sha256;

  const AppUpdateInfo({
    required this.latestVersion,
    this.buildNumber = 1,
    required this.releaseDate,
    required this.title,
    required this.releaseNotes,
    required this.downloadUrl,
    this.fallbackBrowserUrl,
    this.fileSizeBytes = 0,
    this.isMandatory = false,
    this.sha256,
  });

  String get formattedFileSize {
    if (fileSizeBytes <= 0) return '';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    var rawNotes = json['releaseNotes'];
    List<String> notes = [];
    if (rawNotes is List) {
      notes = rawNotes.map((e) => e.toString()).toList();
    } else if (rawNotes is String) {
      notes = rawNotes.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }

    return AppUpdateInfo(
      latestVersion: json['latestVersion']?.toString() ?? json['version']?.toString() ?? '1.0.0',
      buildNumber: json['buildNumber'] is int
          ? json['buildNumber']
          : int.tryParse(json['buildNumber']?.toString() ?? '1') ?? 1,
      releaseDate: json['releaseDate']?.toString() ?? '',
      title: json['title']?.toString() ?? 'New Version Available',
      releaseNotes: notes.isNotEmpty
          ? notes
          : [
              'UI & Performance Improvements',
              'Systematic PC Desktop multi-column layouts',
              'In-Kind offering payment status tracking',
              'Enhanced PDF exports and ledger tables',
            ],
      downloadUrl: json['downloadUrl']?.toString() ?? json['url']?.toString() ?? '',
      fallbackBrowserUrl: json['fallbackBrowserUrl']?.toString() ?? json['browserUrl']?.toString(),
      fileSizeBytes: json['fileSizeBytes'] is int
          ? json['fileSizeBytes']
          : int.tryParse(json['fileSizeBytes']?.toString() ?? '0') ?? 0,
      isMandatory: json['isMandatory'] == true,
      sha256: json['sha256']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latestVersion': latestVersion,
        'buildNumber': buildNumber,
        'releaseDate': releaseDate,
        'title': title,
        'releaseNotes': releaseNotes,
        'downloadUrl': downloadUrl,
        'fallbackBrowserUrl': fallbackBrowserUrl,
        'fileSizeBytes': fileSizeBytes,
        'isMandatory': isMandatory,
        'sha256': sha256,
      };

  static AppUpdateInfo parse(String rawJson) {
    return AppUpdateInfo.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
  }
}
