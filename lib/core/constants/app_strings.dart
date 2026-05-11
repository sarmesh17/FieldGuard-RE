/// Application string constants for localization
class AppStrings {
  AppStrings._();

  // Login Screen
  static const String welcomeBack = 'Welcome Back';
  static const String signInToAccount = 'Sign in to your agent account';
  static const String mobileNumber = 'Mobile Number';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String signIn = 'Sign In';
  static const String requestAccess = 'Request Access';
  static const String enterPassword = 'Enter your password';
  static const String phoneHint = '000 000 000';

  // Validation Messages
  static const String phoneRequired = 'Phone number is required';
  static const String phoneInvalid = 'Please enter a valid phone number';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 8 characters';

  // Onboarding Screen
  static const String skip = 'Skip';
  static const String getStarted = 'Get Started';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String logIn = 'Log In';

  // Onboarding pages
  static const List<String> onboardingTitles = [
    'Stay Ahead in the Field',
    'Know Every Visit, Every Time',
  ];

  static const List<String> onboardingSubtitles = [
    'Get real-time alerts and updates so you never miss a critical visit or deadline in your territory.',
    'Automatic background tracking ensures your territory visits are accurately logged without manual entry.',
  ];

  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String invalidCredentials = 'Invalid phone number or password';
}
