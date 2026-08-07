import 'package:objectbox/objectbox.dart';

@Entity()
class OnboardingCacheEntity {
  @Id()
  int id;
  bool hasSeenLocationOnboarding;

  OnboardingCacheEntity({
    this.id = 0,
    required this.hasSeenLocationOnboarding,
  });
}
