import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toefl/remote/local/shared_pref/localization_shared_pref.dart';
import 'package:toefl/routes/navigator_key.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/routes/route_observer.dart';
import 'package:toefl/routes/routes.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:toefl/utils/locale.dart';

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Flutter Demo',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//         ),
//         home: const HangmanGame());
//   }
// }
  
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  requestNotificationPermission();
  await EasyLocalization.ensureInitialized();

  final selectedLocale = await LocalizationSharedPreference().getSelectedLang();

  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale(LocaleEnum.id.name),
        Locale(LocaleEnum.en.name),
      ],
      path: 'assets/translation',
      fallbackLocale: Locale(LocaleEnum.id.name),
      startLocale: selectedLocale != null
          ? Locale(selectedLocale)
          : Locale(LocaleEnum.en.name),
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

void requestNotificationPermission() async {
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: Locale(Platform.localeName),
      title: 'Pentol',
      theme: ThemeData(
        primaryColor: HexColor(mariner700),
        secondaryHeaderColor: HexColor(mariner100),
        fontFamily: GoogleFonts.nunito().fontFamily,
        colorScheme: Theme.of(context)
            .colorScheme
            .copyWith(outline: HexColor(mariner800)),
      ),
      initialRoute: RouteKey.root,
      routes: routes,
      navigatorKey: navigatorKey,
      navigatorObservers: [
        NavigatorHistory(),
      ],
    );
  }
}