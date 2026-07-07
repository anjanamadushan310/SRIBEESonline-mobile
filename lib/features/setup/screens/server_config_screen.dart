/// SRIBEESonline - Server Configuration Screen
///
/// Shown on first launch (before language selection) when no API URL has been
/// saved. Lets the user enter the backend host so the app works on a physical
/// device connected to the same Wi-Fi as the dev machine.
///
/// Flow:
///   1. User types server address, e.g.  192.168.1.100:8000
///   2. Tap "Test Connection" → app calls GET {host}/health
///   3. Tap "Save & Continue"  → URL written to SharedPreferences and
///      AppConfig updated; app navigates to LanguageSelectionScreen.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/language_provider.dart';
import '../../onboarding/screens/language_selection_screen.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _testing = false;
  bool _saving = false;
  _TestStatus _status = _TestStatus.idle;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    // Pre-fill with current URL, stripped of the /api/v1 suffix for clarity.
    final current = AppConfig.instance.apiBaseUrl;
    final clean = current.endsWith('/api/v1')
        ? current.substring(0, current.length - 7)
        : current;
    _controller.text = clean;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Normalise the user's input to a full base URL, e.g.
  ///   192.168.1.100:8000  →  http://192.168.1.100:8000
  ///   http://192.168.1.100:8000  →  http://192.168.1.100:8000   (unchanged)
  String _normalise(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), ''); // strip trailing /
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'http://$trimmed';
  }

  /// Full API base URL stored in AppConfig (adds /api/v1 suffix).
  String _apiBaseUrl(String host) => '$host/api/v1';

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _testing = true;
      _status = _TestStatus.idle;
      _statusMessage = '';
    });

    final host = _normalise(_controller.text);
    final healthUrl = '$host/health';

    try {
      final response = await Dio().get<dynamic>(
        healthUrl,
        options: Options(
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _status = _TestStatus.success;
          _statusMessage = 'Connected! Server is running.';
        });
      } else {
        setState(() {
          _status = _TestStatus.failure;
          _statusMessage = 'Server responded with ${response.statusCode}.';
        });
      }
    } on DioException catch (e) {
      String msg;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        msg = 'Timed out — is the server running and on the same network?';
      } else if (e.type == DioExceptionType.connectionError) {
        msg = 'Cannot reach $host — check the IP address and port.';
      } else {
        msg = e.message ?? 'Connection failed.';
      }
      setState(() {
        _status = _TestStatus.failure;
        _statusMessage = msg;
      });
    } catch (e) {
      setState(() {
        _status = _TestStatus.failure;
        _statusMessage = 'Unexpected error: $e';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final host = _normalise(_controller.text);
    final apiUrl = _apiBaseUrl(host);

    // Persist to SharedPreferences.
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(kCustomApiUrlKey, apiUrl);

    // Update the running AppConfig so the next ApiClient creation picks it up.
    AppConfig.updateApiUrl(apiUrl);

    if (!mounted) return;
    setState(() => _saving = false);

    pushAndClearFade(context, const LanguageSelectionScreen());
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // ── Icon + title ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.dns_rounded, size: 40, color: primary),
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Text(
                    'Server Setup',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Enter the address of your backend server.\nRequired when running on a physical device.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                // ── URL input ─────────────────────────────────────────────
                Text(
                  'Server address',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: '192.168.1.100:8000',
                    helperText:
                        'Your computer\'s local IP + port. /api/v1 is added automatically.',
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.link_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a server address.';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_status != _TestStatus.idle) {
                      setState(() => _status = _TestStatus.idle);
                    }
                  },
                ),

                const SizedBox(height: 12),

                // ── Live URL preview ──────────────────────────────────────
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (_, value, __) {
                    if (value.text.trim().isEmpty) return const SizedBox.shrink();
                    final preview = _apiBaseUrl(_normalise(value.text));
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Will use: $preview',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Status banner ─────────────────────────────────────────
                if (_status != _TestStatus.idle) ...[
                  _StatusBanner(status: _status, message: _statusMessage),
                  const SizedBox(height: 16),
                ],

                // ── Buttons ───────────────────────────────────────────────
                Row(
                  children: [
                    // Test button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testing ? null : _testConnection,
                        icon: _testing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_find_rounded),
                        label: Text(_testing ? 'Testing…' : 'Test Connection'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Save button
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                        label: Text(_saving ? 'Saving…' : 'Save & Continue'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Tips ──────────────────────────────────────────────────
                _TipsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Private widgets
// ============================================================================

enum _TestStatus { idle, success, failure }

class _StatusBanner extends StatelessWidget {
  final _TestStatus status;
  final String message;

  const _StatusBanner({required this.status, required this.message});

  @override
  Widget build(BuildContext context) {
    final isOk = status == _TestStatus.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isOk
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOk ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_outline : Icons.error_outline,
            color: isOk ? Colors.green.shade700 : Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isOk ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                'How to find your IP address',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _tip('Windows', 'Run: ipconfig  →  look for IPv4 Address'),
          _tip('Mac / Linux', 'Run: ifconfig  →  look for inet'),
          _tip('Phone & PC', 'Must be on the same Wi-Fi network'),
          _tip('Backend', 'Make sure uvicorn is running on 0.0.0.0:8000'),
        ],
      ),
    );
  }

  Widget _tip(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
