import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────
const kPrimary = Color(0xFF0D7377);
const kPrimaryLight = Color(0xFFE0F4F4);
const kBackground = Color(0xFFF1F5F9);
const kSurface = Color(0xFFFFFFFF);
const kBorder = Color(0xFFE2E8F0);
const kTextPrimary = Color(0xFF0F172A);
const kTextSecondary = Color(0xFF64748B);
const kTextHint = Color(0xFF94A3B8);
const kPaidColor = Color(0xFF16A34A);
const kPaidBg = Color(0xFFF0FDF4);
const kUnpaidColor = Color(0xFFD97706);
const kUnpaidBg = Color(0xFFFEF3C7);
const kDangerColor = Color(0xFFDC2626);
const kDangerBg = Color(0xFFFEF2F2);

// Legacy aliases used throughout the codebase
const appColor = kSurface;
const buttonColor = kPrimary;
var scaffoldColor = kBackground;

// ─── Card Decorations ─────────────────────────────────────────────────────────
BoxDecoration get kCardDecoration => BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );

BoxDecoration get kCardDecorationFlat => BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder, width: 1),
    );

// ─── Shared Widgets ──────────────────────────────────────────────────────────
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

Widget closeButton(BuildContext context, [Function()? onTap]) {
  return GestureDetector(
    onTap: () {
      onTap?.call();
      Navigator.of(context).pop();
    },
    child: Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: kPrimaryLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(CupertinoIcons.xmark, color: kPrimary, size: 15),
    ),
  );
}

Widget statusBadge(bool isPaid) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isPaid ? kPaidBg : kUnpaidBg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      isPaid ? 'Paid' : 'Unpaid',
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isPaid ? kPaidColor : kUnpaidColor,
      ),
    ),
  );
}

Widget sectionLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: kTextSecondary,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ─── Theme ────────────────────────────────────────────────────────────────────
CupertinoThemeData theme({required bool isDarkMode}) {
  return CupertinoThemeData(
    brightness: isDarkMode ? Brightness.dark : Brightness.light,
    primaryColor: kPrimary,
    scaffoldBackgroundColor: kBackground,
    barBackgroundColor: kSurface,
    textTheme: CupertinoTextThemeData(
      textStyle: GoogleFonts.poppins(
        fontSize: 15,
        color: isDarkMode ? CupertinoColors.white : kTextPrimary,
      ),
      navLargeTitleTextStyle: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: isDarkMode ? CupertinoColors.white : kTextPrimary,
      ),
      navTitleTextStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? CupertinoColors.white : kTextPrimary,
      ),
      actionTextStyle: GoogleFonts.poppins(
        fontSize: 15,
        color: kPrimary,
      ),
    ),
  );
}

// ─── Dialogs ──────────────────────────────────────────────────────────────────
void customCupertinoDialog(BuildContext context, Function()? onTap) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(
        'Delete Item',
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Text(
          'This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: CupertinoColors.systemBlue),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          child: Text(
            'Delete',
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

Future<DateTime?> customDatePicker(BuildContext context) {
  return showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    lastDate: DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: kPrimary,
            onPrimary: Colors.white,
            onSurface: kTextPrimary,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        child: child!,
      );
    },
  );
}

customDateFormat(String? date) {
  return DateFormat('MMM dd, yyyy').format(DateTime.parse(date!));
}
