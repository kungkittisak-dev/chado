// Sample code demonstrating feature flags before removal
// Note: This is an example. The import would be from your actual project.
// import 'package:myapp/services/feature_flag_service.dart';

// Mock feature flag service for demonstration
class FeatureFlagService {
  bool isEnabled(String flag) => true;
}

class AuthenticationScreen {
  final FeatureFlagService flags = FeatureFlagService();

  void showLogin() {
    // Example 1: Simple if statement (new_authentication_ui = true)
    // Expected: Keep new UI, remove old UI
    if (flags.isEnabled('new_authentication_ui')) {
      print('Showing new authentication UI');
      showNewAuthUI();
    } else {
      print('Showing old authentication UI');
      showOldAuthUI();
    }

    // Example 2: Negated flag (experimental_api = false)
    // Expected: Remove experimental code
    if (!flags.isEnabled('experimental_api')) {
      print('Using stable API');
      useStableAPI();
    } else {
      print('Using experimental API');
      useExperimentalAPI();
    }

    // Example 3: Complex condition (improved_performance = true)
    // Expected: Simplify to just userCondition()
    if (flags.isEnabled('improved_performance') && userCondition()) {
      print('Using improved performance mode');
      enableOptimizations();
    }

    // Example 4: Ternary operator (legacy_compatibility_mode = false)
    // Expected: Replace with modernImplementation()
    final implementation = flags.isEnabled('legacy_compatibility_mode')
        ? legacyImplementation()
        : modernImplementation();
    print('Using implementation: $implementation');

    // Example 5: Simple if without else (experimental_api = false)
    // Expected: Remove entire if statement
    if (flags.isEnabled('experimental_api')) {
      print('Running experimental code');
      runExperimentalCode();
    }

    // Example 6: OR condition (new_authentication_ui = true)
    // Expected: Keep then block (condition is always true)
    if (flags.isEnabled('new_authentication_ui') || fallbackCondition()) {
      print('This will always run');
      alwaysExecuteThis();
    }
  }

  void showNewAuthUI() {
    print('New UI');
  }

  void showOldAuthUI() {
    print('Old UI');
  }

  void useStableAPI() {
    print('Stable');
  }

  void useExperimentalAPI() {
    print('Experimental');
  }

  bool userCondition() => true;

  void enableOptimizations() {
    print('Optimized');
  }

  String legacyImplementation() => 'legacy';

  String modernImplementation() => 'modern';

  void runExperimentalCode() {
    print('Experimental');
  }

  bool fallbackCondition() => false;

  void alwaysExecuteThis() {
    print('Always');
  }
}

// Feature flag definitions that should be removed
class FeatureFlags {
  static const bool newAuthenticationUi = true;
  static const bool experimentalApi = false;
  static const bool improvedPerformance = true;
  static const bool legacyCompatibilityMode = false;
}
