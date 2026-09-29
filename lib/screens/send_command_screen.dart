import 'package:flutter/material.dart';
import '../services/tracking_api_service.dart';
import '../l10n/app_l10n.dart';
import '../theme/app_theme_tokens.dart';

class SendCommandScreen extends StatefulWidget {
  final String vehicleName;
  final int? deviceId;

  const SendCommandScreen({
    super.key,
    required this.vehicleName,
    this.deviceId,
  });

  @override
  State<SendCommandScreen> createState() => _SendCommandScreenState();
}

class _SendCommandScreenState extends State<SendCommandScreen> {
  final List<Map<String, dynamic>> _commandHistory = <Map<String, dynamic>>[];
  bool _isLoading = false;

  void _confirmAndSendCommand(String commandType, String actionTitle) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            actionTitle,
            style: const TextStyle(
              color: Color(0xFFFF5364),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Do you want to Stop/Resume Engine?',
            style: TextStyle(
              fontSize: 14,
              color: context.textColor,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _executeCommand(commandType, actionTitle);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeCommand(String commandType, String title) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.deviceId != null) {
        await TrackingApiService.sendCommandData(<String, dynamic>{
          'device_id': widget.deviceId,
          'type': commandType,
        });
      }
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      setState(() {
        _commandHistory.insert(0, <String, dynamic>{
          'title': title,
          'type': commandType,
          'time': timeStr,
          'status': 'Sent',
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title command sent successfully'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send $title command'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = context.textColor;
    final Color cardBg = context.containerColor;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFFFF5364),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Send Command - ${widget.vehicleName}',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Top Command Action Box ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // ─── STOP ENGINE ───
                          _buildCommandCircle(
                            label: 'STOP ENGINE',
                            ringColor: const Color(0xFFFF5252),
                            iconColor: const Color(0xFFFF5252),
                            bgColor: const Color(0xFF2B1D1D),
                            onTap: () => _confirmAndSendCommand('engineStop', 'Stop Engine'),
                          ),
                          // ─── RESUME ENGINE ───
                          _buildCommandCircle(
                            label: 'RESUME ENGINE',
                            ringColor: const Color(0xFF4CAF50),
                            iconColor: const Color(0xFF4CAF50),
                            bgColor: const Color(0xFF1C2B1F),
                            onTap: () => _confirmAndSendCommand('engineResume', 'Resume Engine'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Note: Only Emergency case.Please do no use where gsm network connectivity is poor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.mutedTextColor,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Command History Section ───
                Text(
                  context.tr('Command History'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 40),

                if (_commandHistory.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Today's Command history not availa...",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFF5364),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _commandHistory.length,
                    separatorBuilder: (BuildContext _, int index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _commandHistory[index];
                      final isStop = item['type'] == 'engineStop';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock,
                              color: isStop ? const Color(0xFFFF5252) : const Color(0xFF4CAF50),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    item['time'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.mutedTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['status'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5364)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommandCircle({
    required String label,
    required Color ringColor,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: ringColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.lock,
                size: 38,
                color: iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
