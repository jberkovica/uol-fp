import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get appTitle => 'Mira Stāstniece';

  @override
  String get myTales => 'Mani stāsti';

  @override
  String get create => 'izveidot';

  @override
  String get favourites => 'Mīļākie';

  @override
  String get latest => 'Jaunākie';

  @override
  String kidStories(String kidName) {
    return '$kidName stāsti';
  }

  @override
  String get noStoriesYet => 'Pagaidām nav stāstu';

  @override
  String get profile => 'Profils';

  @override
  String get home => 'Sākums';

  @override
  String get settings => 'Iestatījumi';

  @override
  String get selectProfile => 'Izvēlieties profilu';

  @override
  String get noProfileSelected => 'Nav izvēlēts profils';

  @override
  String get magicIsHappening => 'Notiek brīnums..';

  @override
  String get uploadYourCreation => 'Augšupielādējiet savu darbu';

  @override
  String get dragDropHere => 'Velciet un nometiet šeit';

  @override
  String get or => 'VAI';

  @override
  String get browseFile => 'Izvēlēties failu';

  @override
  String get generateStory => 'Izveidot stāstu';

  @override
  String get signIn => 'Ieiet';

  @override
  String get signUp => 'Reģistrēties';

  @override
  String get email => 'E-pasts';

  @override
  String get password => 'Parole';

  @override
  String get confirmPassword => 'Apstipriniet paroli';

  @override
  String get forgotPassword => 'Aizmirsāt paroli?';

  @override
  String get alreadyHaveAccount => 'Jau ir konts?';

  @override
  String get logout => 'Iziet no konta';

  @override
  String get dontHaveAccount => 'Nav konta?';

  @override
  String get welcomeBack => 'Laipni lūdzam atpakaļ!';

  @override
  String get createYourAccount => 'Izveidojiet savu kontu';

  @override
  String get parentDashboard => 'Vecāku panelis';

  @override
  String get enterPin => 'Ievadiet PIN';

  @override
  String failedToLoadStories(String error) {
    return 'Neizdevās ielādēt stāstus: $error';
  }

  @override
  String get audioRecordingComingSoon => 'Audio ierakstīšana drīz būs pieejama!';

  @override
  String get textStoryComingSoon => 'Teksta stāstu ģenerēšana drīz būs pieejama!';

  @override
  String failedToPickImage(String error) {
    return 'Neizdevās izvēlēties attēlu: $error';
  }

  @override
  String failedToGenerateStory(String error) {
    return 'Neizdevās izveidot stāstu: $error';
  }

  @override
  String get pleaseEnterName => 'Lūdzu, ievadiet vārdu';

  @override
  String failedToCreateProfile(String error) {
    return 'Neizdevās izveidot profilu: $error';
  }

  @override
  String get editProfileComingSoon => 'Profila rediģēšana drīz būs pieejama!';

  @override
  String get favoritesComingSoon => 'Izlase drīz būs pieejama!';

  @override
  String failedToPlayAudio(String error) {
    return 'Neizdevās atskaņot audio: $error';
  }

  @override
  String get incorrectPin => 'Nepareizs PIN. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get accountCreatedSuccessfully => 'Konts veiksmīgi izveidots! Pārbaudiet savu e-pastu, lai apstiprinātu kontu.';

  @override
  String get appleSignInComingSoon => 'Pierakstīšanās ar Apple drīz būs pieejama!';

  @override
  String get appleSignUpComingSoon => 'Reģistrācija ar Apple drīz būs pieejama!';

  @override
  String failedToLoadKids(String error) {
    return 'Neizdevās ielādēt bērnus: $error';
  }

  @override
  String get addKidProfileFirst => 'Vispirms pievienojiet bērna profilu, lai izveidotu stāstus';

  @override
  String get noKidsProfilesAvailable => 'Nav bērnu profilu. Vispirms pievienojiet bērnu!';

  @override
  String get changePinComingSoon => 'PIN maiņa drīz būs pieejama!';

  @override
  String get storySettingsComingSoon => 'Stāstu iestatījumi drīz būs pieejami!';

  @override
  String get exportDataComingSoon => 'Datu eksports drīz būs pieejams!';

  @override
  String deletingKidProfile(String kidName) {
    return 'Dzēš $kidName profilu...';
  }

  @override
  String kidProfileDeleted(String kidName) {
    return '$kidName profils veiksmīgi dzēsts';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Neizdevās dzēst profilu: $error';
  }

  @override
  String languageUpdatedTo(String language) {
    return 'Valoda mainīta uz $language';
  }

  @override
  String get failedToUpdateLanguage => 'Neizdevās mainīt valodu';

  @override
  String errorUpdatingLanguage(String error) {
    return 'Kļūda mainot valodu: $error';
  }

  @override
  String get upload => 'augšupielādēt';

  @override
  String get dictate => 'diktēt';

  @override
  String get submit => 'iesniegt';

  @override
  String get cancel => 'Atcelt';

  @override
  String get continueWithGoogle => 'Turpināt ar Google';

  @override
  String get continueWithApple => 'Turpināt ar Apple';

  @override
  String get continueWithFacebook => 'Turpināt ar Facebook';

  @override
  String get googleSignInFailed => 'Google pierakstīšanās neizdevās';

  @override
  String get appleSignInFailed => 'Apple pierakstīšanās neizdevās';

  @override
  String get facebookSignInFailed => 'Facebook pierakstīšanās neizdevās';

  @override
  String get createAccount => 'Izveidot kontu';

  @override
  String get editProfile => 'Rediģēt profilu';

  @override
  String get viewStories => 'Skatīt stāstus';

  @override
  String get deleteProfile => 'Dzēst profilu';

  @override
  String get addKid => 'Pievienot bērnu';

  @override
  String get decline => 'Noraidīt';

  @override
  String get approve => 'Apstiprināt';

  @override
  String get delete => 'Dzēst';

  @override
  String get storyPreview => 'Stāsta priekšskatījums';

  @override
  String get exitParentMode => 'Iziet no vecāku režīma';

  @override
  String get textSize => 'Teksta izmērs';

  @override
  String get backgroundMusic => 'Fona mūzika';

  @override
  String get createAnotherStory => 'Izveidot vēl vienu stāstu';

  @override
  String get fullNameOptional => 'Pilns vārds (neobligāti)';

  @override
  String get enterChildName => 'Ievadiet bērna vārdu';

  @override
  String get writeYourIdeaHere => 'rakstiet savu ideju šeit...';

  @override
  String get enterFeedbackOrChanges => 'Ievadiet atsauksmes vai pieprasiet izmaiņas...';

  @override
  String get changeNameAgeAvatar => 'Mainīt vārdu, vecumu vai avatāru';

  @override
  String get switchProfile => 'Mainīt profilu';

  @override
  String get changeToDifferentKidProfile => 'Pārslēgties uz citu bērna profilu';

  @override
  String get favoriteStories => 'Mīļākie stāsti';

  @override
  String get viewYourMostLovedTales => 'Skatiet savus vismīļākos stāstus';

  @override
  String get language => 'Valoda';

  @override
  String get changePin => 'Mainīt PIN';

  @override
  String get updateParentDashboardPin => 'Atjaunināt vecāku paneļa PIN';

  @override
  String get storySettings => 'Stāstu iestatījumi';

  @override
  String get configureStoryGenerationPreferences => 'Konfigurēt stāstu ģenerēšanas preferences';

  @override
  String get exportData => 'Eksportēt datus';

  @override
  String get downloadAllStoriesAndData => 'Lejupielādēt visus stāstus un datus';

  @override
  String get noStoryDataAvailable => 'Stāsta dati nav pieejami';

  @override
  String currentFontSize(int size) {
    return 'Pašreizējais: ${size}pt';
  }

  @override
  String get enabled => 'Ieslēgts';

  @override
  String get disabled => 'Izslēgts';

  @override
  String get kidsProfiles => 'Bērnu profili';

  @override
  String get totalStories => 'Kopā stāstu';

  @override
  String get noKidsProfilesYet => 'Pagaidām nav bērnu profilu';

  @override
  String get addFirstKidProfile => 'Pievienojiet pirmo bērna profilu personalizētiem stāstiem!';

  @override
  String get parentControls => 'Vecāku kontrole';

  @override
  String get selectLanguage => 'Izvēlieties valodu';

  @override
  String get newStory => 'Jauns stāsts';

  @override
  String stories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'stāsti',
      one: 'stāsts',
      zero: 'stāstu',
    );
    return '$count $_temp0';
  }

  @override
  String createdDate(String date) {
    return 'Izveidots $date';
  }

  @override
  String deleteProfileConfirm(String kidName, int storyCount) {
    return 'Vai tiešām vēlaties dzēst $kidName profilu? Tas arī dzēsīs visus $storyCount stāstus.';
  }

  @override
  String profileDetails(String avatarType) {
    return 'Profils: $avatarType';
  }

  @override
  String creatingStoriesSince(String date) {
    return 'Rada stāstus kopš $date';
  }

  @override
  String get storiesCreated => 'Stāsti izveidoti';

  @override
  String get wordsWritten => 'Vārdi uzrakstīti';

  @override
  String get profileOptions => 'Profila opcijas';

  @override
  String get changeToDifferentProfile => 'Pārslēgties uz citu bērna profilu';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get latvian => 'Latviešu';

  @override
  String get pleaseEnterEmail => 'Lūdzu, ievadiet savu e-pastu';

  @override
  String get pleaseEnterValidEmail => 'Lūdzu, ievadiet derīgu e-pastu';

  @override
  String get passwordMinLength => 'Parolei jābūt vismaz 6 simbolu garai';

  @override
  String get passwordsDoNotMatch => 'Paroles nesakrīt';

  @override
  String get pleaseEnterPassword => 'Lūdzu, ievadiet paroli';

  @override
  String get pleaseConfirmPassword => 'Lūdzu, apstipriniet paroli';

  @override
  String get storyApprovedSuccessfully => 'Stāsts veiksmīgi apstiprināts!';

  @override
  String get storyDeclined => 'Stāsts noraidīts';

  @override
  String get declineStory => 'Noraidīt stāstu';

  @override
  String get pleaseProvideReason => 'Lūdzu, norādiet noraidīšanas iemeslu:';

  @override
  String get declineReasonHint => 'Piemēram, pārāk baidoši, nepiedienīgs saturs utt.';

  @override
  String get suggestEdits => 'Ieteikt izmaiņas';

  @override
  String get provideSuggestions => 'Sniedziet ieteikumus stāsta uzlabošanai:';

  @override
  String get suggestionsHint => 'Piemēram, padarīt mazāk baidošu, pievienot vairāk par draudzību utt.';

  @override
  String get regeneratingStory => 'Izveidojam jaunu stāsta versiju ar jūsu ieteikumiem...';

  @override
  String get regenerateStory => 'Izveidot jaunu versiju';

  @override
  String get imageNotAvailable => 'Attēls nav pieejams';

  @override
  String get pendingStories => 'Gaida apstiprinājumu';

  @override
  String get noPendingStories => 'Nav stāstu, kas gaida apstiprinājumu';

  @override
  String get allStoriesReviewed => 'Visi stāsti ir pārskatīti';

  @override
  String forChild(String childName) {
    return 'Priekš $childName';
  }

  @override
  String get review => 'Pārskatīt';

  @override
  String get approvalMethod => 'Apstiprinājuma veids';

  @override
  String get selectApprovalMethod => 'Izvēlieties apstiprinājuma veidu';

  @override
  String get autoApprove => 'Automātiski apstiprināt';

  @override
  String get reviewInApp => 'Pārskatīt lietotnē';

  @override
  String get reviewByEmail => 'Pārskatīt pa e-pastu';

  @override
  String get autoApproveDescription => 'Stāsti tiek automātiski apstiprināti un uzreiz pieejami';

  @override
  String get reviewInAppDescription => 'Pārskatiet stāstus vecāku panelī, pirms tie tiek rādīti bērniem';

  @override
  String get reviewByEmailDescription => 'Saņemiet e-pasta paziņojumus, lai pārskatītu stāstus pirms apstiprināšanas';

  @override
  String approvalMethodUpdated(String method) {
    return 'Apstiprinājuma veids nomainīts uz $method';
  }

  @override
  String get failedToUpdateApprovalMethod => 'Neizdevās nomainīt apstiprinājuma veidu';

  @override
  String errorUpdatingApprovalMethod(String error) {
    return 'Kļūda mainot apstiprinājuma veidu: $error';
  }

  @override
  String get yourStoryIsReady => 'Tavs stāsts ir gatavs! 🎉';

  @override
  String get parentReviewPending => 'Gaida vecāku apstiprinājumu 👨‍👩‍👧‍👦';

  @override
  String get tapReviewToApprove => 'Nospied Pārskatīt, lai lūgtu vecāku apstiprinājumu';

  @override
  String get weWillNotifyWhenReady => 'Mēs paziņosim, kad tavs stāsts būs gatavs!';

  @override
  String get openStory => 'Atvērt stāstu';

  @override
  String get pleaseEnterText => 'Lūdzu, ievadiet tekstu, lai izveidotu stāstu';

  @override
  String get textTooShort => 'Lūdzu, uzrakstiet vismaz 10 simbolus savas stāsta idejas aprakstam';

  @override
  String get textTooLong => 'Teksts ir pārāk garš. Lūdzu, ierobežojiet to līdz 500 simboliem';

  @override
  String get pleaseSelectChild => 'Lūdzu, vispirms izvēlieties bērnu';

  @override
  String get recording => 'Ierakstīšana';

  @override
  String get stopRecording => 'Beigt ierakstīšanu';

  @override
  String get microphonePermissionRequired => 'Mikrofonam ir nepieciešama atļauja audio ierakstīšanai';

  @override
  String get failedToStartRecording => 'Neizdevās sākt ierakstīšanu';

  @override
  String get failedToStopRecording => 'Neizdevās beigt ierakstīšanu';

  @override
  String get noRecordingAvailable => 'Ieraksts nav pieejams';
}
