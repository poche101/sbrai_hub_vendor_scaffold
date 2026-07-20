/// A static translation table covering the fixed UI chrome across the
/// whole app (nav labels, headings, buttons, form labels, category
/// names). Listing content itself (vendor-authored titles/descriptions)
/// should go through the backend's POST /translate endpoints instead,
/// since that's dynamic text — this file is only for fixed copy that
/// ships with the app.
enum AppLanguage { english, igbo, yoruba, hausa, french }

extension AppLanguageX on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.igbo:
        return 'ig';
      case AppLanguage.yoruba:
        return 'yo';
      case AppLanguage.hausa:
        return 'ha';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.english:
        return 'en';
    }
  }

  String get label {
    switch (this) {
      case AppLanguage.igbo:
        return 'Igbo (Asụsụ Igbo)';
      case AppLanguage.yoruba:
        return 'Yorùbá (Èdè Yorùbá)';
      case AppLanguage.hausa:
        return 'Hausa (Harshen Hausa)';
      case AppLanguage.french:
        return 'Français';
      case AppLanguage.english:
        return 'English';
    }
  }
}

class AppStrings {
  AppStrings._();

  static const Map<String, Map<AppLanguage, String>> _table = {
    // ---- Nav / chrome ------------------------------------------------
    'home': {AppLanguage.english: 'Home', AppLanguage.igbo: 'Ụlọ', AppLanguage.yoruba: 'Ilé', AppLanguage.hausa: 'Gida', AppLanguage.french: 'Accueil'},
    'chat': {AppLanguage.english: 'Chat', AppLanguage.igbo: 'Kwuo okwu', AppLanguage.yoruba: 'Ìfọ̀rọ̀wánilẹ́nuwò', AppLanguage.hausa: 'Hira', AppLanguage.french: 'Discuter'},
    'messages': {AppLanguage.english: 'Messages', AppLanguage.igbo: 'Ozi', AppLanguage.yoruba: 'Àwọn Ìránṣẹ́', AppLanguage.hausa: 'Saƙonni', AppLanguage.french: 'Messages'},
    'post': {AppLanguage.english: 'Post', AppLanguage.igbo: 'Zipu', AppLanguage.yoruba: 'Fiwé', AppLanguage.hausa: 'Tura', AppLanguage.french: 'Publier'},
    'dashboard': {AppLanguage.english: 'Dashboard', AppLanguage.igbo: 'Bọọdụ', AppLanguage.yoruba: 'Pátákó', AppLanguage.hausa: 'Allo', AppLanguage.french: 'Tableau de bord'},
    'settings': {AppLanguage.english: 'Settings', AppLanguage.igbo: 'Ntọala', AppLanguage.yoruba: 'Ètò', AppLanguage.hausa: 'Saituna', AppLanguage.french: 'Réglages'},
    'favorites': {AppLanguage.english: 'Favorites', AppLanguage.igbo: 'Ihe ọ masịrị gị', AppLanguage.yoruba: 'Ayanfẹ', AppLanguage.hausa: 'Abubuwan so', AppLanguage.french: 'Favoris'},
    'profile': {AppLanguage.english: 'Profile', AppLanguage.igbo: 'Profaịlụ', AppLanguage.yoruba: 'Àkọsílẹ̀', AppLanguage.hausa: 'Bayanan martaba', AppLanguage.french: 'Profil'},
    'kyc': {AppLanguage.english: 'KYC', AppLanguage.igbo: 'KYC', AppLanguage.yoruba: 'KYC', AppLanguage.hausa: 'KYC', AppLanguage.french: 'KYC'},
    'logout': {AppLanguage.english: 'Logout', AppLanguage.igbo: 'Pụọ', AppLanguage.yoruba: 'Jáde', AppLanguage.hausa: 'Fita', AppLanguage.french: 'Déconnexion'},
    'subscription': {AppLanguage.english: 'Subscription', AppLanguage.igbo: 'Ndenye aha', AppLanguage.yoruba: 'Ìforúkọsílẹ̀', AppLanguage.hausa: 'Biyan kuɗi', AppLanguage.french: 'Abonnement'},

    // ---- Home ---------------------------------------------------------
    'searchPlaceholder': {AppLanguage.english: 'What are you looking for?', AppLanguage.igbo: 'Kedu ihe ị na-achọ?', AppLanguage.yoruba: 'Kín ni o ń wá?', AppLanguage.hausa: 'Me kake nema?', AppLanguage.french: 'Que recherchez-vous ?'},
    'recommended': {AppLanguage.english: 'Recommended for You', AppLanguage.igbo: 'Atụrụ Aro Maka Gị', AppLanguage.yoruba: 'Ohun tí a dámọ̀ràn fún ọ', AppLanguage.hausa: 'Shawarwari a gare ka', AppLanguage.french: 'Recommandé pour vous'},
    'items': {AppLanguage.english: 'items', AppLanguage.igbo: 'ihe', AppLanguage.yoruba: 'ohun', AppLanguage.hausa: 'abubuwa', AppLanguage.french: 'articles'},
    'call': {AppLanguage.english: 'Call', AppLanguage.igbo: 'Kpọọ', AppLanguage.yoruba: 'Pè', AppLanguage.hausa: 'Kira', AppLanguage.french: 'Appeler'},
    'allNigeria': {AppLanguage.english: 'All Nigeria', AppLanguage.igbo: 'Naịjirịa Niile', AppLanguage.yoruba: 'Gbogbo Nàìjíríà', AppLanguage.hausa: 'Duk Najeriya', AppLanguage.french: 'Tout le Nigeria'},
    'trending': {AppLanguage.english: 'Trending', AppLanguage.igbo: 'Na-ese', AppLanguage.yoruba: 'Gbajúmọ̀', AppLanguage.hausa: 'Abin da ke tafiya', AppLanguage.french: 'Tendance'},
    'buyer': {AppLanguage.english: 'Buyer', AppLanguage.igbo: 'Onye Azụta', AppLanguage.yoruba: 'Olùra', AppLanguage.hausa: 'Mai saye', AppLanguage.french: 'Acheteur'},
    'vendor': {AppLanguage.english: 'Vendor', AppLanguage.igbo: 'Onye Na-ere', AppLanguage.yoruba: 'Olùtajà', AppLanguage.hausa: 'Mai sayarwa', AppLanguage.french: 'Vendeur'},

    // ---- Categories -----------------------------------------------------
    'cat_sharp_sand': {AppLanguage.english: 'Sharp Sand', AppLanguage.igbo: 'Ájá Nkọ', AppLanguage.yoruba: 'Iyanrin', AppLanguage.hausa: 'Yashi', AppLanguage.french: 'Sable'},
    'cat_granite': {AppLanguage.english: 'Granite', AppLanguage.igbo: 'Nkume Granite', AppLanguage.yoruba: 'Òkúta Granite', AppLanguage.hausa: 'Dutsen Granite', AppLanguage.french: 'Granit'},
    'cat_blocks': {AppLanguage.english: 'Blocks', AppLanguage.igbo: 'Blọk', AppLanguage.yoruba: 'Bíríkì', AppLanguage.hausa: 'Bulo', AppLanguage.french: 'Blocs'},
    'cat_cement': {AppLanguage.english: 'Cement', AppLanguage.igbo: 'Simenti', AppLanguage.yoruba: 'Simenti', AppLanguage.hausa: 'Siminti', AppLanguage.french: 'Ciment'},
    'cat_iron_rods': {AppLanguage.english: 'Iron Rods', AppLanguage.igbo: 'Mkpịsị Ígwè', AppLanguage.yoruba: 'Ọ̀pá Irin', AppLanguage.hausa: 'Sandunan ƙarfe', AppLanguage.french: 'Barres de fer'},
    'cat_paints': {AppLanguage.english: 'Paints', AppLanguage.igbo: 'Agba', AppLanguage.yoruba: 'Àwọ̀', AppLanguage.hausa: 'Fenti', AppLanguage.french: 'Peintures'},
    'cat_furniture': {AppLanguage.english: 'Furniture', AppLanguage.igbo: 'Ngwá Ụlọ', AppLanguage.yoruba: 'Ohun Èlò Ilé', AppLanguage.hausa: 'Kayan daki', AppLanguage.french: 'Meubles'},
    'cat_scaffolding': {AppLanguage.english: 'Scaffolding', AppLanguage.igbo: 'Ngwá Ọrụ', AppLanguage.yoruba: 'Àtẹ̀gùn Ìkọ́lé', AppLanguage.hausa: 'Kayan hawa', AppLanguage.french: 'Échafaudage'},
    'cat_logistics': {AppLanguage.english: 'Logistics', AppLanguage.igbo: 'Ụgbọ Ibu', AppLanguage.yoruba: 'Ìrìnnà Ẹrù', AppLanguage.hausa: 'Sufuri', AppLanguage.french: 'Logistique'},
    'cat_borehole': {AppLanguage.english: 'Borehole', AppLanguage.igbo: 'Olulu Mmiri', AppLanguage.yoruba: 'Kànga', AppLanguage.hausa: 'Rijiya', AppLanguage.french: 'Forage'},
    'cat_cleaning': {AppLanguage.english: 'Cleaning', AppLanguage.igbo: 'Ihicha', AppLanguage.yoruba: 'Ìṣọ́nà', AppLanguage.hausa: 'Tsaftacewa', AppLanguage.french: 'Nettoyage'},
    'cat_fumigation': {AppLanguage.english: 'Fumigation', AppLanguage.igbo: 'Ịgba Ọgwụ Ahụhụ', AppLanguage.yoruba: 'Ìtọ́jú Kòkòrò', AppLanguage.hausa: 'Feshin ƙwari', AppLanguage.french: 'Fumigation'},
    'cat_apartments': {AppLanguage.english: 'Apartments', AppLanguage.igbo: 'Ụlọ Mgbaghari', AppLanguage.yoruba: 'Ìyẹ̀wù Ilé', AppLanguage.hausa: 'Gidaje', AppLanguage.french: 'Appartements'},
    'cat_houses': {AppLanguage.english: 'Houses', AppLanguage.igbo: 'Ụlọ', AppLanguage.yoruba: 'Ilé', AppLanguage.hausa: 'Gidaje', AppLanguage.french: 'Maisons'},
    'cat_commercial': {AppLanguage.english: 'Commercial', AppLanguage.igbo: 'Azụmahịa', AppLanguage.yoruba: 'Ti Òwò', AppLanguage.hausa: 'Kasuwanci', AppLanguage.french: 'Commercial'},
    'cat_land': {AppLanguage.english: 'Land', AppLanguage.igbo: 'Ala', AppLanguage.yoruba: 'Ilẹ̀', AppLanguage.hausa: 'Ƙasa', AppLanguage.french: 'Terrain'},

    // ---- Auth (login / signup) ------------------------------------------
    'welcomeBack': {AppLanguage.english: 'Welcome Back', AppLanguage.igbo: 'Nnọọ Ọzọ', AppLanguage.yoruba: 'Kaabọ Padà', AppLanguage.hausa: 'Barka da dawowa', AppLanguage.french: 'Content de vous revoir'},
    'signInSubtitle': {AppLanguage.english: 'Sign in to your account to continue', AppLanguage.igbo: 'Banye n\'akaụntụ gị ka ị gaa n\'ihu', AppLanguage.yoruba: 'Wọlé sí àkáǹtì rẹ láti tẹ̀síwájú', AppLanguage.hausa: 'Shiga asusun ka don ci gaba', AppLanguage.french: 'Connectez-vous pour continuer'},
    'emailAddress': {AppLanguage.english: 'Email Address', AppLanguage.igbo: 'Adreesị Email', AppLanguage.yoruba: 'Àdírẹ́sì Ímeèlì', AppLanguage.hausa: 'Adireshin Imel', AppLanguage.french: 'Adresse e-mail'},
    'password': {AppLanguage.english: 'Password', AppLanguage.igbo: 'Okwuntughe', AppLanguage.yoruba: 'Ọ̀rọ̀ Ìgbaniwọlé', AppLanguage.hausa: 'Kalmar sirri', AppLanguage.french: 'Mot de passe'},
    'forgotPassword': {AppLanguage.english: 'Forgot Password?', AppLanguage.igbo: 'Chefuru Okwuntughe?', AppLanguage.yoruba: 'Gbàgbé Ọ̀rọ̀ Ìgbaniwọlé?', AppLanguage.hausa: 'Manta kalmar sirri?', AppLanguage.french: 'Mot de passe oublié ?'},
    'signIn': {AppLanguage.english: 'Sign In', AppLanguage.igbo: 'Banye', AppLanguage.yoruba: 'Wọlé', AppLanguage.hausa: 'Shiga', AppLanguage.french: 'Se connecter'},
    'noAccount': {AppLanguage.english: "Don't have an account?", AppLanguage.igbo: 'Ọ nweghị akaụntụ?', AppLanguage.yoruba: 'Ò ní àkáǹtì?', AppLanguage.hausa: 'Ba ka da asusu?', AppLanguage.french: "Vous n'avez pas de compte ?"},
    'signUp': {AppLanguage.english: 'Sign Up', AppLanguage.igbo: 'Debanye Aha', AppLanguage.yoruba: 'Forúkọsílẹ̀', AppLanguage.hausa: 'Yi rajista', AppLanguage.french: "S'inscrire"},
    'continueWithGoogle': {AppLanguage.english: 'Continue with Google', AppLanguage.igbo: 'Jiri Google Gaa N\'ihu', AppLanguage.yoruba: 'Tẹ̀síwájú pẹ̀lú Google', AppLanguage.hausa: 'Ci gaba da Google', AppLanguage.french: 'Continuer avec Google'},
    'continueWithFacebook': {AppLanguage.english: 'Continue with Facebook', AppLanguage.igbo: 'Jiri Facebook Gaa N\'ihu', AppLanguage.yoruba: 'Tẹ̀síwájú pẹ̀lú Facebook', AppLanguage.hausa: 'Ci gaba da Facebook', AppLanguage.french: 'Continuer avec Facebook'},
    'alreadyHaveAccount': {AppLanguage.english: 'Already have an account?', AppLanguage.igbo: 'Ị nweelarị akaụntụ?', AppLanguage.yoruba: 'Ṣé o ti ní àkáǹtì?', AppLanguage.hausa: 'Kana da asusu tuni?', AppLanguage.french: 'Vous avez déjà un compte ?'},

    // ---- Profile --------------------------------------------------------
    'myProfile': {AppLanguage.english: 'My Profile', AppLanguage.igbo: 'Profaịlụ M', AppLanguage.yoruba: 'Àkọsílẹ̀ Mi', AppLanguage.hausa: 'Bayanan Martaba na', AppLanguage.french: 'Mon Profil'},
    'accountInformation': {AppLanguage.english: 'Account Information', AppLanguage.igbo: 'Ozi Akaụntụ', AppLanguage.yoruba: 'Àlàyé Àkáǹtì', AppLanguage.hausa: 'Bayanan Asusu', AppLanguage.french: 'Informations du compte'},
    'yourStatistics': {AppLanguage.english: 'Your Statistics', AppLanguage.igbo: 'Ọnụọgụ Gị', AppLanguage.yoruba: 'Àwọn Ìṣirò Rẹ', AppLanguage.hausa: 'Kididdigar ka', AppLanguage.french: 'Vos statistiques'},
    'activeListings': {AppLanguage.english: 'Active Listings', AppLanguage.igbo: 'Ndepụta Na-arụ Ọrụ', AppLanguage.yoruba: 'Àkọsílẹ̀ Tí Ń Ṣiṣẹ́', AppLanguage.hausa: 'Jerin masu aiki', AppLanguage.french: 'Annonces actives'},
    'totalViews': {AppLanguage.english: 'Total Views', AppLanguage.igbo: 'Mgbanwe Niile', AppLanguage.yoruba: 'Àpapọ̀ Wíwò', AppLanguage.hausa: 'Jimlar kallo', AppLanguage.french: 'Vues totales'},

    // ---- Dashboard ------------------------------------------------------
    'vendorDashboard': {AppLanguage.english: 'Vendor Dashboard', AppLanguage.igbo: 'Bọọdụ Onye Na-ere', AppLanguage.yoruba: 'Pátákó Olùtajà', AppLanguage.hausa: 'Allon Mai Sayarwa', AppLanguage.french: 'Tableau de bord vendeur'},
    'postAd': {AppLanguage.english: 'Post Ad', AppLanguage.igbo: 'Zipu Mgbasa Ozi', AppLanguage.yoruba: 'Fi Ìpolówó Ránṣẹ́', AppLanguage.hausa: 'Tura talla', AppLanguage.french: 'Publier une annonce'},
    'totalSales': {AppLanguage.english: 'Total Sales', AppLanguage.igbo: 'Ire Ahịa Niile', AppLanguage.yoruba: 'Àpapọ̀ Títà', AppLanguage.hausa: 'Jimlar sayarwa', AppLanguage.french: 'Ventes totales'},
    'overview': {AppLanguage.english: 'Overview', AppLanguage.igbo: 'Nchịkọta', AppLanguage.yoruba: 'Àkọsílẹ̀ Gbogbogbo', AppLanguage.hausa: 'Bayyani', AppLanguage.french: 'Aperçu'},
    'myListings': {AppLanguage.english: 'My Listings', AppLanguage.igbo: 'Ndepụta M', AppLanguage.yoruba: 'Àwọn Àkọsílẹ̀ Mi', AppLanguage.hausa: 'Jerina', AppLanguage.french: 'Mes annonces'},
    'analytics': {AppLanguage.english: 'Analytics', AppLanguage.igbo: 'Nyocha', AppLanguage.yoruba: 'Ìtúpalẹ̀', AppLanguage.hausa: 'Bincike', AppLanguage.french: 'Analytique'},
    'recentActivity': {AppLanguage.english: 'Recent Activity', AppLanguage.igbo: 'Ọrụ Ndị Na-adịbeghị Anya', AppLanguage.yoruba: 'Ìgbòkègbodò Àìpẹ́', AppLanguage.hausa: 'Ayyukan kwanan nan', AppLanguage.french: 'Activité récente'},
    'quickActions': {AppLanguage.english: 'Quick Actions', AppLanguage.igbo: 'Omume Ngwa Ngwa', AppLanguage.yoruba: 'Ìgbésẹ̀ Kíákíá', AppLanguage.hausa: 'Ayyuka masu sauri', AppLanguage.french: 'Actions rapides'},

    // ---- Settings -------------------------------------------------------
    'notifications': {AppLanguage.english: 'Notifications', AppLanguage.igbo: 'Ọkwa', AppLanguage.yoruba: 'Àwọn Ìtàníjí', AppLanguage.hausa: 'Sanarwa', AppLanguage.french: 'Notifications'},
    'privacySecurity': {AppLanguage.english: 'Privacy & Security', AppLanguage.igbo: 'Nzuzo & Nchekwa', AppLanguage.yoruba: 'Àṣírí àti Ààbò', AppLanguage.hausa: 'Sirri da Tsaro', AppLanguage.french: 'Confidentialité et sécurité'},
    'changePassword': {AppLanguage.english: 'Change Password', AppLanguage.igbo: 'Gbanwee Okwuntughe', AppLanguage.yoruba: 'Yí Ọ̀rọ̀ Ìgbaniwọlé Padà', AppLanguage.hausa: 'Canja kalmar sirri', AppLanguage.french: 'Changer le mot de passe'},
    'languageRegion': {AppLanguage.english: 'Language & Region', AppLanguage.igbo: 'Asụsụ & Mpaghara', AppLanguage.yoruba: 'Èdè àti Agbègbè', AppLanguage.hausa: 'Harshe da Yanki', AppLanguage.french: 'Langue et région'},
    'language': {AppLanguage.english: 'Language', AppLanguage.igbo: 'Asụsụ', AppLanguage.yoruba: 'Èdè', AppLanguage.hausa: 'Harshe', AppLanguage.french: 'Langue'},
    'currency': {AppLanguage.english: 'Currency', AppLanguage.igbo: 'Ego', AppLanguage.yoruba: 'Owó', AppLanguage.hausa: 'Kuɗi', AppLanguage.french: 'Devise'},
    'termsOfService': {AppLanguage.english: 'Terms of Service', AppLanguage.igbo: 'Usoro Ọrụ', AppLanguage.yoruba: 'Àwọn Òfin Iṣẹ́', AppLanguage.hausa: 'Sharuɗɗan Sabis', AppLanguage.french: 'Conditions d\'utilisation'},
    'privacyPolicy': {AppLanguage.english: 'Privacy Policy', AppLanguage.igbo: 'Amụma Nzuzo', AppLanguage.yoruba: 'Ìlànà Àṣírí', AppLanguage.hausa: 'Manufar Sirri', AppLanguage.french: 'Politique de confidentialité'},
    'helpSupport': {AppLanguage.english: 'Help & Support', AppLanguage.igbo: 'Enyemaka & Nkwado', AppLanguage.yoruba: 'Ìrànlọ́wọ́ àti Àtìlẹ́yìn', AppLanguage.hausa: 'Taimako da Tallafi', AppLanguage.french: 'Aide et assistance'},
    'dangerZone': {AppLanguage.english: 'Danger Zone', AppLanguage.igbo: 'Mpaghara Ihe Egwu', AppLanguage.yoruba: 'Agbègbè Ewu', AppLanguage.hausa: 'Yankin Hatsari', AppLanguage.french: 'Zone de danger'},
    'deleteAccount': {AppLanguage.english: 'Delete Account', AppLanguage.igbo: 'Hichapụ Akaụntụ', AppLanguage.yoruba: 'Pa Àkáǹtì Rẹ́', AppLanguage.hausa: 'Share Asusu', AppLanguage.french: 'Supprimer le compte'},

    // ---- KYC --------------------------------------------------------------
    'kycVerification': {AppLanguage.english: 'KYC Verification', AppLanguage.igbo: 'Nnwapụta KYC', AppLanguage.yoruba: 'Ìmúdájú KYC', AppLanguage.hausa: 'Tabbatar da KYC', AppLanguage.french: 'Vérification KYC'},
    'secureAccount': {AppLanguage.english: 'Secure your account', AppLanguage.igbo: 'Chekwaa akaụntụ gị', AppLanguage.yoruba: 'Dáàbò bo àkáǹtì rẹ', AppLanguage.hausa: 'Kare asusun ka', AppLanguage.french: 'Sécurisez votre compte'},
    'verificationProgress': {AppLanguage.english: 'Verification Progress', AppLanguage.igbo: 'Ọganihu Nnwapụta', AppLanguage.yoruba: 'Ìtẹ̀síwájú Ìmúdájú', AppLanguage.hausa: 'Ci gaban tabbatarwa', AppLanguage.french: 'Progression de la vérification'},
    'emailVerification': {AppLanguage.english: 'Email Verification', AppLanguage.igbo: 'Nnwapụta Email', AppLanguage.yoruba: 'Ìmúdájú Ímeèlì', AppLanguage.hausa: 'Tabbatar da Imel', AppLanguage.french: 'Vérification de l\'e-mail'},
    'phoneVerification': {AppLanguage.english: 'Phone Verification', AppLanguage.igbo: 'Nnwapụta Ekwentị', AppLanguage.yoruba: 'Ìmúdájú Fóònù', AppLanguage.hausa: 'Tabbatar da Waya', AppLanguage.french: 'Vérification du téléphone'},
    'identityVerification': {AppLanguage.english: 'Identity Verification', AppLanguage.igbo: 'Nnwapụta Njirimara', AppLanguage.yoruba: 'Ìmúdájú Ìdánimọ̀', AppLanguage.hausa: 'Tabbatar da Shaida', AppLanguage.french: 'Vérification d\'identité'},
    'businessVerification': {AppLanguage.english: 'Business Verification', AppLanguage.igbo: 'Nnwapụta Azụmahịa', AppLanguage.yoruba: 'Ìmúdájú Òwò', AppLanguage.hausa: 'Tabbatar da Kasuwanci', AppLanguage.french: 'Vérification de l\'entreprise'},
    'continueToSubscription': {AppLanguage.english: 'Continue to Subscription', AppLanguage.igbo: 'Gaa N\'ihu Na Ndenye Aha', AppLanguage.yoruba: 'Tẹ̀síwájú sí Ìforúkọsílẹ̀', AppLanguage.hausa: 'Ci gaba zuwa biyan kuɗi', AppLanguage.french: 'Continuer vers l\'abonnement'},

    // ---- Favorites ----------------------------------------------------
    'myFavorites': {AppLanguage.english: 'My Favorites', AppLanguage.igbo: 'Ihe M Hụrụ N\'anya', AppLanguage.yoruba: 'Àwọn Ayanfẹ́ Mi', AppLanguage.hausa: 'Abubuwan da nake so', AppLanguage.french: 'Mes favoris'},
    'noFavoritesYet': {AppLanguage.english: 'No Favorites Yet', AppLanguage.igbo: 'Ọ Nwebeghị Ihe Ị Hụrụ N\'anya', AppLanguage.yoruba: 'Kò Sí Ayanfẹ́ Síbẹ̀', AppLanguage.hausa: 'Babu abubuwan so tukuna', AppLanguage.french: 'Aucun favori pour le moment'},
    'saveItemsLater': {AppLanguage.english: 'Save items you like to view them later', AppLanguage.igbo: 'Chekwaa ihe ị masịrị ka ị hụ ha ma emesịa', AppLanguage.yoruba: 'Fi àwọn nǹkan tí o fẹ́ràn pamọ́ láti wò wọ́n nígbà mìíràn', AppLanguage.hausa: 'Ajiye abubuwan da kake so don kallon su daga baya', AppLanguage.french: 'Enregistrez les articles que vous aimez pour les revoir plus tard'},
    'startShopping': {AppLanguage.english: 'Start Shopping', AppLanguage.igbo: 'Bido Ịzụ Ahịa', AppLanguage.yoruba: 'Bẹ̀rẹ̀ Rírajà', AppLanguage.hausa: 'Fara siyayya', AppLanguage.french: 'Commencer les achats'},
  };

  static String t(String key, AppLanguage lang, {String? fallback}) {
    return _table[key]?[lang] ?? _table[key]?[AppLanguage.english] ?? fallback ?? key;
  }

  /// Converts a backend category name (e.g. "Sharp Sand") into its
  /// translation key ("cat_sharp_sand") and looks it up; falls back to
  /// the original name untranslated if this category isn't in the table
  /// (e.g. a brand-new category an admin just added).
  static String translateCategory(String name, AppLanguage lang) {
    final key = 'cat_${name.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
    return t(key, lang, fallback: name);
  }
}
