// ignore: unused_import
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
  String get favourites => 'Favorites';

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
  String get logout => 'Logout';

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
  String get audioRecordingComingSoon =>
      'Audio recording will be implemented soon!';

  @override
  String get textStoryComingSoon =>
      'Text story generation will be implemented soon!';

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
  String get accountCreatedSuccessfully =>
      'Account created successfully! Please check your email to verify your account.';

  @override
  String get appleSignInComingSoon => 'Apple sign in coming soon!';

  @override
  String get appleSignUpComingSoon => 'Apple sign up coming soon!';

  @override
  String failedToLoadKids(String error) {
    return 'Failed to load kids: $error';
  }

  @override
  String get addKidProfileFirst =>
      'Please add a kid profile first to create stories';

  @override
  String get noKidsProfilesAvailable =>
      'No kids profiles available. Add a kid first!';

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
  String get continueWithFacebook => 'Continue with Facebook';

  @override
  String get googleSignInFailed => 'Google sign in failed';

  @override
  String get appleSignInFailed => 'Apple sign in failed';

  @override
  String get facebookSignInFailed => 'Facebook sign in failed';

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
  String get enterFeedbackOrChanges =>
      'Enter any feedback or request changes...';

  @override
  String get transcribingAudio => 'Transcribing audio...';

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
  String get currentPin => 'Current PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get enterCurrentPin => 'Enter your current PIN';

  @override
  String get enterNewPin => 'Enter your new PIN';

  @override
  String get confirmNewPin => 'Confirm your new PIN';

  @override
  String get pinsDoNotMatch => 'PINs do not match';

  @override
  String get pinChangedSuccessfully => 'PIN changed successfully';

  @override
  String get incorrectCurrentPin => 'Incorrect current PIN';

  @override
  String get storySettings => 'Story Settings';

  @override
  String get configureStoryGenerationPreferences =>
      'Configure story generation preferences';

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
  String get addFirstKidProfile =>
      'Add your first kid profile to get started with personalized stories!';

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
  String get spanish => 'Español';

  @override
  String get french => 'Français';

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

  @override
  String get storyApprovedSuccessfully => 'Story approved successfully!';

  @override
  String get storyDeclined => 'Story declined';

  @override
  String get declineStory => 'Decline Story';

  @override
  String get pleaseProvideReason => 'Please provide a reason for declining:';

  @override
  String get declineReasonHint =>
      'E.g., too scary, inappropriate content, etc.';

  @override
  String get suggestEdits => 'Suggest Edits';

  @override
  String get provideSuggestions => 'Provide suggestions to improve the story:';

  @override
  String get suggestionsHint =>
      'E.g., make it less scary, add more about friendship, etc.';

  @override
  String get regeneratingStory => 'Regenerating story with your suggestions...';

  @override
  String get regenerateStory => 'Regenerate Story';

  @override
  String get imageNotAvailable => 'Image not available';

  @override
  String get pendingStories => 'Pending Stories';

  @override
  String get noPendingStories => 'No pending stories for review';

  @override
  String get allStoriesReviewed => 'All stories have been reviewed';

  @override
  String forChild(String childName) {
    return 'For $childName';
  }

  @override
  String get review => 'Review';

  @override
  String get approvalMethod => 'Approval Method';

  @override
  String get selectApprovalMethod => 'Select Approval Method';

  @override
  String get autoApprove => 'Auto Approve';

  @override
  String get reviewInApp => 'Review in App';

  @override
  String get reviewByEmail => 'Review by Email';

  @override
  String get autoApproveDescription =>
      'Stories are automatically approved and available immediately';

  @override
  String get reviewInAppDescription =>
      'Review stories in the parent dashboard before they\'re shown to children';

  @override
  String get reviewByEmailDescription =>
      'Receive email notifications to review stories before approval';

  @override
  String approvalMethodUpdated(String method) {
    return 'Approval method updated to $method';
  }

  @override
  String get failedToUpdateApprovalMethod => 'Failed to update approval method';

  @override
  String errorUpdatingApprovalMethod(String error) {
    return 'Error updating approval method: $error';
  }

  @override
  String get yourStoryIsReady => 'Your story is ready!';

  @override
  String get parentReviewPending => 'Parent review pending';

  @override
  String get tapReviewToApprove => 'Tap Review to ask parent for approval';

  @override
  String get weWillNotifyWhenReady =>
      'We\'ll let you know when your story is ready!';

  @override
  String get openStory => 'open';

  @override
  String get pleaseEnterText => 'Please enter some text to create your story';

  @override
  String get textTooShort =>
      'Please write at least 10 characters for your story idea';

  @override
  String get textTooLong =>
      'Text is too long. Please keep it under 500 characters';

  @override
  String get pleaseSelectChild => 'Please select a child first';

  @override
  String get recording => 'Recording';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get microphonePermissionRequired =>
      'Microphone permission is required to record audio';

  @override
  String get failedToStartRecording => 'Failed to start recording';

  @override
  String get failedToStopRecording => 'Failed to stop recording';

  @override
  String get noRecordingAvailable => 'No recording available';

  @override
  String get addNewProfile => 'Add New Profile';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get createNewProfile => 'Create New Profile';

  @override
  String get addDetailsForChild => 'Add details for your child';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceOptional => 'Appearance (Optional)';

  @override
  String get personalityPreferences => 'Personality & Preferences';

  @override
  String get personalityPreferencesOptional =>
      'Personality & Preferences (Optional)';

  @override
  String get additionalNotes => 'Additional Notes';

  @override
  String get additionalNotesOptional => 'Additional Notes (Optional)';

  @override
  String get ageOptional => 'Age (Optional)';

  @override
  String get chooseAvatar => 'Choose Avatar';

  @override
  String get hairColor => 'Hair Color';

  @override
  String get hairColorOptional => 'Hair Color (Optional)';

  @override
  String get hairLength => 'Hair Length';

  @override
  String get hairLengthOptional => 'Hair Length (Optional)';

  @override
  String get skinColor => 'Skin Color';

  @override
  String get skinColorOptional => 'Skin Color (Optional)';

  @override
  String get eyeColor => 'Eye Color';

  @override
  String get eyeColorOptional => 'Eye Color (Optional)';

  @override
  String get gender => 'Gender';

  @override
  String get genderOptional => 'Gender (Optional)';

  @override
  String get favoriteStoryTypes => 'Favorite Story Types';

  @override
  String get favoriteStoryTypesOptional => 'Favorite Story Types (Optional)';

  @override
  String get addSpecialNotes => 'Add any special notes about your child...';

  @override
  String addSpecialNotesFor(String childName) {
    return 'Add any special notes about $childName...';
  }

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get creating => 'Creating...';

  @override
  String failedToUpdateProfile(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get setYourParentPin => 'Set Your Parent PIN';

  @override
  String get createFourDigitPinAccess =>
      'Create a 4-digit PIN to access\nparent dashboard and settings';

  @override
  String get settingUpYourPin => 'Setting up your PIN...';

  @override
  String get thisWillBeUsedForAccess =>
      'This PIN will be used to access parent settings and approve stories for your children.';

  @override
  String get pleaseEnterAllFourDigits => 'Please enter all 4 digits';

  @override
  String get failedToSetPin => 'Failed to set PIN. Please try again.';

  @override
  String get tapToStartRecording => 'Tap to start recording';

  @override
  String get pauseRecording => 'Pause recording';

  @override
  String get startOver => 'Start over';

  @override
  String get playAudio => 'Play audio';

  @override
  String get pauseAudio => 'Pause audio';

  @override
  String get submitForTranscription => 'Submit for transcription';

  @override
  String get dictateAgain => 'Dictate Again';

  @override
  String get editAsText => 'Edit as Text';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get switchToText => 'Switch to Text';

  @override
  String get camera => 'camera';

  @override
  String get gallery => 'gallery';

  @override
  String get age => 'Age';

  @override
  String get appearanceOptionalSection => 'Appearance (Optional)';

  @override
  String get appearanceDescription =>
      'Describe how your child looks to help create personalized stories.';

  @override
  String get appearanceMethodQuestion =>
      'How would you like to describe appearance?';

  @override
  String get describeInWords => 'Describe in words';

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get aiWillAnalyzePhoto =>
      'AI will analyze the photo and create a description';

  @override
  String get extractingAppearance => 'Extracting appearance...';

  @override
  String get aiExtractedDescription =>
      'AI extracted this description from your photo. Feel free to review and edit it.';

  @override
  String get appearanceExamplePlaceholder =>
      'Example: \"Curly brown hair, bright green eyes, and a gap-toothed smile\"';

  @override
  String get appearancePhotoPlaceholder =>
      'Upload a photo above to auto-generate description, or type manually';

  @override
  String get appearanceHelperText =>
      'Describe hair, eyes, distinctive features, etc. This helps create personalized stories.';

  @override
  String get aiGeneratedHelperText =>
      'You can edit this AI-generated description to make it more personal.';

  @override
  String get storyPreferencesOptional => 'Story Preferences (Optional)';

  @override
  String get preferredLanguage => 'Preferred Language';

  @override
  String get parentNotesOptional => 'Parent Notes (Optional)';

  @override
  String get parentNotesDescription =>
      'Add special context for stories: hobbies, pets, siblings, interests, etc.';

  @override
  String get parentNotesExample =>
      'Example: Loves dinosaurs, has a pet cat named Whiskers...';

  @override
  String get ageRequired => 'Age (Required)';

  @override
  String get appearanceExtractedSuccess =>
      'Appearance extracted! You can review and edit the description below.';

  @override
  String failedToExtractAppearance(String error) {
    return 'Failed to extract appearance: $error';
  }

  @override
  String get genreAdventure => 'Adventure';

  @override
  String get genreFantasy => 'Fantasy';

  @override
  String get genreFriendship => 'Friendship';

  @override
  String get genreFamily => 'Family';

  @override
  String get genreAnimals => 'Animals';

  @override
  String get genreMagic => 'Magic';

  @override
  String get genreSpace => 'Space';

  @override
  String get genreUnderwater => 'Underwater';

  @override
  String get genreForest => 'Forest';

  @override
  String get genreFairyTale => 'Fairy Tale';

  @override
  String get genreSuperhero => 'Superhero';

  @override
  String get genreDinosaurs => 'Dinosaurs';

  @override
  String get genrePirates => 'Pirates';

  @override
  String get genrePrincess => 'Princess';

  @override
  String get genreDragons => 'Dragons';

  @override
  String get genreRobots => 'Robots';

  @override
  String get genreMystery => 'Mystery';

  @override
  String get genreFunny => 'Funny';

  @override
  String get genreEducational => 'Educational';

  @override
  String get genreBedtime => 'Bedtime Stories';

  @override
  String get wizardNameTitle => 'What\'s your little one\'s name?';

  @override
  String get wizardNameSubtitle => 'Choose a name and fun avatar';

  @override
  String get wizardAgeTitle => 'How old is your little one?';

  @override
  String get wizardAgeSubtitle =>
      'This helps us choose the perfect vocabulary and themes';

  @override
  String get wizardGenderTitle => 'Tell us about your child';

  @override
  String get wizardGenderSubtitle =>
      'We\'ll use the right pronouns and perspective';

  @override
  String get wizardAppearanceTitle => 'Help us personalize stories';

  @override
  String get wizardAppearanceSubtitle =>
      'Describe your child\'s appearance (optional)';

  @override
  String get wizardGenresTitle => 'What does your child love?';

  @override
  String get wizardGenresSubtitle =>
      'Pick their favorite story types (optional)';

  @override
  String get wizardNotesTitle => 'Any special details?';

  @override
  String get wizardNotesSubtitle =>
      'Share interests, pets, or lessons to include (optional)';

  @override
  String get wizardReviewTitle => 'Ready to create magic!';

  @override
  String get wizardReviewSubtitle => 'Review your child\'s profile';

  @override
  String get enterName => 'Enter name';

  @override
  String get chooseAnAvatar => 'Choose an avatar';

  @override
  String get boy => 'Boy';

  @override
  String get girl => 'Girl';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String stepOfSteps(int currentStep, int totalSteps) {
    return 'Step $currentStep of $totalSteps';
  }

  @override
  String get parentNotesHintText =>
      'e.g., Has a pet dog named Max, loves space and rockets, learning about sharing...';

  @override
  String get enterAge212 => 'Enter age (2-12)';

  @override
  String get pleaseEnterAge => 'Please enter age';

  @override
  String get pleaseEnterValidAge => 'Please enter a valid age';

  @override
  String get ageRangeError => 'Age must be between 2 and 12';

  @override
  String get avatarUpdatedSuccessfully => 'Avatar updated successfully!';

  @override
  String get failedToUpdateAvatar =>
      'Failed to update avatar. Please try again.';

  @override
  String get describe => 'Describe';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get aiExtractedAppearanceWillAppearHere =>
      'AI extracted appearance will appear here...';

  @override
  String get appearanceDescriptionPlaceholder =>
      'e.g., Brown curly hair, green eyes, loves wearing dinosaur t-shirts...';

  @override
  String get skip => 'Skip';

  @override
  String get continueButton => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get step => 'Step';

  @override
  String get ofStep => 'of';

  @override
  String get notesPlaceholder =>
      'e.g., Has a pet dog named Max, loves space and rockets, learning about sharing...';

  @override
  String get yearsOld => 'years old';

  @override
  String get specialNotes => 'Special Notes';
}
