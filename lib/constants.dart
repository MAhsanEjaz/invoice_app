import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/widgets/app_tap.dart';

// ─── Mode-independent colours ─────────────────────────────────────────────────
const kPrimary = Color(0xFF0D7377);
const kPaidColor = Color(0xFF16A34A);
const kUnpaidColor = Color(0xFFD97706);
const kDangerColor = Color(0xFFDC2626);
const kQuoteColor = Color(0xFF7C3AED);
const kEstimateColor = Color(0xFF0369A1);

// Legacy aliases kept for older screens that still reference them
const appColor = Color(0xFFFFFFFF);
const buttonColor = kPrimary;
var scaffoldColor = const Color(0xFFF1F5F9);

// ─── AppColors class ──────────────────────────────────────────────────────────
class AppColors {
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color primaryLight;
  final Color paidBg;
  final Color unpaidBg;
  final Color dangerBg;
  final Color quoteBg;
  final Color estimateBg;

  const AppColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.primaryLight,
    required this.paidBg,
    required this.unpaidBg,
    required this.dangerBg,
    required this.quoteBg,
    required this.estimateBg,
  });

  static const light = AppColors(
    background: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textHint: Color(0xFF94A3B8),
    primaryLight: Color(0xFFE0F4F4),
    paidBg: Color(0xFFF0FDF4),
    unpaidBg: Color(0xFFFEF3C7),
    dangerBg: Color(0xFFFEF2F2),
    quoteBg: Color(0xFFF5F3FF),
    estimateBg: Color(0xFFE0F2FE),
  );

  static const dark = AppColors(
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    border: Color(0xFF334155),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textHint: Color(0xFF64748B),
    primaryLight: Color(0xFF0D3B3D),
    paidBg: Color(0xFF052E16),
    unpaidBg: Color(0xFF451A03),
    dangerBg: Color(0xFF450A0A),
    quoteBg: Color(0xFF2E1065),
    estimateBg: Color(0xFF0C4A6E),
  );

  static AppColors of(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? dark : light;
  }
}

// ─── BuildContext extensions ──────────────────────────────────────────────────
extension AppColorsX on BuildContext {
  AppColors get colors => AppColors.of(this);
  bool get isDarkMode => AppColors.of(this) == AppColors.dark;

  BoxDecoration get cardDecoration => BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: (isDarkMode ? Colors.black : const Color(0xFF0F172A)).withValues(
          alpha: isDarkMode ? 0.3 : 0.06,
        ),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  BoxDecoration get cardDecorationFlat => BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: colors.border, width: 1),
  );
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────
class ImagePick {
  static pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      return image.path;
    }
  }
}

Widget customHeight(BuildContext context, double height) {
  return SizedBox(height: MediaQuery.sizeOf(context).height * height);
}

responseText(BuildContext context, double size) {
  return MediaQuery.sizeOf(context).width * size;
}

/// [onTap] runs (if given) and is then followed by a pop, for screens reached
/// via push navigation. [onClose] fully replaces that pop — used when the
/// screen is instead embedded in the desktop sidebar shell, where there is no
/// route to pop and "close" should just switch back to the previous section.
Widget closeButton(
  BuildContext context, [
  Function()? onTap,
  VoidCallback? onClose,
]) {
  final cl = context.colors;
  return AppTap(
    onTap: () {
      if (onClose != null) {
        onClose();
        return;
      }
      onTap?.call();
      Navigator.of(context).pop();
    },
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: cl.primaryLight, shape: BoxShape.circle),
      child: const Icon(CupertinoIcons.xmark, color: kPrimary, size: 15),
    ),
  );
}

Widget statusBadge(BuildContext context, bool isPaid) {
  final cl = context.colors;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isPaid ? cl.paidBg : cl.unpaidBg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      isPaid ? context.tr('paid') : context.tr('unpaid'),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isPaid ? kPaidColor : kUnpaidColor,
      ),
    ),
  );
}

Widget documentBadge(BuildContext context, InvoiceModel inv) {
  final docType = inv.documentType ?? 'Invoice';
  final cl = context.colors;
  if (docType == 'Quote') {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cl.quoteBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.tr('doc_quote'),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kQuoteColor,
        ),
      ),
    );
  } else if (docType == 'Estimate') {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cl.estimateBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.tr('doc_estimate'),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kEstimateColor,
        ),
      ),
    );
  }
  // Invoice — show paid/unpaid status
  return statusBadge(context, inv.invoiceStatus == 'Paid');
}

Widget recurringBadge(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: kPrimary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(CupertinoIcons.repeat, size: 10, color: kPrimary),
        const SizedBox(width: 3),
        Text(
          context.tr('recurring'),
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
      ],
    ),
  );
}

Widget sectionLabel(BuildContext context, String label) {
  return Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: context.colors.textSecondary,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ─── Theme ────────────────────────────────────────────────────────────────────
CupertinoThemeData theme({required bool isDarkMode}) {
  final colors = isDarkMode ? AppColors.dark : AppColors.light;
  return CupertinoThemeData(
    brightness: isDarkMode ? Brightness.dark : Brightness.light,
    primaryColor: kPrimary,
    scaffoldBackgroundColor: colors.background,
    barBackgroundColor: colors.surface,
    textTheme: CupertinoTextThemeData(
      textStyle: GoogleFonts.poppins(fontSize: 15, color: colors.textPrimary),
      navLargeTitleTextStyle: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      navTitleTextStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      actionTextStyle: GoogleFonts.poppins(fontSize: 15, color: kPrimary),
    ),
  );
}

// ─── Dialogs ──────────────────────────────────────────────────────────────────
void customCupertinoDialog(BuildContext context, Function()? onTap) {
  showCupertinoDialog(
    context: context,
    builder:
        (context) => CupertinoAlertDialog(
          title: Text(
            context.tr('delete_item'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              context.tr('action_cannot_undo'),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                context.tr('cancel'),
                style: GoogleFonts.poppins(color: CupertinoColors.systemBlue),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: Text(
                context.tr('delete'),
                style: GoogleFonts.poppins(color: CupertinoColors.systemRed),
              ),
              onPressed: () {
                Navigator.pop(context);
                if (onTap != null) onTap();
              },
            ),
          ],
        ),
  );
}

Future<DateTime?> customDatePicker(
  BuildContext context, {
  bool allowFuture = false,
}) {
  final isDark = context.isDarkMode;
  return showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    lastDate:
        allowFuture
            ? DateTime.now().add(const Duration(days: 365 * 5))
            : DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: ThemeData(
          colorScheme:
              isDark
                  ? ColorScheme.dark(
                    primary: kPrimary,
                    onPrimary: Colors.white,
                    surface: AppColors.dark.surface,
                    onSurface: AppColors.dark.textPrimary,
                  )
                  : const ColorScheme.light(
                    primary: kPrimary,
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        child: child!,
      );
    },
  );
}

String customDateFormat(String? date) {
  if (date == null || date.isEmpty) return '';
  try {
    return DateFormat('MMM dd, yyyy').format(DateTime.parse(date));
  } catch (_) {
    return date;
  }
}
