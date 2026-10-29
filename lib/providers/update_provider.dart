import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_update_info.dart';
import '../services/update_service.dart';

class UpdateProvider extends ChangeNotifier {
  final UpdateService _service = UpdateService();

  String get currentVersion => UpdateService.currentAppVersion;
  int get currentBuildNumber => UpdateService.currentAppBuildNumber;

  AppUpdateInfo? _updateInfo;
  AppUpdateInfo? get updateInfo => _updateInfo;

  UpdateCheckStatus _checkStatus = UpdateCheckStatus.idle;
  UpdateCheckStatus get checkStatus => _checkStatus;

  UpdateDownloadStatus _downloadStatus = UpdateDownloadStatus.idle;
  UpdateDownloadStatus get downloadStatus => _downloadStatus;

  DownloadProgress _downloadProgress = const DownloadProgress();
  DownloadProgress get downloadProgress => _downloadProgress;

  String? _downloadedFilePath;
  String? get downloadedFilePath => _downloadedFilePath;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _customDirectUrl = '';
  String get customDirectUrl => _customDirectUrl;

  StreamSubscription<DownloadProgress>? _downloadSub;

  bool get hasUpdateAvailable =>
      _checkStatus == UpdateCheckStatus.updateAvailable && _updateInfo != null;

  bool get isMandatory => _updateInfo?.isMandatory ?? false;

  void setCustomDirectUrl(String url) {
    _customDirectUrl = url.trim();
    notifyListeners();
  }

  /// Check for application updates
  Future<void> checkForUpdates({
    bool isManual = true,
    String? customEndpoint,
  }) async {
    _checkStatus = UpdateCheckStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await _service.fetchUpdateInfo(customEndpoint: customEndpoint);
      _updateInfo = info;

      final hasNew = UpdateService.isNewerVersion(info.latestVersion, currentVersion);

      if (hasNew) {
        _checkStatus = UpdateCheckStatus.updateAvailable;
      } else {
        _checkStatus = UpdateCheckStatus.upToDate;
      }
    } catch (e) {
      _checkStatus = UpdateCheckStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Start direct in-app download
  void startDownload({String? overrideUrl}) {
    final targetUrl = overrideUrl ??
        (_customDirectUrl.isNotEmpty
            ? _customDirectUrl
            : _updateInfo?.downloadUrl ?? '');

    if (targetUrl.isEmpty) {
      // If no direct URL configured, set an error
      _downloadStatus = UpdateDownloadStatus.failed;
      _errorMessage = 'Please provide a valid direct download link for the installer (.exe / .apk)';
      notifyListeners();
      return;
    }

    _downloadStatus = UpdateDownloadStatus.downloading;
    _errorMessage = null;
    _downloadProgress = const DownloadProgress(statusText: 'Connecting to download server...');
    notifyListeners();

    final ext = targetUrl.toLowerCase().contains('.apk') ? 'apk' : 'exe';
    final targetFileName =
        'Durga_Puja_Manager_v${_updateInfo?.latestVersion ?? "2.0.0"}_Setup.$ext';

    _downloadSub?.cancel();
    _downloadSub = _service
        .downloadUpdateFile(
      downloadUrl: targetUrl,
      targetFileName: targetFileName,
      onComplete: (filePath) {
        _downloadedFilePath = filePath;
        _downloadStatus = UpdateDownloadStatus.completed;
        notifyListeners();
      },
      onError: (err) {
        _downloadStatus = UpdateDownloadStatus.failed;
        _errorMessage = err;
        notifyListeners();
      },
    )
        .listen((progress) {
      _downloadProgress = progress;
      notifyListeners();
    });
  }

  /// Cancel active in-app download
  void cancelDownload() {
    _downloadSub?.cancel();
    _downloadSub = null;
    _service.cancelDownload();
    _downloadStatus = UpdateDownloadStatus.idle;
    _downloadProgress = const DownloadProgress();
    notifyListeners();
  }

  /// 1-Click Install of the downloaded update installer
  Future<bool> installDownloadedUpdate() async {
    if (_downloadedFilePath == null) return false;

    _downloadStatus = UpdateDownloadStatus.installing;
    notifyListeners();

    final success = await _service.launchInstaller(_downloadedFilePath!);
    if (!success) {
      _errorMessage = 'Unable to launch installer. Please open folder manually.';
      _downloadStatus = UpdateDownloadStatus.completed;
      notifyListeners();
    }
    return success;
  }

  /// Open containing folder in Windows Explorer
  Future<void> openDownloadedFolder() async {
    if (_downloadedFilePath != null) {
      await _service.openContainingFolder(_downloadedFilePath!);
    }
  }

  /// Open in browser
  Future<void> openInBrowser({String? url}) async {
    final targetUrl = url ??
        _updateInfo?.fallbackBrowserUrl ??
        _updateInfo?.downloadUrl ??
        _customDirectUrl;

    if (targetUrl.isNotEmpty) {
      await _service.openInBrowser(targetUrl);
    }
  }

  /// Reset update states
  void reset() {
    _downloadSub?.cancel();
    _downloadSub = null;
    _checkStatus = UpdateCheckStatus.idle;
    _downloadStatus = UpdateDownloadStatus.idle;
    _downloadProgress = const DownloadProgress();
    _downloadedFilePath = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }
}
