import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/providers/bank_provider.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/invoice_number_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/providers/saved_client_provider.dart';
import 'package:invoicemaker/providers/service_provider.dart';
import 'package:invoicemaker/providers/tax_provider.dart';
import 'package:invoicemaker/providers/terms_provider.dart';
import 'package:invoicemaker/providers/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const int _version = 1;

  // Every SharedPreferences key the app owns, grouped by type.
  static const _listKeys = [
    'invoices',
    'saved_clients',
    'bank_accounts',
    'services',
  ];
  static const _strKeys = [
    'businesses', // handled separately (logo paths are rewritten)
    'active_business_id',
    'terms_conditions',
    'selected_currency',
    'tax_default_label',
    'inv_num_prefix',
    'app_locale',
  ];
  static const _doubleKeys = ['tax_default_rate'];
  static const _boolKeys = ['inv_num_year', 'app_dark_mode'];
  static const _intKeys = ['inv_num_pad'];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Gathers all app data, writes it to a timestamped .json file, and opens
  /// the system share sheet so the user can save it anywhere (Drive, email…).
  static Future<void> exportBackup(BuildContext context) async {
    _showLoading(context, context.tr('exporting'));
    try {
      final payload = await _gather();
      final json = const JsonEncoder.withIndent('  ').convert(payload);

      final now = DateTime.now();
      final name =
          'invoicemaker_backup_${now.year}${_p(now.month)}${_p(now.day)}'
          '_${_p(now.hour)}${_p(now.minute)}.json';

      final XFile shareFile;
      if (kIsWeb) {
        // No filesystem on web — share straight from bytes.
        shareFile = XFile.fromData(
          utf8.encode(json),
          mimeType: 'application/json',
          name: name,
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$name');
        await file.writeAsBytes(utf8.encode(json), flush: true);
        shareFile = XFile(file.path, mimeType: 'application/json');
      }

      if (!context.mounted) return;
      Navigator.pop(context); // close loading dialog

      await SharePlus.instance.share(
        ShareParams(files: [shareFile], subject: 'Invoice Maker Backup'),
      );
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context);
        _showAlert(context, context.tr('backup_export_fail'), isError: true);
      }
    }
  }

  /// Lets the user pick a .json backup file, confirms the overwrite, restores
  /// all data, and reloads every provider so the UI reflects the change.
  static Future<void> importBackup(BuildContext context) async {
    // 1. File picker
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );
    } catch (_) {
      if (context.mounted) {
        _showAlert(context, context.tr('restore_invalid'), isError: true);
      }
      return;
    }

    if (picked == null || picked.files.isEmpty) return;
    // Read from bytes rather than a file path — web never exposes a real
    // filesystem path, only in-memory bytes.
    final bytes = picked.files.first.bytes;
    if (bytes == null) {
      if (context.mounted) {
        _showAlert(context, context.tr('restore_invalid'), isError: true);
      }
      return;
    }

    // 2. Parse
    Map<String, dynamic> data;
    try {
      final content = utf8.decode(bytes);
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        if (context.mounted) {
          _showAlert(context, context.tr('restore_not_backup'), isError: true);
        }
        return;
      }
      data = decoded;
    } catch (_) {
      if (context.mounted) {
        _showAlert(context, context.tr('restore_invalid'), isError: true);
      }
      return;
    }

    if (!_isValidBackup(data)) {
      if (context.mounted) {
        _showAlert(context, context.tr('restore_not_backup'), isError: true);
      }
      return;
    }

    // 3. Confirm overwrite
    if (!context.mounted) return;
    final confirmed = await _confirmRestore(context);
    if (!confirmed || !context.mounted) return;

    // 4. Write to prefs + restore logo files
    _showLoading(context, context.tr('restoring'));
    try {
      await _restore(data);
      if (!context.mounted) return;
      await _reloadProviders(context);
      if (!context.mounted) return;
      Navigator.pop(context); // close loading dialog
      _showAlert(context, context.tr('restore_success'));
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context);
        _showAlert(context, context.tr('restore_invalid'), isError: true);
      }
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  static bool _isValidBackup(Map<String, dynamic> data) {
    if (data['version'] is! int) return false;
    if (data['created_at'] is! String) return false;
    const knownKeys = [
      ..._listKeys,
      ..._strKeys,
      ..._doubleKeys,
      ..._boolKeys,
      ..._intKeys,
    ];
    return knownKeys.any((k) => data.containsKey(k));
  }

  // ── Data gathering ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _gather() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, dynamic>{
      'version': _version,
      'created_at': DateTime.now().toIso8601String(),
    };

    for (final k in _listKeys) {
      out[k] = prefs.getStringList(k) ?? [];
    }
    for (final k in _strKeys) {
      final v = prefs.getString(k);
      if (v != null) out[k] = v;
    }
    for (final k in _doubleKeys) {
      final v = prefs.getDouble(k);
      if (v != null) out[k] = v;
    }
    for (final k in _boolKeys) {
      final v = prefs.getBool(k);
      if (v != null) out[k] = v;
    }
    for (final k in _intKeys) {
      final v = prefs.getInt(k);
      if (v != null) out[k] = v;
    }

    // Encode each business logo as base64 so the backup is a single portable file.
    out['business_logos'] = await _gatherLogos(prefs);

    return out;
  }

  static Future<Map<String, String>> _gatherLogos(
    SharedPreferences prefs,
  ) async {
    final logos = <String, String>{};
    final raw = prefs.getString('businesses');
    if (raw == null) return logos;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final b in list) {
        final id = b['id'] as String?;
        final path = b['businessLogo'] as String?;
        if (id == null || path == null) continue;
        final file = File(path);
        if (!await file.exists()) continue;
        logos[id] = base64Encode(await file.readAsBytes());
      }
    } catch (_) {}
    return logos;
  }

  // ── Data restoration ──────────────────────────────────────────────────────

  static Future<void> _restore(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final logos = (data['business_logos'] as Map<String, dynamic>?) ?? {};

    // Web has no filesystem to write logo images back to, so restored
    // businesses come back without a logo there — everything else (clients,
    // invoices, settings) still restores normally.
    Directory? docsDir;
    if (!kIsWeb) {
      docsDir = await getApplicationDocumentsDirectory();
      for (final entry in logos.entries) {
        final bid = entry.key;
        final b64 = entry.value as String? ?? '';
        if (b64.isEmpty) continue;
        final logoDir = Directory('${docsDir.path}/invoicemaker/$bid');
        if (!await logoDir.exists()) await logoDir.create(recursive: true);
        await File('${logoDir.path}/logo.jpg').writeAsBytes(base64Decode(b64));
      }
    }

    // Rewrite businesses JSON with paths valid on *this* device (the absolute
    // path prefix differs between devices, so we rebuild it from docsDir).
    final businessesRaw = data['businesses'] as String?;
    if (businessesRaw != null) {
      try {
        final list = jsonDecode(businessesRaw) as List<dynamic>;
        for (final b in list) {
          final bid = b['id'] as String?;
          if (bid == null) continue;
          b['businessLogo'] =
              (docsDir != null && logos.containsKey(bid))
                  ? '${docsDir.path}/invoicemaker/$bid/logo.jpg'
                  : null;
        }
        await prefs.setString('businesses', jsonEncode(list));
      } catch (_) {
        // If JSON manipulation fails, store the raw string; paths may be wrong
        // but it is better than losing all business metadata.
        await prefs.setString('businesses', businessesRaw);
      }
    }

    // String lists
    for (final k in _listKeys) {
      final v = data[k];
      if (v is List) await prefs.setStringList(k, List<String>.from(v));
    }

    // Strings — skip 'businesses', already saved above.
    for (final k in _strKeys) {
      if (k == 'businesses') continue;
      final v = data[k] as String?;
      if (v != null) await prefs.setString(k, v);
    }

    for (final k in _doubleKeys) {
      final v = data[k];
      if (v is num) await prefs.setDouble(k, v.toDouble());
    }
    for (final k in _boolKeys) {
      final v = data[k];
      if (v is bool) await prefs.setBool(k, v);
    }
    for (final k in _intKeys) {
      final v = data[k];
      if (v is num) await prefs.setInt(k, v.toInt());
    }
  }

  // ── Provider reload ───────────────────────────────────────────────────────

  static Future<void> _reloadProviders(BuildContext context) async {
    // Capture every provider reference synchronously before any async gap so
    // the linter (use_build_context_synchronously) is satisfied.
    final invoiceProv = Provider.of<InvoiceProvider>(context, listen: false);
    final businessProv = Provider.of<BusinessProvider>(context, listen: false);
    final clientProv = Provider.of<SavedClientProvider>(context, listen: false);
    final bankProv = Provider.of<BankProvider>(context, listen: false);
    final serviceProv = Provider.of<ServiceProvider>(context, listen: false);
    final currencyProv = Provider.of<CurrencyProvider>(context, listen: false);
    final taxProv = Provider.of<TaxProvider>(context, listen: false);
    final invNumProv = Provider.of<InvoiceNumberProvider>(
      context,
      listen: false,
    );
    final termsProv = Provider.of<TermsProvider>(context, listen: false);
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);

    await invoiceProv.loadInvoices();
    await businessProv.getSaveBusinessModel();
    await Future.wait([
      clientProv.reload(),
      bankProv.reload(),
      serviceProv.reload(),
      currencyProv.reload(),
      taxProv.reload(),
      invNumProv.reload(),
      termsProv.reload(),
      localeProv.reload(),
      themeProv.reload(),
    ]);
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  static void _showLoading(BuildContext context, String message) {
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CupertinoAlertDialog(
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(radius: 14),
                  const SizedBox(height: 14),
                  Text(message),
                ],
              ),
            ),
          ),
    );
  }

  static Future<bool> _confirmRestore(BuildContext context) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: Text(context.tr('restore_confirm_title')),
            content: Text(context.tr('restore_confirm_body')),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.tr('cancel')),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.tr('restore_btn')),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  static void _showAlert(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    showCupertinoDialog<void>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: Text(isError ? 'Error' : '✓'),
            content: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(message),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  static String _p(int n) => n.toString().padLeft(2, '0');
}
