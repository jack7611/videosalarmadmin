import 'package:admin/controllers/User_controller.dart';
import 'package:admin/controllers/Videos_controller.dart';
import 'package:admin/controllers/admin_controller.dart';
import 'package:admin/controllers/blog_controller.dart';
import 'package:admin/controllers/creator_controller.dart';
import 'package:admin/controllers/movie_controller.dart';
import 'package:admin/controllers/movie_controller.dart';
import 'package:admin/controllers/custom_notification_controller.dart';
import 'package:admin/creators/screens/creator_dashboard_screen.dart';
import 'package:admin/screens/dashboard/components/Blog_page.dart';
import 'package:admin/screens/dashboard/components/User_page.dart';
import 'package:admin/screens/dashboard/components/Videos_page.dart';
import 'package:admin/screens/dashboard/components/Creator_page.dart';
import 'package:admin/screens/dashboard/components/addblog_Screen.dart';
import 'package:admin/screens/dashboard/components/addvideo_Screen.dart';
import 'package:admin/screens/dashboard/components/admin_ticket_page.dart';
import 'package:admin/screens/dashboard/components/advertisement.dart';
import 'package:admin/screens/dashboard/components/invoices.dart';
import 'package:admin/screens/dashboard/components/live_page.dart';
import 'package:admin/screens/dashboard/components/movies_page.dart';
import 'package:admin/screens/dashboard/components/send_noti_page.dart';
import 'package:admin/screens/dashboard/components/subscription.dart';
import 'package:admin/screens/dashboard/components/subscription_reconciliation.dart';
import 'package:admin/screens/main/components/AuthWrapper.dart';
import 'package:admin/creators/components/creator_auth_wrapper.dart';
import 'package:admin/screens/main/components/admin_page.dart';
import 'package:admin/screens/main/components/custom_notification_screen.dart';
import 'package:admin/screens/main/main_screen.dart';
import 'package:admin/screens/dashboard/components/quiz_admin_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/controllers/menu_app_controller.dart';
import 'dart:html' as html; // For accessing local storage

const FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyAZ9roj2_TjkPNKk392tjNVtOhX59UcFpg",
    authDomain: "videoalarm-a0b26.firebaseapp.com",
    projectId: "videoalarm-a0b26",
    storageBucket: "videoalarm-a0b26.appspot.com",
    messagingSenderId: "1030438775387",
    appId: "1:1030438775387:web:0e6a68512435d115066d7e");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);

  // Initialize controllers globally using Get.put()
  Get.put(AdminSignInController());
  Get.put(UserController());
  Get.put(VideosController());
  Get.put(BlogController());
  Get.put(CreatorController());
  Get.put(MenuController());
  Get.put(MovieController());
  Get.put(CustomNotificationController());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MenuAppController(),
        ),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Videos Alarm Admin',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
              .apply(bodyColor: Colors.white),
          canvasColor: secondaryColor,
        ),
        //home: AuthWrapper(),
        home: getInitialPage(),
        routes: {
          '/Dashboard': (context) => MainScreen(),
          '/Blog': (context) => BlogPage(),
          '/Users': (context) => UserPage(),
          '/Videos': (context) => VideosPage(),
          '/add': (context) => AddVideoPage(),
          '/Addblog': (context) => AddBlogPage(),
          '/subscriptions': (context) => SubscriptionPage(),
          '/live': (context) => LiveVideosPage(),
          '/ads': (context) => AdvertisementPage(),
          '/tickets': (context) => const AdminTicketPage(),
          '/reconciliation': (context) => const SubscriptionTrackerPage(),
          '/invoices': (context) => const InvoiceListPage(),
          '/noti': (context) => const NotificationPage(),
          '/creators': (context) => const CreatorPage(),
          '/Movies': (context) => const MoviesPage(),
          '/custom_notification': (context) => const CustomNotificationScreen(),
          '/quiz': (context) => const QuizAdminPage(),

          // Creator routes
          // Creator routes
          ///creator': (context) => const CreatorSignInPage(), // Covered by AuthWrapper
          '/creator/dashboard': (context) => const CreatorDashboardScreen(),
        },
        onGenerateRoute: (settings) {
          // Check if user is not signed in and is trying to access a protected route
          if (!isLoggedIn() && isProtectedRoute(settings.name)) {
            // Redirect to the sign-in page if not logged in
            return MaterialPageRoute(
                builder: (context) => const AdminSignInPage());
          }

          // Allow navigation for other routes
          return null;
        },
      ),
    );
  }
  Widget getInitialPage() {
  final path = html.window.location.pathname; // e.g., "/admin" or "/creator"

  if (path!.startsWith('/creator')) {
    return const CreatorAuthWrapper(); // Open creator auth flow
  } else {
    return AuthWrapper(); // Default admin login
  }
}


  // Function to check if the user is logged in based on localStorage or Firebase state
  bool isLoggedIn() {
    return html.window.localStorage['isLoggedIn'] == 'true' ||
        FirebaseAuth.instance.currentUser != null;
  }

  // Function to check if a route is protected and requires authentication
  bool isProtectedRoute(String? route) {
    final protectedRoutes = ['/Blog', '/Users', '/Videos', '/Addblog', '/add', '/quiz'];
    return protectedRoutes.contains(route);
  }
}
