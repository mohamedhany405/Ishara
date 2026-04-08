import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings_controller.dart';

/// Centralized translations for all UI strings.
/// Usage: `t(ref).talk` or `tr(context, ref).safety`
class AppStrings {
  // ── Navbar ──────────────────────────────────────────────────────────────────
  final String talk;
  final String vision;
  final String safety;
  final String learn;
  final String profile;

  // ── Talk / Communicate screen ──────────────────────────────────────────────
  final String communicate;
  final String communicateSub;
  final String translationReady;
  final String onDevice;
  final String eslToArabic;
  final String arabicToEsl;
  final String input;
  final String typeOrSpeak;
  final String translate;
  final String translating;
  final String microphone;
  final String listening;
  final String translation;
  final String translatedTextHere;
  final String speak;
  final String confident;
  final String quickPhrases;
  final String howItWorks;
  final String stepType;
  final String stepTypeDesc;
  final String stepDirection;
  final String stepDirectionDesc;
  final String stepTranslate;
  final String stepTranslateDesc;
  final String stepListen;
  final String stepListenDesc;
  final String micSource;
  final String phone;
  final String glasses;
  final String startCamera;
  final String stopCamera;
  final String cameraActive;
  final String cameraActiveDesc;
  final String waitingForSigns;
  final String liveTranslation;
  final String noSignDetected;
  final String pointCamera;
  final String stepCamera;
  final String stepCameraDesc;

  // ── Vision screen ──────────────────────────────────────────────────────────
  final String visionTitle;
  final String visionSub;
  final String scanning;
  final String camera;
  final String gallery;
  final String analysing;
  final String recognizedText;
  final String currencyTotal;
  final String currencyBreakdownLabel;
  final String objectsMode;
  final String objectsModeDesc;
  final String detectedObjects;
  final String noObjectsFound;
  final String currency;
  final String readText;
  final String objects;
  final String copied;
  final String copyText;

  // ── Safety screen ──────────────────────────────────────────────────────────
  final String safetyTitle;
  final String safetySub;
  final String sosEmergency;
  final String tapToOpenSos;
  final String obstacleDetection;
  final String obstacleNearby;
  final String connectHardware;
  final String distance;
  final String cancelSos;
  final String helpSent;
  final String cancelled;
  final String sosCounting;
  final String sosArmedTap;
  final String sendLocation;
  final String startCountdown;
  final String cancel;
  final String done;
  final String tapToArm;
  final String live;
  final String simulated;
  final String left;
  final String right;
  final String sosEmergencyTitle;
  final String locationSentMsg;
  final String sosCancelledMsg;

  // ── Learn screen ───────────────────────────────────────────────────────────
  final String learnTitle;
  final String learnSub;
  final String lessons;
  final String dictionary;
  final String searchLessons;
  final String searchDictionary;
  final String noLessonsFound;
  final String noEntriesFound;
  final String beginner;
  final String daily;
  final String emergency;
  final String wordDetail;
  final String lessonDetail;
  final String watchSign;
  final String close;
  final String meaning;
  final String signVideo;

  // ── Profile screen ─────────────────────────────────────────────────────────
  final String profileTitle;
  final String editProfile;
  final String edit;
  final String save;
  final String appearance;
  final String language;
  final String accessibility;
  final String about;
  final String light;
  final String dark;
  final String system;
  final String pairHardware;
  final String glassesOrCane;
  final String logout;
  final String logoutConfirm;
  final String guestMessage;
  final String guestLogin;
  final String name;
  final String email;
  final String disabilityType;
  final String status;
  final String verified;
  final String notVerified;
  final String fullName;
  final String version;
  final String versionSub;
  final String serverUrl;
  final String serverUrlHint;
  final String profileUpdated;
  final String avatarUpdated;
  final String user;
  final String accessibilityDesc;

  // ── Auth screens ───────────────────────────────────────────────────────────
  final String login;
  final String register;
  final String verifyEmail;
  final String otpSent;
  final String verify;
  final String resendCode;
  final String resendIn;
  final String skipForNow;
  final String otpBrowserHint;
  final String reopen;
  final String welcomeBack;
  final String signInToContinue;
  final String emailAddress;
  final String password;
  final String emailRequired;
  final String invalidEmail;
  final String passwordRequired;
  final String tooShort;
  final String signIn;
  final String signUp;
  final String noAccount;
  final String createAccount;
  final String joinIshara;
  final String passwordHint;
  final String nameRequired;
  final String atLeast8;
  final String letterAndNumber;
  final String accessibilityProfile;
  final String haveAccount;
  final String allDigits;
  final String browserError;
  final String ishara;
  final String eslCompanion;
  final String hearing;
  final String deaf;
  final String blind;
  final String nonVerbal;

  // ── Hardware pairing ───────────────────────────────────────────────────────
  final String pairGlasses;
  final String connectToGlasses;
  final String glassesInstructions;
  final String glassesIp;
  final String port;
  final String connected;
  final String disconnect;
  final String connecting;
  final String retryConnect;
  final String glassesStatus;
  final String waitingSensor;
  final String sensorError;
  final String glassesMicRecording;
  final String glassesMicIdle;
  final String micIdle;
  final String testVibration;
  final String connectedToGlasses;

  // ── Server config ──────────────────────────────────────────────────────────
  final String serverSetup;
  final String serverSetupDesc;
  final String enterServerIp;
  final String connect;
  final String testing;
  final String connectionSuccess;
  final String connectionFailed;

  // ── Emergency contact (Safety page) ───────────────────────────────────────
  final String emergencyContact;
  final String addContact;
  final String editContact;
  final String deleteContact;
  final String contactName;
  final String phoneNumber;
  final String sendVia;
  final String saveContact;
  final String locationAutoSent;
  final String contactSaved;
  final String sosTriggeredByGlasses;

  const AppStrings({
    required this.talk,
    required this.vision,
    required this.safety,
    required this.learn,
    required this.profile,
    required this.communicate,
    required this.communicateSub,
    required this.translationReady,
    required this.onDevice,
    required this.eslToArabic,
    required this.arabicToEsl,
    required this.input,
    required this.typeOrSpeak,
    required this.translate,
    required this.translating,
    required this.microphone,
    required this.listening,
    required this.translation,
    required this.translatedTextHere,
    required this.speak,
    required this.confident,
    required this.quickPhrases,
    required this.howItWorks,
    required this.stepType,
    required this.stepTypeDesc,
    required this.stepDirection,
    required this.stepDirectionDesc,
    required this.stepTranslate,
    required this.stepTranslateDesc,
    required this.stepListen,
    required this.stepListenDesc,
    required this.micSource,
    required this.phone,
    required this.glasses,
    required this.startCamera,
    required this.stopCamera,
    required this.cameraActive,
    required this.cameraActiveDesc,
    required this.waitingForSigns,
    required this.liveTranslation,
    required this.noSignDetected,
    required this.pointCamera,
    required this.stepCamera,
    required this.stepCameraDesc,
    required this.visionTitle,
    required this.visionSub,
    required this.scanning,
    required this.camera,
    required this.gallery,
    required this.analysing,
    required this.recognizedText,
    required this.currencyTotal,
    required this.currencyBreakdownLabel,
    required this.objectsMode,
    required this.objectsModeDesc,
    required this.detectedObjects,
    required this.noObjectsFound,
    required this.currency,
    required this.readText,
    required this.objects,
    required this.copied,
    required this.copyText,
    required this.safetyTitle,
    required this.safetySub,
    required this.sosEmergency,
    required this.tapToOpenSos,
    required this.obstacleDetection,
    required this.obstacleNearby,
    required this.connectHardware,
    required this.distance,
    required this.cancelSos,
    required this.helpSent,
    required this.cancelled,
    required this.sosCounting,
    required this.sosArmedTap,
    required this.sendLocation,
    required this.startCountdown,
    required this.cancel,
    required this.done,
    required this.tapToArm,
    required this.live,
    required this.simulated,
    required this.left,
    required this.right,
    required this.sosEmergencyTitle,
    required this.locationSentMsg,
    required this.sosCancelledMsg,
    required this.learnTitle,
    required this.learnSub,
    required this.lessons,
    required this.dictionary,
    required this.searchLessons,
    required this.searchDictionary,
    required this.noLessonsFound,
    required this.noEntriesFound,
    required this.beginner,
    required this.daily,
    required this.emergency,
    required this.wordDetail,
    required this.lessonDetail,
    required this.watchSign,
    required this.close,
    required this.meaning,
    required this.signVideo,
    required this.profileTitle,
    required this.editProfile,
    required this.edit,
    required this.save,
    required this.appearance,
    required this.language,
    required this.accessibility,
    required this.about,
    required this.light,
    required this.dark,
    required this.system,
    required this.pairHardware,
    required this.glassesOrCane,
    required this.logout,
    required this.logoutConfirm,
    required this.guestMessage,
    required this.guestLogin,
    required this.name,
    required this.email,
    required this.disabilityType,
    required this.status,
    required this.verified,
    required this.notVerified,
    required this.fullName,
    required this.version,
    required this.versionSub,
    required this.serverUrl,
    required this.serverUrlHint,
    required this.profileUpdated,
    required this.avatarUpdated,
    required this.user,
    required this.accessibilityDesc,
    required this.login,
    required this.register,
    required this.verifyEmail,
    required this.otpSent,
    required this.verify,
    required this.resendCode,
    required this.resendIn,
    required this.skipForNow,
    required this.otpBrowserHint,
    required this.reopen,
    required this.welcomeBack,
    required this.signInToContinue,
    required this.emailAddress,
    required this.password,
    required this.emailRequired,
    required this.invalidEmail,
    required this.passwordRequired,
    required this.tooShort,
    required this.signIn,
    required this.signUp,
    required this.noAccount,
    required this.createAccount,
    required this.joinIshara,
    required this.passwordHint,
    required this.nameRequired,
    required this.atLeast8,
    required this.letterAndNumber,
    required this.accessibilityProfile,
    required this.haveAccount,
    required this.allDigits,
    required this.browserError,
    required this.ishara,
    required this.eslCompanion,
    required this.hearing,
    required this.deaf,
    required this.blind,
    required this.nonVerbal,
    required this.pairGlasses,
    required this.connectToGlasses,
    required this.glassesInstructions,
    required this.glassesIp,
    required this.port,
    required this.connected,
    required this.disconnect,
    required this.connecting,
    required this.retryConnect,
    required this.glassesStatus,
    required this.waitingSensor,
    required this.sensorError,
    required this.glassesMicRecording,
    required this.glassesMicIdle,
    required this.micIdle,
    required this.testVibration,
    required this.connectedToGlasses,
    required this.serverSetup,
    required this.serverSetupDesc,
    required this.enterServerIp,
    required this.connect,
    required this.testing,
    required this.connectionSuccess,
    required this.connectionFailed,
    // Emergency contact
    required this.emergencyContact,
    required this.addContact,
    required this.editContact,
    required this.deleteContact,
    required this.contactName,
    required this.phoneNumber,
    required this.sendVia,
    required this.saveContact,
    required this.locationAutoSent,
    required this.contactSaved,
    required this.sosTriggeredByGlasses,
  });
}

const _en = AppStrings(
  // Navbar
  talk: 'Talk',
  vision: 'Vision',
  safety: 'Safety',
  learn: 'Learn',
  profile: 'Profile',
  // Communicate
  communicate: 'Communicate',
  communicateSub: 'ESL ↔ Arabic · Real-time translation',
  translationReady: 'Translation engine ready',
  onDevice: 'On-device',
  eslToArabic: 'ESL → AR',
  arabicToEsl: 'AR → ESL',
  input: 'Input',
  typeOrSpeak: 'Type or speak here…',
  translate: 'Translate',
  translating: 'Translating…',
  microphone: 'Microphone',
  listening: 'Listening…',
  translation: 'Translation',
  translatedTextHere: 'Translated text will appear here…',
  speak: 'Speak',
  confident: 'confident',
  quickPhrases: 'Quick phrases',
  howItWorks: 'How it works',
  stepType: 'Type or speak',
  stepTypeDesc: 'Enter text or use the microphone to capture speech',
  stepDirection: 'Choose direction',
  stepDirectionDesc: 'Toggle between ESL → Arabic or Arabic → ESL',
  stepTranslate: 'Get translation',
  stepTranslateDesc: 'Tap Translate for instant results with confidence score',
  stepListen: 'Listen to output',
  stepListenDesc: 'Hear the translated text spoken aloud',
  micSource: 'Mic source:',
  phone: 'Phone',
  glasses: 'Glasses',
  startCamera: 'Start Camera',
  stopCamera: 'Stop Camera',
  cameraActive: 'Camera Active',
  cameraActiveDesc: 'Point your camera at sign language gestures for live translation',
  waitingForSigns: 'Waiting for signs…',
  liveTranslation: 'Live Translation',
  noSignDetected: 'No sign detected yet',
  pointCamera: 'Point camera at hands to detect signs',
  stepCamera: 'Open camera',
  stepCameraDesc: 'Point camera at sign language gestures to detect and translate',
  // Vision
  visionTitle: 'Vision',
  visionSub: 'Scan, read, and understand',
  scanning: 'Scanning…',
  camera: 'Camera',
  gallery: 'Gallery',
  analysing: 'Analysing…',
  recognizedText: 'Recognized text',
  currencyTotal: 'Currency total',
  currencyBreakdownLabel: 'Breakdown',
  objectsMode: 'Objects mode',
  objectsModeDesc:
      'On-device object recognition. Pick an image to detect objects.',
  detectedObjects: 'Detected objects',
  noObjectsFound: 'No objects detected – try a clearer image.',
  currency: 'Currency',
  readText: 'Read Text',
  objects: 'Objects',
  copied: 'Copied to clipboard',
  copyText: 'Copy',
  // Safety
  safetyTitle: 'Safety',
  safetySub: 'Emergency SOS · Obstacle detection',
  sosEmergency: 'SOS \u2013 Emergency',
  tapToOpenSos: 'Tap to open emergency screen',
  obstacleDetection: 'Obstacle detection',
  obstacleNearby: 'Obstacle nearby \u2013 proceed with caution.',
  connectHardware: 'Connect hardware (glasses/cane) for live sensor data.',
  distance: 'Distance',
  cancelSos: 'Cancel SOS',
  helpSent: 'Help Sent ✓',
  cancelled: 'Cancelled',
  sosCounting: 'Counting down \u2013 tap Cancel if not needed.',
  sosArmedTap: 'Tap the button to start countdown.',
  sendLocation: 'Send your location to emergency contacts.',
  startCountdown: 'Start 5-second countdown',
  cancel: 'Cancel',
  done: 'Done',
  tapToArm: 'Tap to arm · hold to send immediately',
  live: 'Live',
  simulated: 'Simulated',
  left: 'Left',
  right: 'Right',
  sosEmergencyTitle: 'SOS Emergency',
  locationSentMsg: 'Your location was sent to emergency contacts.',
  sosCancelledMsg: 'SOS was cancelled.',
  // Learn
  learnTitle: 'Learn',
  learnSub: 'Lessons · Dictionary',
  lessons: 'Lessons',
  dictionary: 'Dictionary',
  searchLessons: 'Search lessons…',
  searchDictionary: 'Search dictionary (Arabic or English)…',
  noLessonsFound: 'No lessons found',
  noEntriesFound: 'No entries found',
  beginner: 'Beginner',
  daily: 'Daily',
  emergency: 'Emergency',
  wordDetail: 'Word Detail',
  lessonDetail: 'Lesson Detail',
  watchSign: 'Watch Sign',
  close: 'Close',
  meaning: 'Meaning',
  signVideo: 'Sign Language Video',
  // Profile
  profileTitle: 'Profile',
  editProfile: 'Edit Profile',
  edit: 'Edit',
  save: 'Save',
  appearance: 'Appearance',
  language: 'Language',
  accessibility: 'Accessibility',
  about: 'About',
  light: 'Light',
  dark: 'Dark',
  system: 'System',
  pairHardware: 'Pair hardware',
  glassesOrCane: 'Glasses or smart cane',
  logout: 'Log out',
  logoutConfirm: 'Are you sure you want to log out?',
  guestMessage: 'You\'re using Ishara as a guest',
  guestLogin: 'Log in',
  name: 'Name',
  email: 'Email',
  disabilityType: 'Disability type',
  status: 'Status',
  verified: 'Verified ✓',
  notVerified: 'Not verified',
  fullName: 'Full name',
  version: 'Version 1.0.0',
  versionSub: 'Ishara \u2013 Accessible ESL companion',
  serverUrl: 'Server URL',
  serverUrlHint: 'e.g. 192.168.1.25',
  profileUpdated: 'Profile updated',
  avatarUpdated: 'Avatar updated',
  user: 'User',
  accessibilityDesc:
      'Set up for deaf, blind, or non-verbal use. Pair glasses or cane for live sensors.',
  // Auth
  login: 'Log in',
  register: 'Register',
  verifyEmail: 'Verify your email',
  otpSent: 'A 6-digit code was generated.',
  verify: 'Verify',
  resendCode: 'Resend code',
  resendIn: 'Resend code in',
  skipForNow: 'Skip for now',
  otpBrowserHint: 'Your browser opened with the OTP. Copy it below.',
  reopen: 'Re-open',
  welcomeBack: 'Welcome back',
  signInToContinue: 'Sign in to continue',
  emailAddress: 'Email address',
  password: 'Password',
  emailRequired: 'Email required',
  invalidEmail: 'Invalid email',
  passwordRequired: 'Password required',
  tooShort: 'Too short',
  signIn: 'Sign In',
  signUp: 'Sign up',
  noAccount: 'Don\'t have an account? ',
  createAccount: 'Create Account',
  joinIshara: 'Join Ishara today',
  passwordHint: 'Password (min 8 chars, letter + number)',
  nameRequired: 'Name required',
  atLeast8: 'At least 8 characters',
  letterAndNumber: 'Must include a letter and a number',
  accessibilityProfile: 'Accessibility profile',
  haveAccount: 'Already have an account? ',
  allDigits: 'Please enter all 6 digits',
  browserError: 'Could not open browser. Check your server is running.',
  ishara: 'Ishara',
  eslCompanion: 'Accessible ESL Companion',
  hearing: 'Hearing',
  deaf: 'Deaf',
  blind: 'Blind',
  nonVerbal: 'Non-verbal',
  // Hardware pairing
  pairGlasses: 'Pair Glasses',
  connectToGlasses: 'Connect to Ishara Glasses',
  glassesInstructions:
      'The glasses run a WebSocket server. Enter the IP shown on the glasses serial monitor and port 8080.',
  glassesIp: 'Glasses IP',
  port: 'Port',
  connected: 'Connected',
  disconnect: 'Disconnect',
  connecting: 'Connecting…',
  retryConnect: 'Retry connect',
  glassesStatus: 'Glasses Status',
  waitingSensor: 'Waiting for sensor…',
  sensorError: 'Sensor error',
  glassesMicRecording: 'Glasses mic: Recording…',
  glassesMicIdle: 'Glasses mic: Idle',
  micIdle: 'Mic idle',
  testVibration: 'Test vibration',
  connectedToGlasses: 'Connected to glasses',
  // Server config
  serverSetup: 'Server Setup',
  serverSetupDesc:
      'Enter the IP address of the computer running the Ishara backend.',
  enterServerIp: 'Server IP address',
  connect: 'Connect',
  testing: 'Testing connection…',
  connectionSuccess: 'Connected successfully!',
  connectionFailed: 'Failed to connect. Check the address and try again.',
  // Emergency contact
  emergencyContact: 'Emergency Contact',
  addContact: 'Add Contact',
  editContact: 'Edit',
  deleteContact: 'Delete',
  contactName: 'Contact name',
  phoneNumber: 'Phone number (e.g. 01012345678)',
  sendVia: 'Send via:',
  saveContact: 'Save',
  locationAutoSent: 'Your location will be sent automatically on SOS',
  contactSaved: 'Emergency contact saved',
  sosTriggeredByGlasses: 'SOS triggered by glasses button',
);

const _ar = AppStrings(
  // Navbar
  talk: 'تحدث',
  vision: 'الرؤية',
  safety: 'الأمان',
  learn: 'تعلّم',
  profile: 'الملف',
  // Communicate
  communicate: 'التواصل',
  communicateSub: 'لغة الإشارة ↔ العربية · ترجمة فورية',
  translationReady: 'محرك الترجمة جاهز',
  onDevice: 'على الجهاز',
  eslToArabic: 'إشارة → عربي',
  arabicToEsl: 'عربي → إشارة',
  input: 'إدخال',
  typeOrSpeak: 'اكتب أو تحدث هنا…',
  translate: 'ترجم',
  translating: 'جاري الترجمة…',
  microphone: 'ميكروفون',
  listening: 'أستمع…',
  translation: 'الترجمة',
  translatedTextHere: 'ستظهر الترجمة هنا…',
  speak: 'تشغيل',
  confident: 'ثقة',
  quickPhrases: 'عبارات سريعة',
  howItWorks: 'كيف يعمل',
  stepType: 'اكتب أو تحدث',
  stepTypeDesc: 'أدخل النص أو استخدم الميكروفون',
  stepDirection: 'اختر الاتجاه',
  stepDirectionDesc: 'بدّل بين إشارة → عربي أو عربي → إشارة',
  stepTranslate: 'احصل على الترجمة',
  stepTranslateDesc: 'اضغط ترجم للحصول على النتيجة مع نسبة الثقة',
  stepListen: 'استمع للنتيجة',
  stepListenDesc: 'اسمع النص المترجم بصوت عالٍ',
  micSource: 'مصدر الصوت:',
  phone: 'الهاتف',
  glasses: 'النظارات',
  startCamera: 'تشغيل الكاميرا',
  stopCamera: 'إيقاف الكاميرا',
  cameraActive: 'الكاميرا نشطة',
  cameraActiveDesc: 'وجّه الكاميرا إلى إشارات لغة الإشارة للترجمة الفورية',
  waitingForSigns: 'بانتظار الإشارات…',
  liveTranslation: 'ترجمة مباشرة',
  noSignDetected: 'لم يتم اكتشاف إشارة بعد',
  pointCamera: 'وجّه الكاميرا نحو اليدين لاكتشاف الإشارات',
  stepCamera: 'افتح الكاميرا',
  stepCameraDesc: 'وجّه الكاميرا نحو إشارات لغة الإشارة لاكتشافها وترجمتها',
  // Vision
  visionTitle: 'الرؤية',
  visionSub: 'امسح، اقرأ، وافهم',
  scanning: 'جاري المسح…',
  camera: 'الكاميرا',
  gallery: 'المعرض',
  analysing: 'جاري التحليل…',
  recognizedText: 'النص المتعرّف عليه',
  currencyTotal: 'إجمالي العملة',
  currencyBreakdownLabel: 'التفاصيل',
  objectsMode: 'وضع الأشياء',
  objectsModeDesc:
      'تعرّف على الأشياء على الجهاز. اختر صورة لاكتشاف الأشياء.',
  detectedObjects: 'الأشياء المكتشفة',
  noObjectsFound: 'لم يتم اكتشاف أشياء – حاول بصورة أوضح.',
  currency: 'العملة',
  readText: 'قراءة النص',
  objects: 'الأشياء',
  copied: 'تم النسخ',
  copyText: 'نسخ',
  // Safety
  safetyTitle: 'الأمان',
  safetySub: 'طوارئ SOS · كشف العوائق',
  sosEmergency: 'طوارئ SOS',
  tapToOpenSos: 'اضغط لفتح شاشة الطوارئ',
  obstacleDetection: 'كشف العوائق',
  obstacleNearby: 'عائق قريب \u2013 تابع بحذر.',
  connectHardware: 'قم بتوصيل الجهاز (نظارات/عصا) لبيانات المستشعر.',
  distance: 'المسافة',
  cancelSos: 'إلغاء SOS',
  helpSent: 'تم الإرسال ✓',
  cancelled: 'تم الإلغاء',
  sosCounting: 'العد التنازلي \u2013 اضغط إلغاء إذا لم تكن بحاجة.',
  sosArmedTap: 'اضغط الزر لبدء العد التنازلي.',
  sendLocation: 'أرسل موقعك إلى جهات الطوارئ.',
  startCountdown: 'بدء العد التنازلي ٥ ثوانٍ',
  cancel: 'إلغاء',
  done: 'تم',
  tapToArm: 'اضغط للتفعيل · اضغط طويلاً للإرسال فوراً',
  live: 'مباشر',
  simulated: 'محاكاة',
  left: 'يسار',
  right: 'يمين',
  sosEmergencyTitle: 'طوارئ SOS',
  locationSentMsg: 'تم إرسال موقعك إلى جهات الطوارئ.',
  sosCancelledMsg: 'تم إلغاء SOS.',
  // Learn
  learnTitle: 'تعلّم',
  learnSub: 'دروس · قاموس',
  lessons: 'الدروس',
  dictionary: 'القاموس',
  searchLessons: 'ابحث في الدروس…',
  searchDictionary: 'ابحث في القاموس (عربي أو إنجليزي)…',
  noLessonsFound: 'لا توجد دروس',
  noEntriesFound: 'لا توجد نتائج',
  beginner: 'مبتدئ',
  daily: 'يومي',
  emergency: 'طوارئ',
  wordDetail: 'تفاصيل الكلمة',
  lessonDetail: 'تفاصيل الدرس',
  watchSign: 'شاهد الإشارة',
  close: 'إغلاق',
  meaning: 'المعنى',
  signVideo: 'فيديو لغة الإشارة',
  // Profile
  profileTitle: 'الملف الشخصي',
  editProfile: 'تعديل الملف',
  edit: 'تعديل',
  save: 'حفظ',
  appearance: 'المظهر',
  language: 'اللغة',
  accessibility: 'إمكانية الوصول',
  about: 'حول',
  light: 'فاتح',
  dark: 'داكن',
  system: 'النظام',
  pairHardware: 'إقران الجهاز',
  glassesOrCane: 'نظارات أو عصا ذكية',
  logout: 'تسجيل الخروج',
  logoutConfirm: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
  guestMessage: 'أنت تستخدم إيشارا كضيف',
  guestLogin: 'تسجيل الدخول',
  name: 'الاسم',
  email: 'البريد',
  disabilityType: 'نوع الإعاقة',
  status: 'الحالة',
  verified: 'موثّق ✓',
  notVerified: 'غير موثّق',
  fullName: 'الاسم الكامل',
  version: 'الإصدار 1.0.0',
  versionSub: 'إيشارا \u2013 مساعد لغة الإشارة',
  serverUrl: 'رابط الخادم',
  serverUrlHint: 'مثال: 192.168.1.25',
  profileUpdated: 'تم تحديث الملف',
  avatarUpdated: 'تم تحديث الصورة',
  user: 'مستخدم',
  accessibilityDesc:
      'إعداد لأصحاب الإعاقة السمعية أو البصرية أو الكلامية. أقرن النظارات أو العصا للمستشعرات.',
  // Auth
  login: 'تسجيل الدخول',
  register: 'إنشاء حساب',
  verifyEmail: 'تحقق من بريدك',
  otpSent: 'تم إنشاء رمز مكون من ٦ أرقام.',
  verify: 'تحقق',
  resendCode: 'إعادة إرسال الرمز',
  resendIn: 'إعادة إرسال بعد',
  skipForNow: 'تخطي الآن',
  otpBrowserHint: 'تم فتح المتصفح مع رمز التحقق. انسخه أدناه.',
  reopen: 'فتح مجدداً',
  welcomeBack: 'مرحباً بعودتك',
  signInToContinue: 'سجّل الدخول للمتابعة',
  emailAddress: 'البريد الإلكتروني',
  password: 'كلمة المرور',
  emailRequired: 'البريد مطلوب',
  invalidEmail: 'بريد غير صالح',
  passwordRequired: 'كلمة المرور مطلوبة',
  tooShort: 'قصيرة جداً',
  signIn: 'تسجيل الدخول',
  signUp: 'إنشاء حساب',
  noAccount: 'ليس لديك حساب؟ ',
  createAccount: 'إنشاء حساب',
  joinIshara: 'انضم إلى إيشارا اليوم',
  passwordHint: 'كلمة المرور (٨ أحرف على الأقل، حرف + رقم)',
  nameRequired: 'الاسم مطلوب',
  atLeast8: '٨ أحرف على الأقل',
  letterAndNumber: 'يجب أن تحتوي على حرف ورقم',
  accessibilityProfile: 'ملف إمكانية الوصول',
  haveAccount: 'لديك حساب بالفعل؟ ',
  allDigits: 'أدخل جميع الأرقام الستة',
  browserError: 'تعذر فتح المتصفح. تأكد من تشغيل الخادم.',
  ishara: 'إيشارا',
  eslCompanion: 'مساعد لغة الإشارة',
  hearing: 'سمعية',
  deaf: 'صم',
  blind: 'بصرية',
  nonVerbal: 'غير لفظي',
  // Hardware pairing
  pairGlasses: 'إقران النظارات',
  connectToGlasses: 'الاتصال بنظارات إيشارا',
  glassesInstructions:
      'تعمل النظارات كخادم WebSocket. أدخل عنوان IP المعروض على شاشة النظارات والمنفذ 8080.',
  glassesIp: 'عنوان IP النظارات',
  port: 'المنفذ',
  connected: 'متصل',
  disconnect: 'قطع الاتصال',
  connecting: 'جاري الاتصال…',
  retryConnect: 'إعادة المحاولة',
  glassesStatus: 'حالة النظارات',
  waitingSensor: 'بانتظار المستشعر…',
  sensorError: 'خطأ في المستشعر',
  glassesMicRecording: 'ميكروفون النظارات: يسجّل…',
  glassesMicIdle: 'ميكروفون النظارات: خامل',
  micIdle: 'ميكروفون خامل',
  testVibration: 'اختبار الاهتزاز',
  connectedToGlasses: 'تم الاتصال بالنظارات',
  // Server config
  serverSetup: 'إعداد الخادم',
  serverSetupDesc: 'أدخل عنوان IP للحاسوب الذي يشغّل خادم إيشارا.',
  enterServerIp: 'عنوان IP الخادم',
  connect: 'اتصال',
  testing: 'اختبار الاتصال…',
  connectionSuccess: 'تم الاتصال بنجاح!',
  connectionFailed: 'تعذر الاتصال. تحقق من العنوان وحاول مجدداً.',
  // Emergency contact
  emergencyContact: 'جهة الاتصال الطارئ',
  addContact: 'إضافة جهة اتصال',
  editContact: 'تعديل',
  deleteContact: 'حذف',
  contactName: 'اسم جهة الاتصال',
  phoneNumber: 'رقم الهاتف (مثال: 01012345678)',
  sendVia: 'إرسال عبر:',
  saveContact: 'حفظ',
  locationAutoSent: 'سيتم إرسال موقعك تلقائياً عند الضغط على SOS',
  contactSaved: 'تم حفظ جهة الاتصال الطارئ',
  sosTriggeredByGlasses: 'تم تفعيل SOS عبر زر النظارات',
);

/// Convenience accessor – use `t(ref)` anywhere you have a `WidgetRef`.
AppStrings t(WidgetRef ref) {
  final lang = ref.watch(appSettingsProvider).language;
  return lang == IsharaLanguage.ar ? _ar : _en;
}

/// Read-only version for use outside widgets (e.g. in controllers).
AppStrings tRead(Ref ref) {
  final lang = ref.read(appSettingsProvider).language;
  return lang == IsharaLanguage.ar ? _ar : _en;
}
