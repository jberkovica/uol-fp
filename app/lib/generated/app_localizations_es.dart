// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mira Cuentacuentos';

  @override
  String get myTales => 'Mis cuentos';

  @override
  String get create => 'crear';

  @override
  String get favourites => 'Favoritos';

  @override
  String get latest => 'Recientes';

  @override
  String kidStories(String kidName) {
    return 'Cuentos de $kidName';
  }

  @override
  String get noStoriesYet => 'Aún no hay cuentos';

  @override
  String get profile => 'Perfil';

  @override
  String get home => 'Inicio';

  @override
  String get settings => 'Configuración';

  @override
  String get selectProfile => 'Seleccionar Perfil';

  @override
  String get noProfileSelected => 'No se ha seleccionado perfil';

  @override
  String get magicIsHappening => 'La magia está ocurriendo..';

  @override
  String get uploadYourCreation => 'Sube tu creación';

  @override
  String get dragDropHere => 'Arrastra y suelta aquí';

  @override
  String get or => 'O';

  @override
  String get browseFile => 'Buscar archivo';

  @override
  String get generateStory => 'Generar cuento';

  @override
  String get signIn => 'Iniciar Sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get dontHaveAccount => '¿No tienes cuenta?';

  @override
  String get welcomeBack => '¡Bienvenido de vuelta!';

  @override
  String get createYourAccount => 'Crea tu cuenta';

  @override
  String get parentDashboard => 'Panel de Padres';

  @override
  String get enterPin => 'Introduce PIN';

  @override
  String failedToLoadStories(String error) {
    return 'Error al cargar cuentos: $error';
  }

  @override
  String get audioRecordingComingSoon =>
      '¡La grabación de audio estará disponible pronto!';

  @override
  String get textStoryComingSoon =>
      '¡La generación de cuentos de texto estará disponible pronto!';

  @override
  String failedToPickImage(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String failedToGenerateStory(String error) {
    return 'Error al generar cuento: $error';
  }

  @override
  String get pleaseEnterName => 'Por favor, introduce un nombre';

  @override
  String failedToCreateProfile(String error) {
    return 'Error al crear perfil: $error';
  }

  @override
  String get editProfileComingSoon =>
      '¡Editar perfil estará disponible pronto!';

  @override
  String get favoritesComingSoon => '¡Favoritos estará disponible pronto!';

  @override
  String failedToPlayAudio(String error) {
    return 'Error al reproducir audio: $error';
  }

  @override
  String get incorrectPin => 'PIN incorrecto. Inténtalo de nuevo.';

  @override
  String get accountCreatedSuccessfully =>
      '¡Cuenta creada exitosamente! Por favor, revisa tu correo para verificar tu cuenta.';

  @override
  String get appleSignInComingSoon =>
      '¡Iniciar sesión con Apple estará disponible pronto!';

  @override
  String get appleSignUpComingSoon =>
      '¡Registro con Apple estará disponible pronto!';

  @override
  String failedToLoadKids(String error) {
    return 'Error al cargar niños: $error';
  }

  @override
  String get addKidProfileFirst =>
      'Por favor, agrega primero un perfil de niño para crear cuentos';

  @override
  String get noKidsProfilesAvailable =>
      'No hay perfiles de niños disponibles. ¡Agrega un niño primero!';

  @override
  String get changePinComingSoon => '¡Cambiar PIN estará disponible pronto!';

  @override
  String get storySettingsComingSoon =>
      '¡Configuración de cuentos estará disponible pronto!';

  @override
  String get exportDataComingSoon =>
      '¡Exportar datos estará disponible pronto!';

  @override
  String deletingKidProfile(String kidName) {
    return 'Eliminando perfil de $kidName...';
  }

  @override
  String kidProfileDeleted(String kidName) {
    return 'Perfil de $kidName eliminado exitosamente';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Error al eliminar perfil: $error';
  }

  @override
  String languageUpdatedTo(String language) {
    return 'Idioma actualizado a $language';
  }

  @override
  String get failedToUpdateLanguage => 'Error al actualizar idioma';

  @override
  String errorUpdatingLanguage(String error) {
    return 'Error al actualizar idioma: $error';
  }

  @override
  String get upload => 'subir';

  @override
  String get dictate => 'dictar';

  @override
  String get submit => 'enviar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get continueWithFacebook => 'Continuar con Facebook';

  @override
  String get googleSignInFailed => 'Error al iniciar sesión con Google';

  @override
  String get appleSignInFailed => 'Error al iniciar sesión con Apple';

  @override
  String get facebookSignInFailed => 'Error al iniciar sesión con Facebook';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get viewStories => 'Ver Cuentos';

  @override
  String get deleteProfile => 'Eliminar Perfil';

  @override
  String get addKid => 'Agregar Niño';

  @override
  String get decline => 'Rechazar';

  @override
  String get approve => 'Aprobar';

  @override
  String get delete => 'Eliminar';

  @override
  String get storyPreview => 'Vista previa del cuento';

  @override
  String get exitParentMode => 'Salir del Modo Padres';

  @override
  String get textSize => 'Tamaño del Texto';

  @override
  String get backgroundMusic => 'Música de Fondo';

  @override
  String get createAnotherStory => 'Crear Otro Cuento';

  @override
  String get fullNameOptional => 'Nombre Completo (Opcional)';

  @override
  String get enterChildName => 'Introduce el nombre del niño';

  @override
  String get writeYourIdeaHere => 'escribe tu idea aquí...';

  @override
  String get enterFeedbackOrChanges =>
      'Introduce comentarios o solicita cambios...';

  @override
  String get transcribingAudio => 'Transcribiendo audio...';

  @override
  String get changeNameAgeAvatar => 'Cambiar nombre, edad o avatar';

  @override
  String get switchProfile => 'Cambiar Perfil';

  @override
  String get changeToDifferentKidProfile =>
      'Cambiar a un perfil de niño diferente';

  @override
  String get favoriteStories => 'Cuentos Favoritos';

  @override
  String get viewYourMostLovedTales => 'Ve tus cuentos más queridos';

  @override
  String get language => 'Idioma';

  @override
  String get changePin => 'Cambiar PIN';

  @override
  String get updateParentDashboardPin => 'Actualizar PIN del panel de padres';

  @override
  String get currentPin => 'PIN Actual';

  @override
  String get newPin => 'Nuevo PIN';

  @override
  String get confirmPin => 'Confirmar PIN';

  @override
  String get enterCurrentPin => 'Introduce tu PIN actual';

  @override
  String get enterNewPin => 'Introduce tu nuevo PIN';

  @override
  String get confirmNewPin => 'Confirma tu nuevo PIN';

  @override
  String get pinsDoNotMatch => 'Los PINs no coinciden';

  @override
  String get pinChangedSuccessfully => 'PIN cambiado exitosamente';

  @override
  String get incorrectCurrentPin => 'PIN actual incorrecto';

  @override
  String get storySettings => 'Configuración de Cuentos';

  @override
  String get configureStoryGenerationPreferences =>
      'Configurar preferencias de generación de cuentos';

  @override
  String get exportData => 'Exportar Datos';

  @override
  String get downloadAllStoriesAndData => 'Descargar todos los cuentos y datos';

  @override
  String get noStoryDataAvailable => 'No hay datos de cuento disponibles';

  @override
  String currentFontSize(int size) {
    return 'Actual: ${size}pt';
  }

  @override
  String get enabled => 'Habilitado';

  @override
  String get disabled => 'Deshabilitado';

  @override
  String get kidsProfiles => 'Perfiles de Niños';

  @override
  String get totalStories => 'Total de Cuentos';

  @override
  String get noKidsProfilesYet => 'Aún No Hay Perfiles de Niños';

  @override
  String get addFirstKidProfile =>
      '¡Agrega tu primer perfil de niño para comenzar con cuentos personalizados!';

  @override
  String get parentControls => 'Controles Parentales';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get newStory => 'Nuevo Cuento';

  @override
  String stories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cuentos',
      one: 'cuento',
      zero: 'cuentos',
    );
    return '$count $_temp0';
  }

  @override
  String createdDate(String date) {
    return 'Creado $date';
  }

  @override
  String deleteProfileConfirm(String kidName, int storyCount) {
    return '¿Estás seguro de que quieres eliminar el perfil de $kidName? Esto también eliminará todos sus $storyCount cuentos.';
  }

  @override
  String profileDetails(String avatarType) {
    return 'Perfil: $avatarType';
  }

  @override
  String creatingStoriesSince(String date) {
    return 'Creando cuentos desde $date';
  }

  @override
  String get storiesCreated => 'Cuentos Creados';

  @override
  String get wordsWritten => 'Palabras Escritas';

  @override
  String get profileOptions => 'Opciones de Perfil';

  @override
  String get changeToDifferentProfile =>
      'Cambiar a un perfil de niño diferente';

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
  String get pleaseEnterEmail => 'Por favor, introduce tu correo electrónico';

  @override
  String get pleaseEnterValidEmail =>
      'Por favor, introduce un correo electrónico válido';

  @override
  String get passwordMinLength =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get pleaseEnterPassword => 'Por favor, introduce una contraseña';

  @override
  String get pleaseConfirmPassword => 'Por favor, confirma tu contraseña';

  @override
  String get storyApprovedSuccessfully => '¡Cuento aprobado exitosamente!';

  @override
  String get storyDeclined => 'Cuento rechazado';

  @override
  String get declineStory => 'Rechazar Cuento';

  @override
  String get pleaseProvideReason =>
      'Por favor, proporciona una razón para rechazar:';

  @override
  String get declineReasonHint =>
      'Ej., demasiado asustadizo, contenido inapropiado, etc.';

  @override
  String get suggestEdits => 'Sugerir Ediciones';

  @override
  String get provideSuggestions =>
      'Proporciona sugerencias para mejorar el cuento:';

  @override
  String get suggestionsHint =>
      'Ej., hacerlo menos asustadizo, agregar más sobre amistad, etc.';

  @override
  String get regeneratingStory => 'Regenerando cuento con tus sugerencias...';

  @override
  String get regenerateStory => 'Regenerar Cuento';

  @override
  String get imageNotAvailable => 'Imagen no disponible';

  @override
  String get pendingStories => 'Cuentos Pendientes';

  @override
  String get noPendingStories => 'No hay cuentos pendientes de revisión';

  @override
  String get allStoriesReviewed => 'Todos los cuentos han sido revisados';

  @override
  String forChild(String childName) {
    return 'Para $childName';
  }

  @override
  String get review => 'Revisar';

  @override
  String get approvalMethod => 'Método de Aprobación';

  @override
  String get selectApprovalMethod => 'Seleccionar Método de Aprobación';

  @override
  String get autoApprove => 'Aprobar Automáticamente';

  @override
  String get reviewInApp => 'Revisar en la App';

  @override
  String get reviewByEmail => 'Revisar por Correo';

  @override
  String get autoApproveDescription =>
      'Los cuentos se aprueban automáticamente y están disponibles inmediatamente';

  @override
  String get reviewInAppDescription =>
      'Revisa cuentos en el panel de padres antes de mostrarlos a los niños';

  @override
  String get reviewByEmailDescription =>
      'Recibe notificaciones por correo para revisar cuentos antes de aprobarlos';

  @override
  String approvalMethodUpdated(String method) {
    return 'Método de aprobación actualizado a $method';
  }

  @override
  String get failedToUpdateApprovalMethod =>
      'Error al actualizar método de aprobación';

  @override
  String errorUpdatingApprovalMethod(String error) {
    return 'Error al actualizar método de aprobación: $error';
  }

  @override
  String get yourStoryIsReady => '¡Tu cuento está listo!';

  @override
  String get parentReviewPending => 'Revisión de padres pendiente';

  @override
  String get tapReviewToApprove =>
      'Toca Revisar para pedir aprobación de los padres';

  @override
  String get weWillNotifyWhenReady =>
      '¡Te avisaremos cuando tu cuento esté listo!';

  @override
  String get openStory => 'abrir';

  @override
  String get pleaseEnterText =>
      'Por favor, introduce texto para crear tu cuento';

  @override
  String get textTooShort =>
      'Por favor, escribe al menos 10 caracteres para tu idea de cuento';

  @override
  String get textTooLong =>
      'El texto es demasiado largo. Por favor, manténlo bajo 500 caracteres';

  @override
  String get pleaseSelectChild => 'Por favor, selecciona un niño primero';

  @override
  String get recording => 'Grabando';

  @override
  String get stopRecording => 'Parar Grabación';

  @override
  String get microphonePermissionRequired =>
      'Se requiere permiso del micrófono para grabar audio';

  @override
  String get failedToStartRecording => 'Error al iniciar grabación';

  @override
  String get failedToStopRecording => 'Error al parar grabación';

  @override
  String get noRecordingAvailable => 'No hay grabación disponible';

  @override
  String get addNewProfile => 'Agregar Nuevo Perfil';

  @override
  String get createProfile => 'Crear Perfil';

  @override
  String get createNewProfile => 'Crear Nuevo Perfil';

  @override
  String get addDetailsForChild => 'Agrega detalles para tu niño';

  @override
  String get basicInformation => 'Información Básica';

  @override
  String get appearance => 'Apariencia';

  @override
  String get appearanceOptional => 'Apariencia (Opcional)';

  @override
  String get personalityPreferences => 'Personalidad y Preferencias';

  @override
  String get personalityPreferencesOptional =>
      'Personalidad y Preferencias (Opcional)';

  @override
  String get additionalNotes => 'Notas Adicionales';

  @override
  String get additionalNotesOptional => 'Notas Adicionales (Opcional)';

  @override
  String get ageOptional => 'Edad (Opcional)';

  @override
  String get chooseAvatar => 'Elegir Avatar';

  @override
  String get hairColor => 'Color de Cabello';

  @override
  String get hairColorOptional => 'Color de Cabello (Opcional)';

  @override
  String get hairLength => 'Largo de Cabello';

  @override
  String get hairLengthOptional => 'Largo de Cabello (Opcional)';

  @override
  String get skinColor => 'Color de Piel';

  @override
  String get skinColorOptional => 'Color de Piel (Opcional)';

  @override
  String get eyeColor => 'Color de Ojos';

  @override
  String get eyeColorOptional => 'Color de Ojos (Opcional)';

  @override
  String get gender => 'Género';

  @override
  String get genderOptional => 'Género (Opcional)';

  @override
  String get favoriteStoryTypes => 'Tipos de Cuentos Favoritos';

  @override
  String get favoriteStoryTypesOptional =>
      'Tipos de Cuentos Favoritos (Opcional)';

  @override
  String get addSpecialNotes =>
      'Agrega cualquier nota especial sobre tu niño...';

  @override
  String addSpecialNotesFor(String childName) {
    return 'Agrega cualquier nota especial sobre $childName...';
  }

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get creating => 'Creando...';

  @override
  String failedToUpdateProfile(String error) {
    return 'Error al actualizar perfil: $error';
  }

  @override
  String get setYourParentPin => 'Establecer PIN de Padres';

  @override
  String get createFourDigitPinAccess =>
      'Crea un PIN de 4 dígitos para acceder\nal panel de padres y configuración';

  @override
  String get settingUpYourPin => 'Configurando tu PIN...';

  @override
  String get thisWillBeUsedForAccess =>
      'Este PIN se usará para acceder a la configuración de padres y aprobar cuentos para tus niños.';

  @override
  String get pleaseEnterAllFourDigits => 'Por favor, introduce los 4 dígitos';

  @override
  String get failedToSetPin =>
      'Error al establecer PIN. Por favor, inténtalo de nuevo.';

  @override
  String get tapToStartRecording => 'Toca para iniciar grabación';

  @override
  String get pauseRecording => 'Pausar grabación';

  @override
  String get startOver => 'Empezar de nuevo';

  @override
  String get playAudio => 'Reproducir audio';

  @override
  String get pauseAudio => 'Pausar audio';

  @override
  String get submitForTranscription => 'Enviar para transcripción';

  @override
  String get dictateAgain => 'Dictar de Nuevo';

  @override
  String get editAsText => 'Editar como Texto';

  @override
  String get selectImageSource => 'Seleccionar Fuente de Imagen';

  @override
  String get takePhoto => 'Tomar Foto';

  @override
  String get chooseFromGallery => 'Elegir de Galería';

  @override
  String get switchToText => 'Cambiar a Texto';

  @override
  String get camera => 'cámara';

  @override
  String get gallery => 'galería';

  @override
  String get age => 'Edad';

  @override
  String get appearanceOptionalSection => 'Apariencia (Opcional)';

  @override
  String get appearanceDescription =>
      'Describe cómo se ve tu niño para ayudar a crear cuentos personalizados.';

  @override
  String get appearanceMethodQuestion =>
      '¿Cómo te gustaría describir la apariencia?';

  @override
  String get describeInWords => 'Describir con palabras';

  @override
  String get uploadPhoto => 'Subir foto';

  @override
  String get aiWillAnalyzePhoto =>
      'La IA analizará la foto y creará una descripción';

  @override
  String get extractingAppearance => 'Extrayendo apariencia...';

  @override
  String get aiExtractedDescription =>
      'La IA extrajo esta descripción de tu foto. Siéntete libre de revisarla y editarla.';

  @override
  String get appearanceExamplePlaceholder =>
      'Ejemplo: \"Cabello rizado castaño, ojos verdes brillantes y una sonrisa con dientes separados\"';

  @override
  String get appearancePhotoPlaceholder =>
      'Sube una foto arriba para auto-generar descripción, o escribe manualmente';

  @override
  String get appearanceHelperText =>
      'Describe cabello, ojos, características distintivas, etc. Esto ayuda a crear cuentos personalizados.';

  @override
  String get aiGeneratedHelperText =>
      'Puedes editar esta descripción generada por IA para hacerla más personal.';

  @override
  String get storyPreferencesOptional => 'Preferencias de Cuentos (Opcional)';

  @override
  String get preferredLanguage => 'Idioma Preferido';

  @override
  String get parentNotesOptional => 'Notas de Padres (Opcional)';

  @override
  String get parentNotesDescription =>
      'Agrega contexto especial para cuentos: pasatiempos, mascotas, hermanos, intereses, etc.';

  @override
  String get parentNotesExample =>
      'Ejemplo: Le encantan los dinosaurios, tiene un gato llamado Bigotes...';

  @override
  String get ageRequired => 'Edad (Requerida)';

  @override
  String get appearanceExtractedSuccess =>
      '¡Apariencia extraída! Puedes revisar y editar la descripción a continuación.';

  @override
  String failedToExtractAppearance(String error) {
    return 'Error al extraer apariencia: $error';
  }

  @override
  String get genreAdventure => 'Aventura';

  @override
  String get genreFantasy => 'Fantasía';

  @override
  String get genreFriendship => 'Amistad';

  @override
  String get genreFamily => 'Familia';

  @override
  String get genreAnimals => 'Animales';

  @override
  String get genreMagic => 'Magia';

  @override
  String get genreSpace => 'Espacio';

  @override
  String get genreUnderwater => 'Bajo el mar';

  @override
  String get genreForest => 'Bosque';

  @override
  String get genreFairyTale => 'Cuento de hadas';

  @override
  String get genreSuperhero => 'Superhéroe';

  @override
  String get genreDinosaurs => 'Dinosaurios';

  @override
  String get genrePirates => 'Piratas';

  @override
  String get genrePrincess => 'Princesa';

  @override
  String get genreDragons => 'Dragones';

  @override
  String get genreRobots => 'Robots';

  @override
  String get genreMystery => 'Misterio';

  @override
  String get genreFunny => 'Divertido';

  @override
  String get genreEducational => 'Educativo';

  @override
  String get genreBedtime => 'Cuentos para dormir';
}
