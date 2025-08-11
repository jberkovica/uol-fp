// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Mira Conteuse';

  @override
  String get myTales => 'Mes contes';

  @override
  String get create => 'créer';

  @override
  String get favourites => 'Favoris';

  @override
  String get latest => 'Récents';

  @override
  String kidStories(String kidName) {
    return 'Contes de $kidName';
  }

  @override
  String get noStoriesYet => 'Pas encore de contes';

  @override
  String get profile => 'Profil';

  @override
  String get home => 'Accueil';

  @override
  String get settings => 'Paramètres';

  @override
  String get selectProfile => 'Sélectionner un Profil';

  @override
  String get noProfileSelected => 'Aucun profil sélectionné';

  @override
  String get magicIsHappening => 'La magie opère..';

  @override
  String get uploadYourCreation => 'Téléchargez votre création';

  @override
  String get dragDropHere => 'Glissez-déposez ici';

  @override
  String get or => 'OU';

  @override
  String get browseFile => 'Parcourir';

  @override
  String get generateStory => 'Générer un conte';

  @override
  String get signIn => 'Se Connecter';

  @override
  String get signUp => 'S\'Inscrire';

  @override
  String get email => 'Adresse e-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get logout => 'Se Déconnecter';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ?';

  @override
  String get welcomeBack => 'Bon retour !';

  @override
  String get createYourAccount => 'Créez votre compte';

  @override
  String get parentDashboard => 'Panneau Parental';

  @override
  String get enterPin => 'Entrer le PIN';

  @override
  String failedToLoadStories(String error) {
    return 'Échec du chargement des contes : $error';
  }

  @override
  String get audioRecordingComingSoon =>
      'L\'enregistrement audio sera bientôt disponible !';

  @override
  String get textStoryComingSoon =>
      'La génération de contes texte sera bientôt disponible !';

  @override
  String failedToPickImage(String error) {
    return 'Échec de la sélection d\'image : $error';
  }

  @override
  String failedToGenerateStory(String error) {
    return 'Échec de la génération du conte : $error';
  }

  @override
  String get pleaseEnterName => 'Veuillez entrer un nom';

  @override
  String failedToCreateProfile(String error) {
    return 'Échec de la création du profil : $error';
  }

  @override
  String get editProfileComingSoon =>
      'Modifier le profil sera bientôt disponible !';

  @override
  String get favoritesComingSoon => 'Les favoris seront bientôt disponibles !';

  @override
  String failedToPlayAudio(String error) {
    return 'Échec de la lecture audio : $error';
  }

  @override
  String get incorrectPin => 'PIN incorrect. Veuillez réessayer.';

  @override
  String get accountCreatedSuccessfully =>
      'Compte créé avec succès ! Veuillez vérifier votre e-mail pour vérifier votre compte.';

  @override
  String get appleSignInComingSoon =>
      'La connexion avec Apple sera bientôt disponible !';

  @override
  String get appleSignUpComingSoon =>
      'L\'inscription avec Apple sera bientôt disponible !';

  @override
  String failedToLoadKids(String error) {
    return 'Échec du chargement des enfants : $error';
  }

  @override
  String get addKidProfileFirst =>
      'Veuillez d\'abord ajouter un profil d\'enfant pour créer des contes';

  @override
  String get noKidsProfilesAvailable =>
      'Aucun profil d\'enfant disponible. Ajoutez d\'abord un enfant !';

  @override
  String get changePinComingSoon => 'Changer le PIN sera bientôt disponible !';

  @override
  String get storySettingsComingSoon =>
      'Les paramètres des contes seront bientôt disponibles !';

  @override
  String get exportDataComingSoon =>
      'L\'exportation des données sera bientôt disponible !';

  @override
  String deletingKidProfile(String kidName) {
    return 'Suppression du profil de $kidName...';
  }

  @override
  String kidProfileDeleted(String kidName) {
    return 'Profil de $kidName supprimé avec succès';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Échec de la suppression du profil : $error';
  }

  @override
  String languageUpdatedTo(String language) {
    return 'Langue mise à jour vers $language';
  }

  @override
  String get failedToUpdateLanguage => 'Échec de la mise à jour de la langue';

  @override
  String errorUpdatingLanguage(String error) {
    return 'Erreur lors de la mise à jour de la langue : $error';
  }

  @override
  String get upload => 'télécharger';

  @override
  String get dictate => 'dicter';

  @override
  String get submit => 'soumettre';

  @override
  String get cancel => 'Annuler';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithFacebook => 'Continuer avec Facebook';

  @override
  String get googleSignInFailed => 'Échec de la connexion Google';

  @override
  String get appleSignInFailed => 'Échec de la connexion Apple';

  @override
  String get facebookSignInFailed => 'Échec de la connexion Facebook';

  @override
  String get createAccount => 'Créer un Compte';

  @override
  String get editProfile => 'Modifier le Profil';

  @override
  String get viewStories => 'Voir les Contes';

  @override
  String get deleteProfile => 'Supprimer le Profil';

  @override
  String get addKid => 'Ajouter un Enfant';

  @override
  String get decline => 'Refuser';

  @override
  String get approve => 'Approuver';

  @override
  String get delete => 'Supprimer';

  @override
  String get storyPreview => 'Aperçu du conte';

  @override
  String get exitParentMode => 'Quitter le Mode Parent';

  @override
  String get textSize => 'Taille du Texte';

  @override
  String get backgroundMusic => 'Musique de Fond';

  @override
  String get createAnotherStory => 'Créer un Autre Conte';

  @override
  String get fullNameOptional => 'Nom Complet (Facultatif)';

  @override
  String get enterChildName => 'Entrez le nom de l\'enfant';

  @override
  String get writeYourIdeaHere => 'écrivez votre idée ici...';

  @override
  String get enterFeedbackOrChanges =>
      'Entrez des commentaires ou demandez des modifications...';

  @override
  String get transcribingAudio => 'Transcription audio...';

  @override
  String get changeNameAgeAvatar => 'Changer nom, âge ou avatar';

  @override
  String get switchProfile => 'Changer de Profil';

  @override
  String get changeToDifferentKidProfile =>
      'Changer vers un profil d\'enfant différent';

  @override
  String get favoriteStories => 'Contes Favoris';

  @override
  String get viewYourMostLovedTales => 'Consultez vos contes les plus aimés';

  @override
  String get language => 'Langue';

  @override
  String get changePin => 'Changer le PIN';

  @override
  String get updateParentDashboardPin =>
      'Mettre à jour le PIN du panneau parental';

  @override
  String get currentPin => 'PIN Actuel';

  @override
  String get newPin => 'Nouveau PIN';

  @override
  String get confirmPin => 'Confirmer le PIN';

  @override
  String get enterCurrentPin => 'Entrez votre PIN actuel';

  @override
  String get enterNewPin => 'Entrez votre nouveau PIN';

  @override
  String get confirmNewPin => 'Confirmez votre nouveau PIN';

  @override
  String get pinsDoNotMatch => 'Les PINs ne correspondent pas';

  @override
  String get pinChangedSuccessfully => 'PIN changé avec succès';

  @override
  String get incorrectCurrentPin => 'PIN actuel incorrect';

  @override
  String get storySettings => 'Paramètres des Contes';

  @override
  String get configureStoryGenerationPreferences =>
      'Configurer les préférences de génération de contes';

  @override
  String get exportData => 'Exporter les Données';

  @override
  String get downloadAllStoriesAndData =>
      'Télécharger tous les contes et données';

  @override
  String get noStoryDataAvailable => 'Aucune donnée de conte disponible';

  @override
  String currentFontSize(int size) {
    return 'Actuel : ${size}pt';
  }

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get kidsProfiles => 'Profils d\'Enfants';

  @override
  String get totalStories => 'Total des Contes';

  @override
  String get noKidsProfilesYet => 'Pas Encore de Profils d\'Enfants';

  @override
  String get addFirstKidProfile =>
      'Ajoutez votre premier profil d\'enfant pour commencer avec des contes personnalisés !';

  @override
  String get parentControls => 'Contrôles Parentaux';

  @override
  String get selectLanguage => 'Sélectionner la Langue';

  @override
  String get newStory => 'Nouveau Conte';

  @override
  String stories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'contes',
      one: 'conte',
      zero: 'contes',
    );
    return '$count $_temp0';
  }

  @override
  String createdDate(String date) {
    return 'Créé le $date';
  }

  @override
  String deleteProfileConfirm(String kidName, int storyCount) {
    return 'Êtes-vous sûr de vouloir supprimer le profil de $kidName ? Cela supprimera aussi tous ses $storyCount contes.';
  }

  @override
  String profileDetails(String avatarType) {
    return 'Profil : $avatarType';
  }

  @override
  String creatingStoriesSince(String date) {
    return 'Crée des contes depuis $date';
  }

  @override
  String get storiesCreated => 'Contes Créés';

  @override
  String get wordsWritten => 'Mots Écrits';

  @override
  String get profileOptions => 'Options de Profil';

  @override
  String get changeToDifferentProfile =>
      'Changer vers un profil d\'enfant différent';

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
  String get pleaseEnterEmail => 'Veuillez entrer votre adresse e-mail';

  @override
  String get pleaseEnterValidEmail =>
      'Veuillez entrer une adresse e-mail valide';

  @override
  String get passwordMinLength =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer un mot de passe';

  @override
  String get pleaseConfirmPassword => 'Veuillez confirmer votre mot de passe';

  @override
  String get storyApprovedSuccessfully => 'Conte approuvé avec succès !';

  @override
  String get storyDeclined => 'Conte refusé';

  @override
  String get declineStory => 'Refuser le Conte';

  @override
  String get pleaseProvideReason =>
      'Veuillez fournir une raison pour le refus :';

  @override
  String get declineReasonHint =>
      'Ex., trop effrayant, contenu inapproprié, etc.';

  @override
  String get suggestEdits => 'Suggérer des Modifications';

  @override
  String get provideSuggestions =>
      'Fournissez des suggestions pour améliorer le conte :';

  @override
  String get suggestionsHint =>
      'Ex., le rendre moins effrayant, ajouter plus sur l\'amitié, etc.';

  @override
  String get regeneratingStory =>
      'Régénération du conte avec vos suggestions...';

  @override
  String get regenerateStory => 'Régénérer le Conte';

  @override
  String get imageNotAvailable => 'Image non disponible';

  @override
  String get pendingStories => 'Contes en Attente';

  @override
  String get noPendingStories => 'Aucun conte en attente de révision';

  @override
  String get allStoriesReviewed => 'Tous les contes ont été révisés';

  @override
  String forChild(String childName) {
    return 'Pour $childName';
  }

  @override
  String get review => 'Réviser';

  @override
  String get approvalMethod => 'Méthode d\'Approbation';

  @override
  String get selectApprovalMethod => 'Sélectionner la Méthode d\'Approbation';

  @override
  String get autoApprove => 'Approuver Automatiquement';

  @override
  String get reviewInApp => 'Réviser dans l\'App';

  @override
  String get reviewByEmail => 'Réviser par E-mail';

  @override
  String get autoApproveDescription =>
      'Les contes sont automatiquement approuvés et disponibles immédiatement';

  @override
  String get reviewInAppDescription =>
      'Révisez les contes dans le panneau parental avant de les montrer aux enfants';

  @override
  String get reviewByEmailDescription =>
      'Recevez des notifications par e-mail pour réviser les contes avant approbation';

  @override
  String approvalMethodUpdated(String method) {
    return 'Méthode d\'approbation mise à jour vers $method';
  }

  @override
  String get failedToUpdateApprovalMethod =>
      'Échec de la mise à jour de la méthode d\'approbation';

  @override
  String errorUpdatingApprovalMethod(String error) {
    return 'Erreur lors de la mise à jour de la méthode d\'approbation : $error';
  }

  @override
  String get yourStoryIsReady => 'Votre conte est prêt !';

  @override
  String get parentReviewPending => 'Révision parentale en attente';

  @override
  String get tapReviewToApprove =>
      'Appuyez sur Réviser pour demander l\'approbation parentale';

  @override
  String get weWillNotifyWhenReady =>
      'Nous vous préviendrons quand votre conte sera prêt !';

  @override
  String get openStory => 'ouvrir';

  @override
  String get pleaseEnterText =>
      'Veuillez entrer du texte pour créer votre conte';

  @override
  String get textTooShort =>
      'Veuillez écrire au moins 10 caractères pour votre idée de conte';

  @override
  String get textTooLong =>
      'Le texte est trop long. Veuillez le garder sous 500 caractères';

  @override
  String get pleaseSelectChild => 'Veuillez d\'abord sélectionner un enfant';

  @override
  String get recording => 'Enregistrement';

  @override
  String get stopRecording => 'Arrêter l\'Enregistrement';

  @override
  String get microphonePermissionRequired =>
      'Permission du microphone requise pour enregistrer l\'audio';

  @override
  String get failedToStartRecording =>
      'Échec du démarrage de l\'enregistrement';

  @override
  String get failedToStopRecording => 'Échec de l\'arrêt de l\'enregistrement';

  @override
  String get noRecordingAvailable => 'Aucun enregistrement disponible';

  @override
  String get addNewProfile => 'Ajouter un Nouveau Profil';

  @override
  String get createProfile => 'Créer un Profil';

  @override
  String get createNewProfile => 'Créer un Nouveau Profil';

  @override
  String get addDetailsForChild => 'Ajoutez les détails pour votre enfant';

  @override
  String get basicInformation => 'Informations de Base';

  @override
  String get appearance => 'Apparence';

  @override
  String get appearanceOptional => 'Apparence (Facultatif)';

  @override
  String get personalityPreferences => 'Personnalité et Préférences';

  @override
  String get personalityPreferencesOptional =>
      'Personnalité et Préférences (Facultatif)';

  @override
  String get additionalNotes => 'Notes Supplémentaires';

  @override
  String get additionalNotesOptional => 'Notes Supplémentaires (Facultatif)';

  @override
  String get ageOptional => 'Âge (Facultatif)';

  @override
  String get chooseAvatar => 'Choisir un Avatar';

  @override
  String get hairColor => 'Couleur des Cheveux';

  @override
  String get hairColorOptional => 'Couleur des Cheveux (Facultatif)';

  @override
  String get hairLength => 'Longueur des Cheveux';

  @override
  String get hairLengthOptional => 'Longueur des Cheveux (Facultatif)';

  @override
  String get skinColor => 'Couleur de Peau';

  @override
  String get skinColorOptional => 'Couleur de Peau (Facultatif)';

  @override
  String get eyeColor => 'Couleur des Yeux';

  @override
  String get eyeColorOptional => 'Couleur des Yeux (Facultatif)';

  @override
  String get gender => 'Genre';

  @override
  String get genderOptional => 'Genre (Facultatif)';

  @override
  String get favoriteStoryTypes => 'Types de Contes Favoris';

  @override
  String get favoriteStoryTypesOptional =>
      'Types de Contes Favoris (Facultatif)';

  @override
  String get addSpecialNotes =>
      'Ajoutez des notes spéciales sur votre enfant...';

  @override
  String addSpecialNotesFor(String childName) {
    return 'Ajoutez des notes spéciales sur $childName...';
  }

  @override
  String get saveChanges => 'Sauvegarder les Modifications';

  @override
  String get creating => 'Création...';

  @override
  String failedToUpdateProfile(String error) {
    return 'Échec de la mise à jour du profil : $error';
  }

  @override
  String get setYourParentPin => 'Définir votre PIN Parental';

  @override
  String get createFourDigitPinAccess =>
      'Créez un PIN à 4 chiffres pour accéder\nau panneau parental et aux paramètres';

  @override
  String get settingUpYourPin => 'Configuration de votre PIN...';

  @override
  String get thisWillBeUsedForAccess =>
      'Ce PIN sera utilisé pour accéder aux paramètres parentaux et approuver les contes pour vos enfants.';

  @override
  String get pleaseEnterAllFourDigits => 'Veuillez entrer les 4 chiffres';

  @override
  String get failedToSetPin =>
      'Échec de la définition du PIN. Veuillez réessayer.';

  @override
  String get tapToStartRecording => 'Appuyez pour commencer l\'enregistrement';

  @override
  String get pauseRecording => 'Pause l\'enregistrement';

  @override
  String get startOver => 'Recommencer';

  @override
  String get playAudio => 'Lire l\'audio';

  @override
  String get pauseAudio => 'Pause l\'audio';

  @override
  String get submitForTranscription => 'Soumettre pour transcription';

  @override
  String get dictateAgain => 'Dicter à Nouveau';

  @override
  String get editAsText => 'Modifier comme Texte';

  @override
  String get selectImageSource => 'Sélectionner la Source d\'Image';

  @override
  String get takePhoto => 'Prendre une Photo';

  @override
  String get chooseFromGallery => 'Choisir dans la Galerie';

  @override
  String get switchToText => 'Passer au Texte';

  @override
  String get camera => 'appareil photo';

  @override
  String get gallery => 'galerie';

  @override
  String get age => 'Âge';

  @override
  String get appearanceOptionalSection => 'Apparence (Facultatif)';

  @override
  String get appearanceDescription =>
      'Décrivez à quoi ressemble votre enfant pour aider à créer des contes personnalisés.';

  @override
  String get appearanceMethodQuestion =>
      'Comment souhaitez-vous décrire l\'apparence ?';

  @override
  String get describeInWords => 'Décrire avec des mots';

  @override
  String get uploadPhoto => 'Télécharger une photo';

  @override
  String get aiWillAnalyzePhoto =>
      'L\'IA analysera la photo et créera une description';

  @override
  String get extractingAppearance => 'Extraction de l\'apparence...';

  @override
  String get aiExtractedDescription =>
      'L\'IA a extrait cette description de votre photo. N\'hésitez pas à la réviser et l\'éditer.';

  @override
  String get appearanceExamplePlaceholder =>
      'Exemple : \"Cheveux bouclés bruns, yeux verts brillants et un sourire avec un écart entre les dents\"';

  @override
  String get appearancePhotoPlaceholder =>
      'Téléchargez une photo ci-dessus pour générer automatiquement la description, ou tapez manuellement';

  @override
  String get appearanceHelperText =>
      'Décrivez les cheveux, les yeux, les traits distinctifs, etc. Cela aide à créer des contes personnalisés.';

  @override
  String get aiGeneratedHelperText =>
      'Vous pouvez éditer cette description générée par IA pour la rendre plus personnelle.';

  @override
  String get storyPreferencesOptional => 'Préférences de Contes (Facultatif)';

  @override
  String get preferredLanguage => 'Langue Préférée';

  @override
  String get parentNotesOptional => 'Notes Parentales (Facultatif)';

  @override
  String get parentNotesDescription =>
      'Ajoutez un contexte spécial pour les contes : loisirs, animaux de compagnie, frères et sœurs, intérêts, etc.';

  @override
  String get parentNotesExample =>
      'Exemple : Aime les dinosaures, a un chat nommé Moustaches...';

  @override
  String get ageRequired => 'Âge (Requis)';

  @override
  String get appearanceExtractedSuccess =>
      'Apparence extraite ! Vous pouvez réviser et éditer la description ci-dessous.';

  @override
  String failedToExtractAppearance(String error) {
    return 'Échec de l\'extraction de l\'apparence : $error';
  }

  @override
  String get genreAdventure => 'Aventure';

  @override
  String get genreFantasy => 'Fantastique';

  @override
  String get genreFriendship => 'Amitié';

  @override
  String get genreFamily => 'Famille';

  @override
  String get genreAnimals => 'Animaux';

  @override
  String get genreMagic => 'Magie';

  @override
  String get genreSpace => 'Espace';

  @override
  String get genreUnderwater => 'Sous-marin';

  @override
  String get genreForest => 'Forêt';

  @override
  String get genreFairyTale => 'Conte de fées';

  @override
  String get genreSuperhero => 'Super-héros';

  @override
  String get genreDinosaurs => 'Dinosaures';

  @override
  String get genrePirates => 'Pirates';

  @override
  String get genrePrincess => 'Princesse';

  @override
  String get genreDragons => 'Dragons';

  @override
  String get genreRobots => 'Robots';

  @override
  String get genreMystery => 'Mystère';

  @override
  String get genreFunny => 'Drôle';

  @override
  String get genreEducational => 'Éducatif';

  @override
  String get genreBedtime => 'Contes du soir';

  @override
  String get wizardNameTitle => 'Comment s\'appelle votre petit?';

  @override
  String get wizardNameSubtitle => 'Ce nom sera utilisé dans les histoires';

  @override
  String get wizardAgeTitle => 'Quel âge a votre enfant?';

  @override
  String get wizardAgeSubtitle =>
      'Cela nous aidera à choisir des histoires appropriées';

  @override
  String get wizardGenderTitle => 'Sélectionnez le genre de l\'enfant';

  @override
  String get wizardGenderSubtitle =>
      'Cela aidera à créer des histoires plus personnalisées';

  @override
  String get wizardAppearanceTitle => 'À quoi ressemble votre enfant?';

  @override
  String get wizardAppearanceSubtitle =>
      'Décrivez son apparence ou téléchargez une photo';

  @override
  String get wizardGenresTitle => 'Quelles histoires votre enfant aime-t-il?';

  @override
  String get wizardGenresSubtitle => 'Choisissez les genres préférés';

  @override
  String get wizardNotesTitle => 'Notes spéciales';

  @override
  String get wizardNotesSubtitle =>
      'Ajoutez du contexte: loisirs, intérêts, animaux domestiques';

  @override
  String get wizardReviewTitle => 'Vérifiez les informations';

  @override
  String get wizardReviewSubtitle => 'Assurez-vous que tout est correct';

  @override
  String get enterName => 'Entrez le nom';

  @override
  String get chooseAnAvatar => 'Choisissez un avatar';

  @override
  String get boy => 'Garçon';

  @override
  String get girl => 'Fille';

  @override
  String get preferNotToSay => 'Préfère ne pas spécifier';

  @override
  String stepOfSteps(int currentStep, int totalSteps) {
    return 'Étape $currentStep de $totalSteps';
  }

  @override
  String get parentNotesHintText =>
      'ex.: A un chien nommé Max, aime l\'espace et les fusées, apprend à partager...';

  @override
  String get describe => 'Décrire';

  @override
  String get analyzing => 'Analyse en cours...';

  @override
  String get aiExtractedAppearanceWillAppearHere =>
      'L\'IA extraira la description de l\'apparence de la photo';

  @override
  String get appearanceDescriptionPlaceholder =>
      'Par exemple: yeux bruns, cheveux foncés, taches de rousseur';

  @override
  String get skip => 'Ignorer';

  @override
  String get continueButton => 'Continuer';

  @override
  String get back => 'Retour';

  @override
  String get step => 'Étape';

  @override
  String get ofStep => 'de';

  @override
  String get notesPlaceholder =>
      'Par exemple: aime les dinosaures, a peur du noir, a un petit frère';

  @override
  String get yearsOld => 'ans';

  @override
  String get specialNotes => 'Notes spéciales';
}
