import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_update_info.dart';
import '../providers/update_provider.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_layout.dart';

class AppUpdateScreen extends StatefulWidget {
  final bool isModal;
  const AppUpdateScreen({super.key, this.isModal = false});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _customUrlController;
  bool _showCustomUrlInput = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final updateProv = Provider.of<UpdateProvider>(context, listen: false);
    _customUrlController = TextEditingController(text: updateProv.customDirectUrl);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto check updates if idle
    if (updateProv.checkStatus == UpdateCheckStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          updateProv.checkForUpdates();
        }
      });
    }
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updateProv = Provider.of<UpdateProvider>(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final hPadding = isDesktop ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: widget.isModal ? Colors.transparent : AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Bar
              _buildHeaderBar(context, updateProv),
              const SizedBox(height: 20),

              // 2. Status Hero Banner
              _buildStatusHeroBanner(context, updateProv),
              const SizedBox(height: 20),

              // 3. Desktop 2-Column or Mobile Stacked Content
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Release Notes & Highlights
                    Expanded(
                      flex: 5,
                      child: _buildReleaseNotesCard(updateProv.updateInfo),
                    ),
                    const SizedBox(width: 20),

                    // Right Column: Live In-App Downloader & Direct Installer Station
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _buildDownloadAndInstallStation(context, updateProv),
                          const SizedBox(height: 18),
                          _buildDirectLinkInputCard(context, updateProv),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildDownloadAndInstallStation(context, updateProv),
                    const SizedBox(height: 18),
                    _buildReleaseNotesCard(updateProv.updateInfo),
                    const SizedBox(height: 18),
                    _buildDirectLinkInputCard(context, updateProv),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, UpdateProvider updateProv) {
    return Row(
      children: [
        if (Navigator.canPop(context)) ...[
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0x1F1E293B),
              side: const BorderSide(color: AppTheme.glassBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
        ],
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.deepAccent]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'In-App Update Manager',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                'Direct In-App Download & 1-Click Installer Setup',
                style: TextStyle(fontSize: 11.5, color: Colors.white60),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: const Color(0xFF070D1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 2,
          ),
          icon: updateProv.checkStatus == UpdateCheckStatus.checking
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070D1E)),
                )
              : const Icon(Icons.refresh_rounded, size: 16),
          label: Text(
            updateProv.checkStatus == UpdateCheckStatus.checking ? 'Checking...' : 'Check Updates',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          onPressed: updateProv.checkStatus == UpdateCheckStatus.checking
              ? null
              : () => updateProv.checkForUpdates(),
        ),
      ],
    );
  }

  Widget _buildStatusHeroBanner(BuildContext context, UpdateProvider updateProv) {
    final status = updateProv.checkStatus;
    final isChecking = status == UpdateCheckStatus.checking;
    final isAvailable = status == UpdateCheckStatus.updateAvailable;
    final isUpToDate = status == UpdateCheckStatus.upToDate;

    Color themeColor = isAvailable
        ? AppTheme.goldAccent
        : (isUpToDate ? AppTheme.successGreen : AppTheme.primaryBlue);

    String headline = isChecking
        ? 'Checking for Latest Releases...'
        : (isAvailable
            ? 'New Version Update Available!'
            : (isUpToDate ? 'You Are Using the Latest Version!' : 'Update Check Status'));

    String subtitle = isChecking
        ? 'Connecting to secure update repository...'
        : (isAvailable
            ? 'A newer build (v${updateProv.updateInfo?.latestVersion ?? "2.0.0"}) is ready for direct in-app download and installation.'
            : 'Your Puja Management Terminal is fully up to date with the latest features and security fixes.');

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      border: Border.all(color: themeColor.withAlpha(90), width: 1.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Glowing Animated Badge
          ScaleTransition(
            scale: isAvailable ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: themeColor.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(color: themeColor.withAlpha(120), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withAlpha(60),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                isChecking
                    ? Icons.sync_rounded
                    : (isAvailable ? Icons.new_releases_rounded : Icons.verified_rounded),
                color: themeColor,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 18),

          // Details Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        headline,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: themeColor),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: themeColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: themeColor.withAlpha(70)),
                      ),
                      child: Text(
                        isAvailable ? 'UPDATE READY' : (isUpToDate ? 'UP TO DATE' : 'VERSION CHECK'),
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: themeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.5, color: Colors.white.withAlpha(180), height: 1.35),
                ),
                const SizedBox(height: 12),

                // Version pills
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _buildVersionPill(
                      label: 'Installed',
                      version: 'v${updateProv.currentVersion}',
                      color: Colors.white70,
                      icon: Icons.computer_rounded,
                    ),
                    if (updateProv.updateInfo != null)
                      _buildVersionPill(
                        label: 'Latest Release',
                        version: 'v${updateProv.updateInfo!.latestVersion}',
                        color: themeColor,
                        icon: Icons.cloud_download_rounded,
                      ),
                    if (updateProv.updateInfo?.releaseDate.isNotEmpty == true)
                      _buildVersionPill(
                        label: 'Release Date',
                        version: updateProv.updateInfo!.releaseDate,
                        color: Colors.white60,
                        icon: Icons.calendar_today_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionPill({
    required String label,
    required String version,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1F1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140))),
          Text(version, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildReleaseNotesCard(AppUpdateInfo? info) {
    final notes = info?.releaseNotes ?? [
      '⚡ Widescreen PC Multi-Column Desktop UI with automatic column scaling',
      '📦 In-Kind / Samagri Dan: Full Received, Promised (Due), & Partial tracking',
      '💰 Real-time financial estimation, paid amount & due balance strip',
      '🚀 In-App Downloader with direct 1-Click Windows setup installer launch',
      '📄 High-speed PDF export and multi-tab ledger audit views',
    ];

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      border: Border.all(color: AppTheme.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_list_bulleted_rounded, color: AppTheme.primaryBlue, size: 18),
              const SizedBox(width: 8),
              const Text(
                "What's New in this Release",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              if (info != null && info.fileSizeBytes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryBlue.withAlpha(60)),
                  ),
                  child: Text(
                    'Setup Size: ${info.formattedFileSize}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.glassBorder),
          const SizedBox(height: 12),
          ...notes.map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 8),
                      child: Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.successGreen),
                    ),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(fontSize: 12.5, color: Colors.white.withAlpha(200), height: 1.35),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDownloadAndInstallStation(BuildContext context, UpdateProvider updateProv) {
    final downloadStatus = updateProv.downloadStatus;
    final progress = updateProv.downloadProgress;
    final isDownloading = downloadStatus == UpdateDownloadStatus.downloading;
    final isCompleted = downloadStatus == UpdateDownloadStatus.completed;
    final isInstalling = downloadStatus == UpdateDownloadStatus.installing;
    final isFailed = downloadStatus == UpdateDownloadStatus.failed;

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      border: Border.all(
        color: isCompleted
            ? AppTheme.successGreen.withAlpha(120)
            : (isDownloading ? AppTheme.primaryBlue.withAlpha(120) : AppTheme.glassBorder),
        width: 1.4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.download_done_rounded
                    : (isDownloading ? Icons.downloading_rounded : Icons.cloud_download_rounded),
                color: isCompleted ? AppTheme.successGreen : AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Direct In-App Downloader & Installer',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Downloading Live Progress Bar
          if (isDownloading || isCompleted || isInstalling) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x1F1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isInstalling
                            ? 'Launching Windows Setup Installer...'
                            : (isCompleted ? '✓ Download Ready for Installation' : 'Downloading Update Package...'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppTheme.successGreen : Colors.white,
                        ),
                      ),
                      Text(
                        '${(progress.progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isCompleted ? AppTheme.successGreen : AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.progress > 0 ? progress.progress : null,
                      minHeight: 10,
                      backgroundColor: Colors.white.withAlpha(20),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? AppTheme.successGreen : AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${progress.formattedReceived} / ${progress.formattedTotal}',
                        style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160)),
                      ),
                      if (isDownloading)
                        Text(
                          progress.formattedSpeed,
                          style: const TextStyle(fontSize: 11, color: AppTheme.goldAccent, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 2. Error Message banner if failed
          if (isFailed && updateProv.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.dangerRose.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.dangerRose.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.dangerRose, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      updateProv.errorMessage!,
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.dangerRose),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 3. Action Buttons
          if (isCompleted) ...[
            // DIRECT 1-CLICK INSTALL BUTTON
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: const Text(
                  'Install Update Now (1-Click Setup) / सेटअप इनस्टॉल करें',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                ),
                onPressed: () => updateProv.installDownloadedUpdate(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: AppTheme.glassBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.folder_open_rounded, size: 15, color: AppTheme.goldAccent),
                    label: const Text('Open Folder in Explorer', style: TextStyle(fontSize: 11.5)),
                    onPressed: () => updateProv.openDownloadedFolder(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: AppTheme.glassBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text('Download Again', style: TextStyle(fontSize: 11.5)),
                    onPressed: () => updateProv.startDownload(),
                  ),
                ),
              ],
            ),
          ] else if (isDownloading) ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerRose,
                  side: BorderSide(color: AppTheme.dangerRose.withAlpha(90)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Cancel Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => updateProv.cancelDownload(),
              ),
            ),
          ] else ...[
            // Start Download Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: const Color(0xFF070D1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Download Update In-App',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                onPressed: () => updateProv.startDownload(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDirectLinkInputCard(BuildContext context, UpdateProvider updateProv) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      border: Border.all(color: AppTheme.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.link_rounded, color: AppTheme.goldAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Direct Download Link & Custom URL',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _showCustomUrlInput ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => setState(() => _showCustomUrlInput = !_showCustomUrlInput),
              ),
            ],
          ),
          if (_showCustomUrlInput) ...[
            const SizedBox(height: 10),
            Text(
              'Aap direct koi bhi file URL (.exe setup link ya GitHub release direct download URL) paste karke direct in-app download kar sakte hain:',
              style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(160)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: TextField(
                      controller: _customUrlController,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      onChanged: (val) => updateProv.setCustomDirectUrl(val),
                      decoration: InputDecoration(
                        hintText: 'Paste direct .exe or .apk URL (https://...)',
                        hintStyle: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(120)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        suffixIcon: _customUrlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 14, color: Colors.white60),
                                onPressed: () {
                                  _customUrlController.clear();
                                  updateProv.setCustomDirectUrl('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldAccent,
                    foregroundColor: const Color(0xFF070D1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onPressed: () {
                    if (_customUrlController.text.trim().isNotEmpty) {
                      updateProv.startDownload(overrideUrl: _customUrlController.text.trim());
                    }
                  },
                  child: const Text('Download Link', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
