import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

const appColor = Color(0xffFDFAF6);
// const buttonColor = Color(0xff201225);
const buttonColor = Color(0xff16747B);

var scaffoldColor = Colors.grey.shade200;

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
    child: Icon(CupertinoIcons.clear_circled_solid, color: buttonColor),
  );
}

CupertinoThemeData theme({required bool isDarkMode}) {
  return CupertinoThemeData(
    brightness: isDarkMode ? Brightness.dark : Brightness.light,
    primaryColor: CupertinoColors.activeBlue,
    textTheme: CupertinoTextThemeData(
      textStyle: GoogleFonts.habibi(
        fontSize: 17,
        color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
      ),
      navLargeTitleTextStyle: GoogleFonts.habibi(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
      ),
      navTitleTextStyle: GoogleFonts.habibi(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
      ),
      actionTextStyle: GoogleFonts.habibi(
        fontSize: 17,
        color: CupertinoColors.activeBlue,
      ),
    ),
  );
}

void customCupertinoDialog(BuildContext context, Function()? onTap) {
  showCupertinoDialog(
    context: context,
    builder:
        (context) => CupertinoAlertDialog(
          title: Text(
            'Are you sure?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              'Do you really want to delete this item? This action cannot be undone.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'Cancel',
                style: TextStyle(color: CupertinoColors.systemBlue),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: Text(
                'Delete',
                style: TextStyle(color: CupertinoColors.systemRed),
              ),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                if (onTap != null) onTap(); // Call the delete function
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
    firstDate: DateTime.now().subtract(Duration(days: 365 * 5)),
    // 5 years ago
    lastDate: DateTime.now(),
    // Today
    builder: (context, child) {
      return Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: buttonColor, // header background & selected date
            onPrimary: Colors.white, // text color on primary
            onSurface: Colors.black, // text color on normal days
          ),
        ),

        child: child!,
      );
    },
  );
}

customDateFormat(String? date) {
  return DateFormat('MMM,dd,yyyy').format(DateTime.parse(date!));
}
