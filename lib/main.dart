import 'package:flutter/material.dart';
import 'screens/auth.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'core/ai_config.dart';

const _appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform);
//App Check: obrigatório para o FireBase AI Logic
  // Em debug, usa o provedor de depuração; em release, os provedores reais.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider()
        : AndroidPlayIntegrityProvider(),
    providerWeb: kDebugMode
      ? WebDebugProvider(
      //Token fixo passado com --dart-define
      //Se vazio, o SDK gera um token novo e mostra no console (F12)
      debugToken: _appCheckDebugToken.isEmpty ? null : _appCheckDebugToken,
    )
        : ReCaptchaV3Provider(AiConfig.recaptchaSiteKey),
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget{
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return   MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthScreen(),
      theme: ThemeData(
        useMaterial3: true,

        // Fonte padrão
        fontFamily: 'Roboto',

        // Paleta principal
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D6B),
          brightness: Brightness.light,
          primary: const Color(0xFF2E7D6B),
          secondary: const Color(0xFF6C8C7D),
          surface: const Color(0xFFF7F9F8),
          error: const Color(0xFFBA1A1A),
        ),

        // Fundo das telas
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),

        // Barra superior
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F5D50),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
            size: 24,
          ),
        ),

        // Textos
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: Color(0xFF173E35),
          ),

          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: Color(0xFF173E35),
          ),

          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: Color(0xFF173E35),
          ),

          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF245B4F),
          ),

          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2F544C),
          ),

          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: Color(0xFF28332F),
          ),

          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: Color(0xFF48534F),
          ),

          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),

        // Campos de formulário
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF4F655E),
            fontSize: 15,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF8A9893),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFD1DDD8),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFD1DDD8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF2E7D6B),
              width: 2,
            ),
          ),
        ),

        // Botões principais
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D6B),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 14,
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // Botões com contorno
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D6B),
            minimumSize: const Size(0, 50),
            side: const BorderSide(
              color: Color(0xFF2E7D6B),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // Botões flutuantes
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2E7D6B),
          foregroundColor: Colors.white,
          elevation: 3,
        ),

        // Divisores
        dividerTheme: const DividerThemeData(
          color: Color(0xFFDCE5E1),
          thickness: 1,
          space: 24,
        ),
      ),
    );
  }
}
