import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/providers/client_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/items_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/providers/pdf_templates_colors_provider.dart';
import 'package:invoicemaker/providers/bank_provider.dart';
import 'package:invoicemaker/providers/saved_client_provider.dart';
import 'package:invoicemaker/providers/service_provider.dart';
import 'package:invoicemaker/providers/tax_provider.dart';
import 'package:invoicemaker/providers/invoice_number_provider.dart';
import 'package:invoicemaker/providers/terms_provider.dart';
import 'package:invoicemaker/providers/theme_provider.dart';
import 'package:invoicemaker/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local notifications and forced portrait orientation are mobile-only
  // concerns; the web build has no native notification channel and runs in
  // a resizable browser window.
  if (kIsWeb) {
    runApp(const MyApp());
    return;
  }
  await NotificationService.initialize();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => BusinessProvider()),
        ChangeNotifierProvider(create: (context) => ClientProvider()),
        ChangeNotifierProvider(create: (context) => ItemProvider()),
        ChangeNotifierProvider(create: (context) => InvoiceProvider()),
        ChangeNotifierProvider(create: (context) => TemplatesColorsProvider()),
        ChangeNotifierProvider(create: (context) => CurrencyProvider()),
        ChangeNotifierProvider(create: (context) => ServiceProvider()),
        ChangeNotifierProvider(create: (context) => SavedClientProvider()),
        ChangeNotifierProvider(create: (context) => BankProvider()),
        ChangeNotifierProvider(create: (context) => TermsProvider()),
        ChangeNotifierProvider(create: (context) => TaxProvider()),
        ChangeNotifierProvider(create: (context) => InvoiceNumberProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder:
            (context, themeProvider, localeProvider, _) => CupertinoApp(
              debugShowCheckedModeBanner: false,
              locale: localeProvider.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ur'),
                Locale('hi'),
                Locale('ar'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, myChild) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(.8)),
                  child: myChild!,
                );
              },
              theme: theme(isDarkMode: themeProvider.isDark),
              home: const SplashScreen(),
            ),
      ),
    );
  }
}
