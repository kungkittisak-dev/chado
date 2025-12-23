// Simple Riverpod test
class WidgetRef {
  bool watch(dynamic provider) => true;
}

bool releaseFlagProvider(String name) => true;

void testFunction(WidgetRef ref) {
  print('New Feature');
}
