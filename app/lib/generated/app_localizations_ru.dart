import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Мира Сказочница';

  @override
  String get myTales => 'Мои сказки';

  @override
  String get create => 'создать';

  @override
  String get favourites => 'Любимые';

  @override
  String get latest => 'Последние';

  @override
  String kidStories(String kidName) {
    return 'Сказки $kidName';
  }

  @override
  String get noStoriesYet => 'Пока нет сказок';

  @override
  String get profile => 'Профиль';

  @override
  String get home => 'Главная';

  @override
  String get settings => 'Настройки';

  @override
  String get selectProfile => 'Выберите профиль';

  @override
  String get noProfileSelected => 'Профиль не выбран';

  @override
  String get magicIsHappening => 'Происходит волшебство..';

  @override
  String get uploadYourCreation => 'Загрузите ваше творение';

  @override
  String get dragDropHere => 'Перетащите сюда';

  @override
  String get or => 'ИЛИ';

  @override
  String get browseFile => 'Выбрать файл';

  @override
  String get generateStory => 'Создать сказку';

  @override
  String get signIn => 'Войти';

  @override
  String get signUp => 'Регистрация';

  @override
  String get email => 'Эл. почта';

  @override
  String get password => 'Пароль';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт?';

  @override
  String get dontHaveAccount => 'Нет аккаунта?';

  @override
  String get welcomeBack => 'С возвращением!';

  @override
  String get createYourAccount => 'Создайте ваш аккаунт';

  @override
  String get parentDashboard => 'Панель для родителей';

  @override
  String get enterPin => 'Введите PIN';

  @override
  String failedToLoadStories(String error) {
    return 'Не удалось загрузить сказки: $error';
  }

  @override
  String get audioRecordingComingSoon => 'Запись звука будет реализована в ближайшее время!';

  @override
  String get textStoryComingSoon => 'Генерация текстовых историй будет реализована в ближайшее время!';

  @override
  String failedToPickImage(String error) {
    return 'Не удалось выбрать изображение: $error';
  }

  @override
  String failedToGenerateStory(String error) {
    return 'Не удалось создать сказку: $error';
  }

  @override
  String get pleaseEnterName => 'Пожалуйста, введите имя';

  @override
  String failedToCreateProfile(String error) {
    return 'Не удалось создать профиль: $error';
  }

  @override
  String get editProfileComingSoon => 'Редактирование профиля скоро будет доступно!';

  @override
  String get favoritesComingSoon => 'Избранное скоро будет доступно!';

  @override
  String failedToPlayAudio(String error) {
    return 'Не удалось воспроизвести аудио: $error';
  }

  @override
  String get incorrectPin => 'Неверный PIN. Попробуйте еще раз.';

  @override
  String get accountCreatedSuccessfully => 'Аккаунт успешно создан! Проверьте свою почту для подтверждения.';

  @override
  String get appleSignInComingSoon => 'Вход через Apple скоро будет доступен!';

  @override
  String get appleSignUpComingSoon => 'Регистрация через Apple скоро будет доступна!';

  @override
  String failedToLoadKids(String error) {
    return 'Не удалось загрузить детей: $error';
  }

  @override
  String get addKidProfileFirst => 'Сначала добавьте профиль ребенка для создания сказок';

  @override
  String get noKidsProfilesAvailable => 'Нет профилей детей. Сначала добавьте ребенка!';

  @override
  String get changePinComingSoon => 'Изменение PIN скоро будет доступно!';

  @override
  String get storySettingsComingSoon => 'Настройки сказок скоро будут доступны!';

  @override
  String get exportDataComingSoon => 'Экспорт данных скоро будет доступен!';

  @override
  String deletingKidProfile(String kidName) {
    return 'Удаление профиля $kidName...';
  }

  @override
  String kidProfileDeleted(String kidName) {
    return 'Профиль $kidName успешно удален';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Не удалось удалить профиль: $error';
  }

  @override
  String languageUpdatedTo(String language) {
    return 'Язык изменен на $language';
  }

  @override
  String get failedToUpdateLanguage => 'Не удалось изменить язык';

  @override
  String errorUpdatingLanguage(String error) {
    return 'Ошибка при изменении языка: $error';
  }

  @override
  String get upload => 'загрузить';

  @override
  String get dictate => 'диктовать';

  @override
  String get submit => 'отправить';

  @override
  String get cancel => 'Отмена';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get continueWithApple => 'Продолжить с Apple';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get viewStories => 'Посмотреть сказки';

  @override
  String get deleteProfile => 'Удалить профиль';

  @override
  String get addKid => 'Добавить ребенка';

  @override
  String get decline => 'Отклонить';

  @override
  String get approve => 'Одобрить';

  @override
  String get delete => 'Удалить';

  @override
  String get storyPreview => 'Предпросмотр сказки';

  @override
  String get exitParentMode => 'Выйти из родительского режима';

  @override
  String get textSize => 'Размер текста';

  @override
  String get backgroundMusic => 'Фоновая музыка';

  @override
  String get createAnotherStory => 'Создать еще одну сказку';

  @override
  String get fullNameOptional => 'Полное имя (необязательно)';

  @override
  String get enterChildName => 'Введите имя ребенка';

  @override
  String get writeYourIdeaHere => 'напишите вашу идею здесь...';

  @override
  String get enterFeedbackOrChanges => 'Введите отзыв или запросите изменения...';

  @override
  String get changeNameAgeAvatar => 'Изменить имя, возраст или аватар';

  @override
  String get switchProfile => 'Сменить профиль';

  @override
  String get changeToDifferentKidProfile => 'Переключиться на другой профиль ребенка';

  @override
  String get favoriteStories => 'Любимые сказки';

  @override
  String get viewYourMostLovedTales => 'Посмотрите ваши самые любимые сказки';

  @override
  String get language => 'Язык';

  @override
  String get changePin => 'Изменить PIN';

  @override
  String get updateParentDashboardPin => 'Обновить PIN родительской панели';

  @override
  String get storySettings => 'Настройки сказок';

  @override
  String get configureStoryGenerationPreferences => 'Настроить параметры генерации сказок';

  @override
  String get exportData => 'Экспорт данных';

  @override
  String get downloadAllStoriesAndData => 'Скачать все сказки и данные';

  @override
  String get noStoryDataAvailable => 'Данные сказки недоступны';

  @override
  String currentFontSize(int size) {
    return 'Текущий: ${size}pt';
  }

  @override
  String get enabled => 'Включено';

  @override
  String get disabled => 'Выключено';

  @override
  String get kidsProfiles => 'Профили детей';

  @override
  String get totalStories => 'Всего сказок';

  @override
  String get noKidsProfilesYet => 'Пока нет профилей детей';

  @override
  String get addFirstKidProfile => 'Добавьте первый профиль ребенка для персонализированных сказок!';

  @override
  String get parentControls => 'Родительский контроль';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get newStory => 'Новая сказка';

  @override
  String stories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'сказок',
      few: 'сказки',
      one: 'сказка',
      zero: 'сказок',
    );
    return '$count $_temp0';
  }

  @override
  String createdDate(String date) {
    return 'Создано $date';
  }

  @override
  String deleteProfileConfirm(String kidName, int storyCount) {
    return 'Вы уверены, что хотите удалить профиль $kidName? Это также удалит все $storyCount сказок.';
  }

  @override
  String profileDetails(String avatarType) {
    return 'Профиль: $avatarType';
  }

  @override
  String creatingStoriesSince(String date) {
    return 'Создает сказки с $date';
  }

  @override
  String get storiesCreated => 'Создано сказок';

  @override
  String get wordsWritten => 'Слов написано';

  @override
  String get profileOptions => 'Настройки профиля';

  @override
  String get changeToDifferentProfile => 'Переключиться на другой профиль ребенка';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get latvian => 'Latviešu';

  @override
  String get pleaseEnterEmail => 'Пожалуйста, введите ваш email';

  @override
  String get pleaseEnterValidEmail => 'Пожалуйста, введите корректный email';

  @override
  String get passwordMinLength => 'Пароль должен содержать минимум 6 символов';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get pleaseEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String get pleaseConfirmPassword => 'Пожалуйста, подтвердите пароль';
}
