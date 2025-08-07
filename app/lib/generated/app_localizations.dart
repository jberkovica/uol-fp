import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_lv.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('lv'),
    Locale('ru')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Mira Storyteller'**
  String get appTitle;

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'My tales'**
  String get myTales;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'create'**
  String get create;

  /// Favourites section title
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// Latest stories section title
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// Kid's personal stories section
  ///
  /// In en, this message translates to:
  /// **'{kidName}\'s stories'**
  String kidStories(String kidName);

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No stories yet'**
  String get noStoriesYet;

  /// Profile navigation item
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Home navigation item
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Settings navigation item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Profile selection screen title
  ///
  /// In en, this message translates to:
  /// **'Select Profile'**
  String get selectProfile;

  /// Error when no profile is selected
  ///
  /// In en, this message translates to:
  /// **'No profile selected'**
  String get noProfileSelected;

  /// Processing screen message
  ///
  /// In en, this message translates to:
  /// **'Magic is happening..'**
  String get magicIsHappening;

  /// Upload screen title
  ///
  /// In en, this message translates to:
  /// **'Upload your creation'**
  String get uploadYourCreation;

  /// Upload area text
  ///
  /// In en, this message translates to:
  /// **'Drag & drop here'**
  String get dragDropHere;

  /// Alternative option separator
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// File browser button
  ///
  /// In en, this message translates to:
  /// **'Browse file'**
  String get browseFile;

  /// Generate story button
  ///
  /// In en, this message translates to:
  /// **'Generate story'**
  String get generateStory;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Login prompt on signup page
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Signup prompt on login page
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Login screen greeting
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// Signup screen title
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// Parent dashboard title
  ///
  /// In en, this message translates to:
  /// **'Parent Dashboard'**
  String get parentDashboard;

  /// PIN entry screen title
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// Error message when stories fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load stories: {error}'**
  String failedToLoadStories(String error);

  /// No description provided for @audioRecordingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Audio recording will be implemented soon!'**
  String get audioRecordingComingSoon;

  /// No description provided for @textStoryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Text story generation will be implemented soon!'**
  String get textStoryComingSoon;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failedToPickImage(String error);

  /// No description provided for @failedToGenerateStory.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate story: {error}'**
  String failedToGenerateStory(String error);

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @failedToCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to create profile: {error}'**
  String failedToCreateProfile(String error);

  /// No description provided for @editProfileComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit profile coming soon!'**
  String get editProfileComingSoon;

  /// No description provided for @favoritesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Favorites coming soon!'**
  String get favoritesComingSoon;

  /// No description provided for @failedToPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to play audio: {error}'**
  String failedToPlayAudio(String error);

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please try again.'**
  String get incorrectPin;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Please check your email to verify your account.'**
  String get accountCreatedSuccessfully;

  /// No description provided for @appleSignInComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Apple sign in coming soon!'**
  String get appleSignInComingSoon;

  /// No description provided for @appleSignUpComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Apple sign up coming soon!'**
  String get appleSignUpComingSoon;

  /// No description provided for @failedToLoadKids.
  ///
  /// In en, this message translates to:
  /// **'Failed to load kids: {error}'**
  String failedToLoadKids(String error);

  /// No description provided for @addKidProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add a kid profile first to create stories'**
  String get addKidProfileFirst;

  /// No description provided for @noKidsProfilesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No kids profiles available. Add a kid first!'**
  String get noKidsProfilesAvailable;

  /// No description provided for @changePinComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Change PIN coming soon!'**
  String get changePinComingSoon;

  /// No description provided for @storySettingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Story settings coming soon!'**
  String get storySettingsComingSoon;

  /// No description provided for @exportDataComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Export data coming soon!'**
  String get exportDataComingSoon;

  /// No description provided for @deletingKidProfile.
  ///
  /// In en, this message translates to:
  /// **'Deleting {kidName}\'s profile...'**
  String deletingKidProfile(String kidName);

  /// No description provided for @kidProfileDeleted.
  ///
  /// In en, this message translates to:
  /// **'{kidName}\'s profile deleted successfully'**
  String kidProfileDeleted(String kidName);

  /// No description provided for @failedToDeleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete profile: {error}'**
  String failedToDeleteProfile(String error);

  /// No description provided for @languageUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Language updated to {language}'**
  String languageUpdatedTo(String language);

  /// No description provided for @failedToUpdateLanguage.
  ///
  /// In en, this message translates to:
  /// **'Failed to update language'**
  String get failedToUpdateLanguage;

  /// No description provided for @errorUpdatingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Error updating language: {error}'**
  String errorUpdatingLanguage(String error);

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'upload'**
  String get upload;

  /// No description provided for @dictate.
  ///
  /// In en, this message translates to:
  /// **'dictate'**
  String get dictate;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueWithFacebook;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign in failed'**
  String get googleSignInFailed;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign in failed'**
  String get appleSignInFailed;

  /// No description provided for @facebookSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Facebook sign in failed'**
  String get facebookSignInFailed;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @viewStories.
  ///
  /// In en, this message translates to:
  /// **'View Stories'**
  String get viewStories;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get deleteProfile;

  /// No description provided for @addKid.
  ///
  /// In en, this message translates to:
  /// **'Add Kid'**
  String get addKid;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @storyPreview.
  ///
  /// In en, this message translates to:
  /// **'Story preview'**
  String get storyPreview;

  /// No description provided for @exitParentMode.
  ///
  /// In en, this message translates to:
  /// **'Exit Parent Mode'**
  String get exitParentMode;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// No description provided for @backgroundMusic.
  ///
  /// In en, this message translates to:
  /// **'Background Music'**
  String get backgroundMusic;

  /// No description provided for @createAnotherStory.
  ///
  /// In en, this message translates to:
  /// **'Create Another Story'**
  String get createAnotherStory;

  /// No description provided for @fullNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Full Name (Optional)'**
  String get fullNameOptional;

  /// No description provided for @enterChildName.
  ///
  /// In en, this message translates to:
  /// **'Enter child\'s name'**
  String get enterChildName;

  /// No description provided for @writeYourIdeaHere.
  ///
  /// In en, this message translates to:
  /// **'write your idea here...'**
  String get writeYourIdeaHere;

  /// No description provided for @enterFeedbackOrChanges.
  ///
  /// In en, this message translates to:
  /// **'Enter any feedback or request changes...'**
  String get enterFeedbackOrChanges;

  /// No description provided for @transcribingAudio.
  ///
  /// In en, this message translates to:
  /// **'Transcribing audio...'**
  String get transcribingAudio;

  /// No description provided for @changeNameAgeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change name, age, or avatar'**
  String get changeNameAgeAvatar;

  /// No description provided for @switchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch Profile'**
  String get switchProfile;

  /// No description provided for @changeToDifferentKidProfile.
  ///
  /// In en, this message translates to:
  /// **'Change to different kid profile'**
  String get changeToDifferentKidProfile;

  /// No description provided for @favoriteStories.
  ///
  /// In en, this message translates to:
  /// **'Favorite Stories'**
  String get favoriteStories;

  /// No description provided for @viewYourMostLovedTales.
  ///
  /// In en, this message translates to:
  /// **'View your most loved tales'**
  String get viewYourMostLovedTales;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @updateParentDashboardPin.
  ///
  /// In en, this message translates to:
  /// **'Update your parent dashboard PIN'**
  String get updateParentDashboardPin;

  /// No description provided for @currentPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @enterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get enterCurrentPin;

  /// No description provided for @enterNewPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your new PIN'**
  String get enterNewPin;

  /// No description provided for @confirmNewPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new PIN'**
  String get confirmNewPin;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinsDoNotMatch;

  /// No description provided for @pinChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN changed successfully'**
  String get pinChangedSuccessfully;

  /// No description provided for @incorrectCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect current PIN'**
  String get incorrectCurrentPin;

  /// No description provided for @storySettings.
  ///
  /// In en, this message translates to:
  /// **'Story Settings'**
  String get storySettings;

  /// No description provided for @configureStoryGenerationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Configure story generation preferences'**
  String get configureStoryGenerationPreferences;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @downloadAllStoriesAndData.
  ///
  /// In en, this message translates to:
  /// **'Download all stories and data'**
  String get downloadAllStoriesAndData;

  /// No description provided for @noStoryDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No story data available'**
  String get noStoryDataAvailable;

  /// No description provided for @currentFontSize.
  ///
  /// In en, this message translates to:
  /// **'Current: {size}pt'**
  String currentFontSize(int size);

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @kidsProfiles.
  ///
  /// In en, this message translates to:
  /// **'Kids Profiles'**
  String get kidsProfiles;

  /// No description provided for @totalStories.
  ///
  /// In en, this message translates to:
  /// **'Total Stories'**
  String get totalStories;

  /// No description provided for @noKidsProfilesYet.
  ///
  /// In en, this message translates to:
  /// **'No Kids Profiles Yet'**
  String get noKidsProfilesYet;

  /// No description provided for @addFirstKidProfile.
  ///
  /// In en, this message translates to:
  /// **'Add your first kid profile to get started with personalized stories!'**
  String get addFirstKidProfile;

  /// No description provided for @parentControls.
  ///
  /// In en, this message translates to:
  /// **'Parent Controls'**
  String get parentControls;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @newStory.
  ///
  /// In en, this message translates to:
  /// **'New Story'**
  String get newStory;

  /// No description provided for @stories.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =0{stories} =1{story} other{stories}}'**
  String stories(int count);

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String createdDate(String date);

  /// No description provided for @deleteProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {kidName}\'s profile? This will also delete all their {storyCount} stories.'**
  String deleteProfileConfirm(String kidName, int storyCount);

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile: {avatarType}'**
  String profileDetails(String avatarType);

  /// No description provided for @creatingStoriesSince.
  ///
  /// In en, this message translates to:
  /// **'Creating stories since {date}'**
  String creatingStoriesSince(String date);

  /// No description provided for @storiesCreated.
  ///
  /// In en, this message translates to:
  /// **'Stories Created'**
  String get storiesCreated;

  /// No description provided for @wordsWritten.
  ///
  /// In en, this message translates to:
  /// **'Words Written'**
  String get wordsWritten;

  /// No description provided for @profileOptions.
  ///
  /// In en, this message translates to:
  /// **'Profile Options'**
  String get profileOptions;

  /// No description provided for @changeToDifferentProfile.
  ///
  /// In en, this message translates to:
  /// **'Change to different kid profile'**
  String get changeToDifferentProfile;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @latvian.
  ///
  /// In en, this message translates to:
  /// **'Latviešu'**
  String get latvian;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @storyApprovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Story approved successfully!'**
  String get storyApprovedSuccessfully;

  /// No description provided for @storyDeclined.
  ///
  /// In en, this message translates to:
  /// **'Story declined'**
  String get storyDeclined;

  /// No description provided for @declineStory.
  ///
  /// In en, this message translates to:
  /// **'Decline Story'**
  String get declineStory;

  /// No description provided for @pleaseProvideReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for declining:'**
  String get pleaseProvideReason;

  /// No description provided for @declineReasonHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., too scary, inappropriate content, etc.'**
  String get declineReasonHint;

  /// No description provided for @suggestEdits.
  ///
  /// In en, this message translates to:
  /// **'Suggest Edits'**
  String get suggestEdits;

  /// No description provided for @provideSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Provide suggestions to improve the story:'**
  String get provideSuggestions;

  /// No description provided for @suggestionsHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., make it less scary, add more about friendship, etc.'**
  String get suggestionsHint;

  /// No description provided for @regeneratingStory.
  ///
  /// In en, this message translates to:
  /// **'Regenerating story with your suggestions...'**
  String get regeneratingStory;

  /// No description provided for @regenerateStory.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Story'**
  String get regenerateStory;

  /// No description provided for @imageNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get imageNotAvailable;

  /// No description provided for @pendingStories.
  ///
  /// In en, this message translates to:
  /// **'Pending Stories'**
  String get pendingStories;

  /// No description provided for @noPendingStories.
  ///
  /// In en, this message translates to:
  /// **'No pending stories for review'**
  String get noPendingStories;

  /// No description provided for @allStoriesReviewed.
  ///
  /// In en, this message translates to:
  /// **'All stories have been reviewed'**
  String get allStoriesReviewed;

  /// No description provided for @forChild.
  ///
  /// In en, this message translates to:
  /// **'For {childName}'**
  String forChild(String childName);

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @approvalMethod.
  ///
  /// In en, this message translates to:
  /// **'Approval Method'**
  String get approvalMethod;

  /// No description provided for @selectApprovalMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Approval Method'**
  String get selectApprovalMethod;

  /// No description provided for @autoApprove.
  ///
  /// In en, this message translates to:
  /// **'Auto Approve'**
  String get autoApprove;

  /// No description provided for @reviewInApp.
  ///
  /// In en, this message translates to:
  /// **'Review in App'**
  String get reviewInApp;

  /// No description provided for @reviewByEmail.
  ///
  /// In en, this message translates to:
  /// **'Review by Email'**
  String get reviewByEmail;

  /// No description provided for @autoApproveDescription.
  ///
  /// In en, this message translates to:
  /// **'Stories are automatically approved and available immediately'**
  String get autoApproveDescription;

  /// No description provided for @reviewInAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Review stories in the parent dashboard before they\'re shown to children'**
  String get reviewInAppDescription;

  /// No description provided for @reviewByEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive email notifications to review stories before approval'**
  String get reviewByEmailDescription;

  /// No description provided for @approvalMethodUpdated.
  ///
  /// In en, this message translates to:
  /// **'Approval method updated to {method}'**
  String approvalMethodUpdated(String method);

  /// No description provided for @failedToUpdateApprovalMethod.
  ///
  /// In en, this message translates to:
  /// **'Failed to update approval method'**
  String get failedToUpdateApprovalMethod;

  /// No description provided for @errorUpdatingApprovalMethod.
  ///
  /// In en, this message translates to:
  /// **'Error updating approval method: {error}'**
  String errorUpdatingApprovalMethod(String error);

  /// No description provided for @yourStoryIsReady.
  ///
  /// In en, this message translates to:
  /// **'Your story is ready!'**
  String get yourStoryIsReady;

  /// No description provided for @parentReviewPending.
  ///
  /// In en, this message translates to:
  /// **'Parent review pending'**
  String get parentReviewPending;

  /// No description provided for @tapReviewToApprove.
  ///
  /// In en, this message translates to:
  /// **'Tap Review to ask parent for approval'**
  String get tapReviewToApprove;

  /// No description provided for @weWillNotifyWhenReady.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know when your story is ready!'**
  String get weWillNotifyWhenReady;

  /// No description provided for @openStory.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get openStory;

  /// No description provided for @pleaseEnterText.
  ///
  /// In en, this message translates to:
  /// **'Please enter some text to create your story'**
  String get pleaseEnterText;

  /// No description provided for @textTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please write at least 10 characters for your story idea'**
  String get textTooShort;

  /// No description provided for @textTooLong.
  ///
  /// In en, this message translates to:
  /// **'Text is too long. Please keep it under 500 characters'**
  String get textTooLong;

  /// No description provided for @pleaseSelectChild.
  ///
  /// In en, this message translates to:
  /// **'Please select a child first'**
  String get pleaseSelectChild;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecording;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record audio'**
  String get microphonePermissionRequired;

  /// No description provided for @failedToStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to start recording'**
  String get failedToStartRecording;

  /// No description provided for @failedToStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop recording'**
  String get failedToStopRecording;

  /// No description provided for @noRecordingAvailable.
  ///
  /// In en, this message translates to:
  /// **'No recording available'**
  String get noRecordingAvailable;

  /// No description provided for @addNewProfile.
  ///
  /// In en, this message translates to:
  /// **'Add New Profile'**
  String get addNewProfile;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @createNewProfile.
  ///
  /// In en, this message translates to:
  /// **'Create New Profile'**
  String get createNewProfile;

  /// No description provided for @addDetailsForChild.
  ///
  /// In en, this message translates to:
  /// **'Add details for your child'**
  String get addDetailsForChild;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceOptional.
  ///
  /// In en, this message translates to:
  /// **'Appearance (Optional)'**
  String get appearanceOptional;

  /// No description provided for @personalityPreferences.
  ///
  /// In en, this message translates to:
  /// **'Personality & Preferences'**
  String get personalityPreferences;

  /// No description provided for @personalityPreferencesOptional.
  ///
  /// In en, this message translates to:
  /// **'Personality & Preferences (Optional)'**
  String get personalityPreferencesOptional;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// No description provided for @additionalNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes (Optional)'**
  String get additionalNotesOptional;

  /// No description provided for @ageOptional.
  ///
  /// In en, this message translates to:
  /// **'Age (Optional)'**
  String get ageOptional;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get chooseAvatar;

  /// No description provided for @hairColor.
  ///
  /// In en, this message translates to:
  /// **'Hair Color'**
  String get hairColor;

  /// No description provided for @hairColorOptional.
  ///
  /// In en, this message translates to:
  /// **'Hair Color (Optional)'**
  String get hairColorOptional;

  /// No description provided for @hairLength.
  ///
  /// In en, this message translates to:
  /// **'Hair Length'**
  String get hairLength;

  /// No description provided for @hairLengthOptional.
  ///
  /// In en, this message translates to:
  /// **'Hair Length (Optional)'**
  String get hairLengthOptional;

  /// No description provided for @skinColor.
  ///
  /// In en, this message translates to:
  /// **'Skin Color'**
  String get skinColor;

  /// No description provided for @skinColorOptional.
  ///
  /// In en, this message translates to:
  /// **'Skin Color (Optional)'**
  String get skinColorOptional;

  /// No description provided for @eyeColor.
  ///
  /// In en, this message translates to:
  /// **'Eye Color'**
  String get eyeColor;

  /// No description provided for @eyeColorOptional.
  ///
  /// In en, this message translates to:
  /// **'Eye Color (Optional)'**
  String get eyeColorOptional;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderOptional.
  ///
  /// In en, this message translates to:
  /// **'Gender (Optional)'**
  String get genderOptional;

  /// No description provided for @favoriteStoryTypes.
  ///
  /// In en, this message translates to:
  /// **'Favorite Story Types'**
  String get favoriteStoryTypes;

  /// No description provided for @favoriteStoryTypesOptional.
  ///
  /// In en, this message translates to:
  /// **'Favorite Story Types (Optional)'**
  String get favoriteStoryTypesOptional;

  /// No description provided for @addSpecialNotes.
  ///
  /// In en, this message translates to:
  /// **'Add any special notes about your child...'**
  String get addSpecialNotes;

  /// No description provided for @addSpecialNotesFor.
  ///
  /// In en, this message translates to:
  /// **'Add any special notes about {childName}...'**
  String addSpecialNotesFor(String childName);

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String failedToUpdateProfile(String error);

  /// No description provided for @setYourParentPin.
  ///
  /// In en, this message translates to:
  /// **'Set Your Parent PIN'**
  String get setYourParentPin;

  /// No description provided for @createFourDigitPinAccess.
  ///
  /// In en, this message translates to:
  /// **'Create a 4-digit PIN to access\nparent dashboard and settings'**
  String get createFourDigitPinAccess;

  /// No description provided for @settingUpYourPin.
  ///
  /// In en, this message translates to:
  /// **'Setting up your PIN...'**
  String get settingUpYourPin;

  /// No description provided for @thisWillBeUsedForAccess.
  ///
  /// In en, this message translates to:
  /// **'This PIN will be used to access parent settings and approve stories for your children.'**
  String get thisWillBeUsedForAccess;

  /// No description provided for @pleaseEnterAllFourDigits.
  ///
  /// In en, this message translates to:
  /// **'Please enter all 4 digits'**
  String get pleaseEnterAllFourDigits;

  /// No description provided for @failedToSetPin.
  ///
  /// In en, this message translates to:
  /// **'Failed to set PIN. Please try again.'**
  String get failedToSetPin;

  /// Hint text for dictation recording button
  ///
  /// In en, this message translates to:
  /// **'Tap to start recording'**
  String get tapToStartRecording;

  /// Tooltip for pause recording button
  ///
  /// In en, this message translates to:
  /// **'Pause recording'**
  String get pauseRecording;

  /// Tooltip for start over button
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// Tooltip for play audio button
  ///
  /// In en, this message translates to:
  /// **'Play audio'**
  String get playAudio;

  /// Tooltip for pause audio button
  ///
  /// In en, this message translates to:
  /// **'Pause audio'**
  String get pauseAudio;

  /// Tooltip for submit transcription button
  ///
  /// In en, this message translates to:
  /// **'Submit for transcription'**
  String get submitForTranscription;

  /// Button to dictate again
  ///
  /// In en, this message translates to:
  /// **'Dictate Again'**
  String get dictateAgain;

  /// Button to edit as text
  ///
  /// In en, this message translates to:
  /// **'Edit as Text'**
  String get editAsText;

  /// Title for image source selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// Button to take photo with camera
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Button to choose photo from gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Button to switch to text input mode
  ///
  /// In en, this message translates to:
  /// **'Switch to Text'**
  String get switchToText;

  /// Short camera button label
  ///
  /// In en, this message translates to:
  /// **'camera'**
  String get camera;

  /// Short gallery button label
  ///
  /// In en, this message translates to:
  /// **'gallery'**
  String get gallery;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'lv', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'lv':
      return AppLocalizationsLv();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
