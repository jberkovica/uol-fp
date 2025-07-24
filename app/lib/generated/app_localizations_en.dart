import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mira Storyteller';

  @override
  String get myTales => 'My tales';

  @override
  String get create => 'create';

  @override
  String get favourites => 'Favourites';

  @override
  String get latest => 'Latest';

  @override
  String kidStories(String kidName) {
    return '$kidName\'s stories';
  }

  @override
  String get noStoriesYet => 'No stories yet';

  @override
  String get profile => 'Profile';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get selectProfile => 'Select Profile';

  @override
  String get noProfileSelected => 'No profile selected';

  @override
  String get magicIsHappening => 'Magic is happening..';

  @override
  String get uploadYourCreation => 'Upload your creation';

  @override
  String get dragDropHere => 'Drag & drop here';

  @override
  String get or => 'OR';

  @override
  String get browseFile => 'Browse file';

  @override
  String get generateStory => 'Generate story';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get parentDashboard => 'Parent Dashboard';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String failedToLoadStories(String error) {
    return 'Failed to load stories: $error';
  }

  @override
  String get audioRecordingComingSoon => 'Audio recording will be implemented soon!';

  @override
  String get textStoryComingSoon => 'Text story generation will be implemented soon!';

  @override
  String failedToPickImage(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String failedToGenerateStory(String error) {
    return 'Failed to generate story: $error';
  }

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String failedToCreateProfile(String error) {
    return 'Failed to create profile: $error';
  }

  @override
  String get editProfileComingSoon => 'Edit profile coming soon!';

  @override
  String get favoritesComingSoon => 'Favorites coming soon!';

  @override
  String failedToPlayAudio(String error) {
    return 'Failed to play audio: $error';
  }

  @override
  String get incorrectPin => 'Incorrect PIN. Please try again.';

  @override
  String get accountCreatedSuccessfully => 'Account created successfully! Please check your email to verify your account.';

  @override
  String get appleSignInComingSoon => 'Apple sign in coming soon!';

  @override
  String get appleSignUpComingSoon => 'Apple sign up coming soon!';

  @override
  String failedToLoadKids(String error) {
    return 'Failed to load kids: $error';
  }

  @override
  String get addKidProfileFirst => 'Please add a kid profile first to create stories';

  @override
  String get noKidsProfilesAvailable => 'No kids profiles available. Add a kid first!';

  @override
  String get changePinComingSoon => 'Change PIN coming soon!';

  @override
  String get storySettingsComingSoon => 'Story settings coming soon!';

  @override
  String get exportDataComingSoon => 'Export data coming soon!';

  @override
  String deletingKidProfile(String kidName) {
    return 'Deleting $kidName\'s profile...';
  }

  @override
  String kidProfileDeleted(String kidName) {
    return '$kidName\'s profile deleted successfully';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Failed to delete profile: $error';
  }

  @override
  String languageUpdatedTo(String language) {
    return 'Language updated to $language';
  }

  @override
  String get failedToUpdateLanguage => 'Failed to update language';

  @override
  String errorUpdatingLanguage(String error) {
    return 'Error updating language: $error';
  }

  @override
  String get upload => 'upload';

  @override
  String get dictate => 'dictate';

  @override
  String get submit => 'submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get createAccount => 'Create Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get viewStories => 'View Stories';

  @override
  String get deleteProfile => 'Delete Profile';

  @override
  String get addKid => 'Add Kid';

  @override
  String get decline => 'Decline';

  @override
  String get approve => 'Approve';

  @override
  String get delete => 'Delete';

  @override
  String get storyPreview => 'Story preview';

  @override
  String get exitParentMode => 'Exit Parent Mode';

  @override
  String get textSize => 'Text Size';

  @override
  String get backgroundMusic => 'Background Music';

  @override
  String get createAnotherStory => 'Create Another Story';

  @override
  String get fullNameOptional => 'Full Name (Optional)';

  @override
  String get enterChildName => 'Enter child\'s name';

  @override
  String get writeYourIdeaHere => 'write your idea here...';

  @override
  String get enterFeedbackOrChanges => 'Enter any feedback or request changes...';

  @override
  String get changeNameAgeAvatar => 'Change name, age, or avatar';

  @override
  String get switchProfile => 'Switch Profile';

  @override
  String get changeToDifferentKidProfile => 'Change to different kid profile';

  @override
  String get favoriteStories => 'Favorite Stories';

  @override
  String get viewYourMostLovedTales => 'View your most loved tales';

  @override
  String get language => 'Language';

  @override
  String get changePin => 'Change PIN';

  @override
  String get updateParentDashboardPin => 'Update your parent dashboard PIN';

  @override
  String get storySettings => 'Story Settings';

  @override
  String get configureStoryGenerationPreferences => 'Configure story generation preferences';

  @override
  String get exportData => 'Export Data';

  @override
  String get downloadAllStoriesAndData => 'Download all stories and data';

  @override
  String get noStoryDataAvailable => 'No story data available';

  @override
  String currentFontSize(int size) {
    return 'Current: ${size}pt';
  }

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get kidsProfiles => 'Kids Profiles';

  @override
  String get totalStories => 'Total Stories';

  @override
  String get noKidsProfilesYet => 'No Kids Profiles Yet';

  @override
  String get addFirstKidProfile => 'Add your first kid profile to get started with personalized stories!';

  @override
  String get parentControls => 'Parent Controls';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get newStory => 'New Story';

  @override
  String stories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'stories',
      one: 'story',
      zero: 'stories',
    );
    return '$count $_temp0';
  }

  @override
  String createdDate(String date) {
    return 'Created $date';
  }

  @override
  String deleteProfileConfirm(String kidName, int storyCount) {
    return 'Are you sure you want to delete $kidName\'s profile? This will also delete all their $storyCount stories.';
  }

  @override
  String profileDetails(String avatarType) {
    return 'Profile: $avatarType';
  }

  @override
  String creatingStoriesSince(String date) {
    return 'Creating stories since $date';
  }

  @override
  String get storiesCreated => 'Stories Created';

  @override
  String get wordsWritten => 'Words Written';

  @override
  String get profileOptions => 'Profile Options';

  @override
  String get changeToDifferentProfile => 'Change to different kid profile';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get latvian => 'Latviešu';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';
}
