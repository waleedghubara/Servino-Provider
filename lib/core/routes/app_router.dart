import 'package:flutter/material.dart';
import 'package:servino_provider/core/routes/routes.dart';
import 'package:servino_provider/features/auth/password_reset_success_page.dart';
import 'package:servino_provider/features/auth/register_page.dart';
import 'package:servino_provider/features/auth/register_success_page.dart';
import 'package:servino_provider/features/auth/reset_password_page.dart';
import 'package:servino_provider/features/chat/pages/conversations_page.dart';
import 'package:servino_provider/features/main_layout/main_layout_page.dart';
import 'package:servino_provider/features/splash/splash_page.dart';
import 'package:servino_provider/features/auth/login_page.dart';
import 'package:servino_provider/features/auth/forgot_password_page.dart';
import 'package:servino_provider/features/auth/otp_page.dart';
import 'package:servino_provider/features/notifications/notifications_page.dart';
import 'package:servino_provider/features/subscription/subscription_page.dart';
import 'package:servino_provider/features/wallet/wallet_page.dart';
import 'package:servino_provider/features/payment/pages/payment_method_selection_page.dart';
import 'package:servino_provider/features/payment/pages/payment_details_page.dart';
import 'package:servino_provider/features/payment/pages/payment_instruction_page.dart';
import 'package:servino_provider/features/payment/pages/payment_success_page.dart';
import 'package:servino_provider/features/payment/pages/payment_waiting_page.dart';
import 'package:servino_provider/features/payment/pages/paypal_checkout_page.dart';
import 'package:servino_provider/features/payment/models/payment_params.dart';
import 'package:servino_provider/features/payment/models/payment_gateway_model.dart';
import 'package:servino_provider/features/support/support_page.dart';
import 'package:servino_provider/core/widgets/server_error_page.dart';
import 'package:servino_provider/features/auth/banned_page.dart';
import 'package:servino_provider/features/profile/contact_us_page.dart';

/// Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Application Router
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashPage(),
          settings: settings,
        );
      case Routes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case Routes.banned:
        return MaterialPageRoute(
          builder: (_) => const BannedPage(),
          settings: settings,
        );
      case Routes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordPage(),
          settings: settings,
        );
      case Routes.otp:
        return MaterialPageRoute(
          builder: (_) => const OtpPage(),
          settings: settings,
        );
      case Routes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );
      case Routes.resetPassword:
        return MaterialPageRoute(
          builder: (_) => const ResetPasswordPage(),
          settings: settings,
        );
      case Routes.registerSuccess:
        return MaterialPageRoute(
          builder: (_) => const RegisterSuccessPage(),
          settings: settings,
        );
      case Routes.passwordResetSuccess:
        return MaterialPageRoute(
          builder: (_) => const PasswordResetSuccessPage(),
          settings: settings,
        );
      case Routes.main:
        return MaterialPageRoute(
          builder: (_) => const MainLayoutPage(),
          settings: settings,
        );
      case Routes.serverError:
        return MaterialPageRoute(
          builder: (_) => const ServerErrorPage(),
          settings: settings,
        );
      case Routes.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsPage(),
          settings: settings,
        );
      case Routes.subscription:
        return MaterialPageRoute(
          builder: (_) => const SubscriptionPage(),
          settings: settings,
        );
      case Routes.wallet:
        return MaterialPageRoute(
          builder: (_) => const WalletPage(),
          settings: settings,
        );

      // Payment Routes
      case Routes.paymentMethodSelection:
        return MaterialPageRoute(
          builder: (_) => PaymentMethodSelectionPage(
            params: settings.arguments as PaymentParams,
          ),
          settings: settings,
        );
      case Routes.paymentDetails:
        return MaterialPageRoute(
          builder: (_) =>
              PaymentDetailsPage(params: settings.arguments as PaymentParams),
          settings: settings,
        );
      case Routes.paymentInstruction:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PaymentInstructionPage(
            params: args['params'] as PaymentParams,
            method: args['method'] as PaymentGatewayModel,
          ),
          settings: settings,
        );
      case Routes.paypalCheckout:
        return MaterialPageRoute(
          builder: (_) => PaypalCheckoutPage(
            args: settings.arguments as PaypalCheckoutPageParams,
          ),
          settings: settings,
        );
      case Routes.paymentSuccess:
        return MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            params: settings.arguments as PaymentSuccessPageParams,
          ),
          settings: settings,
        );
      case Routes.paymentWaiting:
        final args = settings.arguments;
        PaymentParams params;
        String? transactionId;

        if (args is Map<String, dynamic>) {
          params = args['params'] as PaymentParams;
          transactionId = args['transactionId'] as String?;
        } else {
          params = args as PaymentParams;
        }

        return MaterialPageRoute(
          builder: (_) =>
              PaymentWaitingPage(params: params, transactionId: transactionId),
          settings: settings,
        );
      case Routes.support:
        return MaterialPageRoute(
          builder: (_) => const SupportPage(),
          settings: settings,
        );
      case Routes.conversations:
        return MaterialPageRoute(
          builder: (_) => const ConversationsPage(),
          settings: settings,
        );
      case Routes.contactUs:
        return MaterialPageRoute(
          builder: (_) => const ContactUsPage(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings: settings,
        );
    }
  }

  static void navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
