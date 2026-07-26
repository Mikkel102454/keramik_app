// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get languageName => 'Dansk';

  @override
  String get appTitle => 'Keramik';

  @override
  String get cancel => 'Annuller';

  @override
  String get save => 'Gem';

  @override
  String get delete => 'Slet';

  @override
  String get retry => 'Prøv igen';

  @override
  String get tryAgain => 'Prøv igen';

  @override
  String get add => 'Tilføj';

  @override
  String get create => 'Opret';

  @override
  String get edit => 'Rediger';

  @override
  String get remove => 'Fjern';

  @override
  String get send => 'Send';

  @override
  String get accept => 'Acceptér';

  @override
  String get decline => 'Afvis';

  @override
  String get restore => 'Gendan';

  @override
  String get clear => 'Ryd';

  @override
  String get ok => 'OK';

  @override
  String get loading => 'Indlæser…';

  @override
  String get loadMore => 'Indlæs flere';

  @override
  String get pleaseWait => 'Vent venligst…';

  @override
  String get noMessages => 'Ingen beskeder';

  @override
  String errorWithDetails(String details) {
    return 'Fejl: $details';
  }

  @override
  String get stageIdeas => 'Idéer';

  @override
  String get stageThrown => 'Drejet';

  @override
  String get stageTrimmed => 'Afdrejet';

  @override
  String get stageBisqued => 'Forglødnet';

  @override
  String get stageGlazed => 'Glaseret';

  @override
  String get stageFinished => 'Færdig';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Lys';

  @override
  String get themeDark => 'Mørk';

  @override
  String get measurementMetric => 'Metrisk';

  @override
  String get measurementImperial => 'Britisk/amerikansk';

  @override
  String get privacyEveryone => 'Alle';

  @override
  String get privacyFriends => 'Venner';

  @override
  String get privacyFriendsOfFriends => 'Venners venner';

  @override
  String get privacyNoOne => 'Ingen';

  @override
  String get settingsLoadFailed =>
      'Indstillingerne kunne ikke indlæses. Kontrollér forbindelsen, og prøv igen.';

  @override
  String get settingSaveFailed =>
      'Indstillingen kunne ikke gemmes. Dit tidligere valg er gendannet.';

  @override
  String get settingsAndPrivacy => 'Indstillinger og privatliv';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get editProfile => 'Rediger profil';

  @override
  String get accountInformation => 'Kontooplysninger';

  @override
  String get passwordAndSecurity => 'Adgangskode og sikkerhed';

  @override
  String get downloadYourData => 'Download dine data';

  @override
  String get deleteAccount => 'Slet konto';

  @override
  String get settingsPrivacy => 'Privatliv';

  @override
  String get discoverability => 'Synlighed';

  @override
  String get whoCanDiscover => 'Hvem kan finde din konto?';

  @override
  String get friendRequests => 'Venneanmodninger';

  @override
  String get whoCanSendFriendRequests => 'Hvem kan sende venneanmodninger?';

  @override
  String get messages => 'Beskeder';

  @override
  String get whoCanSendMessageRequests => 'Hvem kan sende beskedanmodninger?';

  @override
  String get blockedAccounts => 'Blokerede konti';

  @override
  String get contentAndDisplay => 'Indhold og visning';

  @override
  String get notifications => 'Notifikationer';

  @override
  String get appearance => 'Udseende';

  @override
  String get units => 'Enheder';

  @override
  String get language => 'Sprog';

  @override
  String get supportAndAbout => 'Hjælp og om';

  @override
  String get websiteHelpCenter => 'Hjælpecenter på webstedet';

  @override
  String get privacyInformation => 'Oplysninger om privatliv';

  @override
  String get aboutKeramik => 'Om Keramik';

  @override
  String get loginSection => 'Login';

  @override
  String get logOut => 'Log ud';

  @override
  String get loggingOut => 'Logger ud…';

  @override
  String get logOutQuestion => 'Log ud?';

  @override
  String get logOutExplanation =>
      'Du kan logge ind igen med din e-mail eller dit brugernavn.';

  @override
  String get logoutFailed =>
      'Log ud mislykkedes. Din session er stadig aktiv; prøv igen.';

  @override
  String get linkOpenFailed => 'Linket kunne ikke åbnes.';

  @override
  String get currentLanguage => 'Nuværende sprog';

  @override
  String get languageSaveFailed =>
      'Sproget kunne ikke gemmes. Dit tidligere sprog er gendannet.';

  @override
  String get username => 'Brugernavn';

  @override
  String get name => 'Navn';

  @override
  String get publicUserId => 'Offentligt bruger-id';

  @override
  String get accountInformationPrivacyNote =>
      'Dit offentlige bruger-id bruges til profillinks og kan ikke ændres.';

  @override
  String get accountInformationLoadFailed =>
      'Kontooplysningerne kunne ikke indlæses.';

  @override
  String get accountEmailPrivacyNote =>
      'Din e-mailadresse er privat. Af sikkerhedshensyn håndteres ændringer af kontoens e-mail gennem support.';

  @override
  String get notSet => 'Ikke angivet';

  @override
  String get currentPassword => 'Nuværende adgangskode';

  @override
  String get newPassword => 'Ny adgangskode';

  @override
  String get confirmNewPassword => 'Bekræft ny adgangskode';

  @override
  String get passwordLengthHelp => 'Brug 8–128 tegn.';

  @override
  String get changePassword => 'Skift adgangskode';

  @override
  String get websitePasswordPage => 'Brug webstedets adgangskodeside';

  @override
  String get passwordsDoNotMatch => 'De nye adgangskoder er ikke ens.';

  @override
  String get passwordChanged =>
      'Adgangskoden er ændret. Andre sessioner er logget ud.';

  @override
  String get passwordChangeFailed =>
      'Adgangskoden kunne ikke ændres. Prøv igen.';

  @override
  String get dataExportDescription =>
      'Din ZIP-fil indeholder JSON-/CSV-poster, indstillinger, relationer, tilgængelige samtaledata samt profil-, keramik- og lerbilleder gemt på serveren.';

  @override
  String get dataExportLimit =>
      'Der kan kun køre én eksport ad gangen. Færdige pakker udløber efter syv dage.';

  @override
  String get exportRequestFailed => 'Eksporten kunne ikke bestilles.';

  @override
  String get exportRefreshFailed => 'Eksportstatus kunne ikke opdateres.';

  @override
  String get exportDownloadFailed =>
      'ZIP-filen kunne ikke downloades eller åbnes.';

  @override
  String availableUntil(String date) {
    return 'Tilgængelig indtil $date';
  }

  @override
  String get refreshStatus => 'Opdater status';

  @override
  String get downloadZip => 'Download ZIP';

  @override
  String get createExport => 'Opret eksport';

  @override
  String get exportQueued => 'Eksporten er sat i kø';

  @override
  String get exportCreating => 'Opretter din eksport';

  @override
  String get exportReady => 'Eksporten er klar';

  @override
  String get exportExpired => 'Eksporten er udløbet';

  @override
  String get exportFailed => 'Eksporten mislykkedes';

  @override
  String get deletionScheduleFailed =>
      'Sletningen kunne ikke planlægges. Prøv igen.';

  @override
  String get deletionCancellationPeriod =>
      'Sletning starter en annulleringsperiode på 30 dage.';

  @override
  String get deletionSignOutExplanation =>
      'Du bliver straks logget ud overalt og kan ikke bruge appens almindelige funktioner. Log ind igen inden for de næste 30 dage for at annullere sletningen eller logge ud.';

  @override
  String get deletionRetentionExplanation =>
      'Efter 30 dage slettes privat identitet, journal- og materialedata samt ejede medier. En deaktiveret pseudonym konto og delte chat-, rapport-, revisions- og sikkerhedsdata bevares på ubestemt tid. Andre medlemmer vil se “Slettet medlem”.';

  @override
  String get deletionUnderstand => 'Jeg forstår, hvad der slettes og bevares.';

  @override
  String get typeDeleteToConfirm => 'Skriv DELETE for at bekræfte';

  @override
  String get scheduleAccountDeletion => 'Planlæg sletning af konto';

  @override
  String get directMessages => 'Direkte beskeder';

  @override
  String get messageRequests => 'Beskedanmodninger';

  @override
  String get groupActivity => 'Gruppeaktivitet';

  @override
  String get pushNotifications => 'Pushnotifikationer';

  @override
  String get pushNotificationsComingLater =>
      'Kommer senere. Keramik leverer ikke notifikationer, mens appen er sat på pause.';

  @override
  String get blockedAccountsLoadFailed =>
      'Blokerede konti kunne ikke indlæses.';

  @override
  String accountUnblockFailed(String username) {
    return '$username kunne ikke fjernes fra blokeringen.';
  }

  @override
  String get noBlockedAccounts => 'Du har ikke blokeret nogen konti.';

  @override
  String get unblock => 'Fjern blokering';

  @override
  String get welcomeBack => 'Velkommen tilbage';

  @override
  String get signInToAccount => 'Log ind på din konto';

  @override
  String get emailOrUsername => 'E-mail eller brugernavn';

  @override
  String get password => 'Adgangskode';

  @override
  String get forgotPassword => 'Glemt adgangskode';

  @override
  String get logIn => 'Log ind';

  @override
  String get accountDeletionPending => 'Kontosletning afventer';

  @override
  String get accountDeletionPendingExplanation =>
      'Almindelig aktivitet er begrænset i perioden på 30 dage. Annuller sletningen for at gendanne kontoen, eller log ud.';

  @override
  String get cancelDeletion => 'Annuller sletning';

  @override
  String get signOut => 'Log ud';

  @override
  String get or => 'ELLER';

  @override
  String get noAccountQuestion => 'Har du ikke en konto? ';

  @override
  String get signUp => 'Opret konto';

  @override
  String get materials => 'Materialer';

  @override
  String get clays => 'Lertyper';

  @override
  String get glazes => 'Glasurer';

  @override
  String get navigationHome => 'Hjem';

  @override
  String get navigationMaterials => 'Materialer';

  @override
  String get navigationShop => 'Butik';

  @override
  String get navigationChats => 'Chats';

  @override
  String get navigationProfile => 'Profil';

  @override
  String get ceramicJournal => 'Keramikjournal';

  @override
  String get journalLoadFailed => 'Vi kunne ikke indlæse din keramikjournal.';

  @override
  String get createCeramic => 'Opret keramik';

  @override
  String get journalSearchHint =>
      'Søg i titler, noter, mærker, ler eller glasur';

  @override
  String get clearSearch => 'Ryd søgning';

  @override
  String get filters => 'Filtre';

  @override
  String get descending => 'Faldende';

  @override
  String get ascending => 'Stigende';

  @override
  String pieceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count emner',
      one: '1 emne',
      zero: 'Ingen emner',
    );
    return '$_temp0';
  }

  @override
  String get unknownStage => 'Ukendt trin';

  @override
  String get filterJournal => 'Filtrer journal';

  @override
  String get stage => 'Trin';

  @override
  String get clay => 'Ler';

  @override
  String get glaze => 'Glasur';

  @override
  String get minimumRating => 'Mindste bedømmelse';

  @override
  String get tags => 'Mærker';

  @override
  String get sortRecentlyUpdated => 'Senest opdateret';

  @override
  String get title => 'Titel';

  @override
  String get rating => 'Bedømmelse';

  @override
  String get creationDate => 'Oprettelsesdato';

  @override
  String get startCeramicJournal => 'Start din keramikjournal';

  @override
  String get emptyJournalDescription =>
      'Gem dit første emne, materialer, proces og resultater.';

  @override
  String get createFirstPiece => 'Opret dit første emne';

  @override
  String get noMatchingPieces => 'Ingen emner matcher';

  @override
  String get clearSearchAndFilters => 'Ryd søgning og filtre';

  @override
  String get ceramic => 'Keramik';

  @override
  String get progress => 'Fremskridt';

  @override
  String get information => 'Oplysninger';

  @override
  String get clayType => 'Lertype';

  @override
  String get select => 'Vælg';

  @override
  String get weight => 'Vægt';

  @override
  String get dimensions => 'Mål';

  @override
  String optionalMeasurementSystem(String system) {
    return 'Valgfrit · $system';
  }

  @override
  String get height => 'Højde';

  @override
  String get width => 'Bredde';

  @override
  String get depth => 'Dybde';

  @override
  String get diameter => 'Diameter';

  @override
  String get glazeApplications => 'Glasurlag';

  @override
  String get rate => 'Bedøm';

  @override
  String get notes => 'Noter';

  @override
  String get projectNotes => 'Projektnoter';

  @override
  String get outcome => 'Resultat';

  @override
  String get optionalResultNotes => 'Valgfrie resultatnoter';

  @override
  String get outcomeHint => 'Hvordan blev emnet?';

  @override
  String get selectFromGallery => 'Vælg fra galleri';

  @override
  String get takePicture => 'Tag et billede';

  @override
  String get titleValidation => 'Angiv en titel på højst 255 tegn';

  @override
  String get invalidStage => 'Ugyldigt trin valgt';

  @override
  String get ceramicFieldsInvalid =>
      'Kontrollér bedømmelse, vægt og notelængder, før du gemmer.';

  @override
  String get addFiring => 'Tilføj brænding';

  @override
  String get editFiring => 'Rediger brænding';

  @override
  String get status => 'Status';

  @override
  String get planned => 'Planlagt';

  @override
  String get completed => 'Fuldført';

  @override
  String get firingType => 'Brændingstype';

  @override
  String get firingBisque => 'Forglødning';

  @override
  String get firingGlaze => 'Glasurbrænding';

  @override
  String get firingSingle => 'Enkeltbrænding';

  @override
  String get firingOverglaze => 'Overglasur / lustre';

  @override
  String get other => 'Andet';

  @override
  String get firingDate => 'Brændingsdato';

  @override
  String get targetCone => 'Målkegle';

  @override
  String get targetTemperature => 'Måltemperatur';

  @override
  String get observedCone => 'Observeret kegle';

  @override
  String get peakTemperature => 'Maksimal temperatur';

  @override
  String get kiln => 'Ovn';

  @override
  String get program => 'Program';

  @override
  String get firingNote => 'Brændingsnote';

  @override
  String get firingSaveFailed => 'Brændingen kunne ikke gemmes. Prøv igen.';

  @override
  String get noGlazeApplications => 'Ingen glasurlag endnu.';

  @override
  String coatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lag',
      one: '1 lag',
    );
    return '$_temp0';
  }

  @override
  String get moveUp => 'Flyt op';

  @override
  String get moveDown => 'Flyt ned';

  @override
  String get removeApplication => 'Fjern lag';

  @override
  String get addGlazeApplication => 'Tilføj glasurlag';

  @override
  String get unknownGlaze => 'Ukendt glasur';

  @override
  String get coatCountLabel => 'Antal lag';

  @override
  String get applicationNote => 'Påføringsnote';

  @override
  String get coatMinimum => 'Angiv mindst ét lag.';

  @override
  String get glazeApplicationSaveFailed =>
      'Glasurlaget kunne ikke gemmes. Prøv igen.';

  @override
  String get deleteCeramic => 'Slet keramik';

  @override
  String get deleteCeramicQuestion =>
      'Er du sikker på, at du vil slette denne keramik?';

  @override
  String get deleteCeramicFailed => 'Keramikken kunne ikke slettes.';

  @override
  String get firings => 'Brændinger';

  @override
  String firingRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count poster',
      one: '1 post',
      zero: 'Ingen poster',
    );
    return '$_temp0';
  }

  @override
  String get noFiringRecords => 'Ingen brændingsposter endnu.';

  @override
  String coneValue(String cone) {
    return 'Kegle $cone';
  }

  @override
  String get deleteFiring => 'Slet brænding';

  @override
  String get history => 'Historik';

  @override
  String stageEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trinhændelser',
      one: '1 trinhændelse',
      zero: 'Ingen trinhændelser',
    );
    return '$_temp0';
  }

  @override
  String updatedOn(String date) {
    return 'Opdateret $date';
  }

  @override
  String historyStartedAt(String stage) {
    return 'Historikken startede ved $stage';
  }

  @override
  String startedAtStage(String stage) {
    return 'Startede ved $stage';
  }

  @override
  String stageTransition(String fromStage, String toStage) {
    return '$fromStage → $toStage';
  }

  @override
  String get deleteFiringQuestion => 'Slet brændingspost?';

  @override
  String deleteFiringExplanation(String type) {
    return 'Dette fjerner permanent posten for $type.';
  }

  @override
  String get deleteFiringFailed => 'Brændingsposten kunne ikke slettes.';

  @override
  String get bisqueFiring => 'Forglødning';

  @override
  String get glazeFiring => 'Glasurbrænding';

  @override
  String get singleFiring => 'Enkeltbrænding';

  @override
  String get overglazeFiring => 'Overglasur-/lustrebrænding';

  @override
  String get otherFiring => 'Anden brænding';

  @override
  String get clayBodies => 'Lertyper';

  @override
  String get clayBody => 'Lertype';

  @override
  String get supplier => 'Leverandør';

  @override
  String get clayNotes => 'Lernoter';

  @override
  String get materialFieldsTooLong =>
      'Leverandør og noter må højst være 255 tegn.';

  @override
  String get deleteClay => 'Slet ler';

  @override
  String get deleteClayQuestion =>
      'Er du sikker på, at du vil slette denne lertype?';

  @override
  String get deleteClayFailed => 'Lertypen kunne ikke slettes.';

  @override
  String get enterTitle => 'Angiv en titel';

  @override
  String get deleteGlaze => 'Slet glasur';

  @override
  String get deleteGlazeQuestion =>
      'Er du sikker på, at du vil slette denne glasur?';

  @override
  String get glazeCannotDelete => 'Glasuren kan ikke slettes';

  @override
  String get deleteImageQuestion => 'Slet billede?';

  @override
  String get cannotUndo => 'Denne handling kan ikke fortrydes.';

  @override
  String get tag => 'Mærke';

  @override
  String get chats => 'Chats';

  @override
  String get searchAccounts => 'Søg efter konti';

  @override
  String get newGroup => 'Ny gruppe';

  @override
  String get archivedChats => 'Arkiverede chats';

  @override
  String get noArchivedChats => 'Ingen arkiverede chats.';

  @override
  String get requests => 'Anmodninger';

  @override
  String waitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count venter',
      one: '1 venter',
      zero: 'Ingen venter',
    );
    return '$_temp0';
  }

  @override
  String get noMessageRequests => 'Ingen beskedanmodninger.';

  @override
  String messageUser(String username) {
    return 'Skriv til $username';
  }

  @override
  String get messageRequestPreviewExplanation =>
      'Du kan sende én forhåndsvisning. Du kan sende flere beskeder, når modtageren har accepteret.';

  @override
  String get writeMessageRequest => 'Skriv en beskedanmodning…';

  @override
  String get sendRequest => 'Send anmodning';

  @override
  String get groupName => 'Gruppenavn';

  @override
  String selectFriendsMemberCount(int count) {
    return 'Vælg venner · $count/50 medlemmer';
  }

  @override
  String get addFriendBeforeGroup =>
      'Tilføj en ven, før du opretter en gruppe.';

  @override
  String get addMembers => 'Tilføj medlemmer';

  @override
  String chooseFriendsLimit(int count) {
    return 'Vælg op til $count af dine venner. Eksisterende medlemmer afvises sikkert.';
  }

  @override
  String get reportMessage => 'Rapportér besked';

  @override
  String get reportReasonQuestion => 'Hvorfor rapporterer du denne besked?';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportHarassment => 'Chikane';

  @override
  String get reportHate => 'Had';

  @override
  String get reportSexualContent => 'Seksuelt indhold';

  @override
  String get reportViolence => 'Vold';

  @override
  String get reportChooseReason => 'Vælg en årsag til rapporteringen.';

  @override
  String get reportOtherExplanationRequired =>
      'Tilføj en forklaring, når du vælger Andet.';

  @override
  String get reportExplanationTooLong =>
      'Forklaringen må højst indeholde 1000 tegn.';

  @override
  String get reportExplanationOptional => 'Forklaring (valgfri)';

  @override
  String get reportExplanationHint =>
      'Tilføj oplysninger, der kan hjælpe ved en senere gennemgang.';

  @override
  String get messageBeingReported => 'Besked, der rapporteres';

  @override
  String get reportEvidenceDisclosure =>
      'Den valgte besked og op til to nærliggende beskeder på hver side inkluderes sikkert til gennemgang. Rapportering blokerer ikke kontoen og ændrer ikke samtalen.';

  @override
  String get submitReport => 'Send rapport';

  @override
  String get all => 'Alle';

  @override
  String get unread => 'Ulæste';

  @override
  String get groups => 'Grupper';

  @override
  String get noGroupChats => 'Ingen gruppechats endnu.';

  @override
  String get noUnreadChats => 'Ingen ulæste chats.';

  @override
  String get noConversations =>
      'Ingen samtaler endnu. Søg efter en konto for at komme i gang.';

  @override
  String get noMessagesYet => 'Ingen beskeder endnu';

  @override
  String get now => 'nu';

  @override
  String relativeMinutes(int count) {
    return '$count min.';
  }

  @override
  String relativeHours(int count) {
    return '$count t.';
  }

  @override
  String relativeDays(int count) {
    return '$count d.';
  }

  @override
  String accountBlocked(String username) {
    return '$username er blokeret';
  }

  @override
  String get undo => 'Fortryd';

  @override
  String get received => 'Modtaget';

  @override
  String get sent => 'Sendt';

  @override
  String get noReceivedRequests => 'Ingen modtagne anmodninger.';

  @override
  String get noSentRequests => 'Ingen sendte anmodninger.';

  @override
  String get requestSent => 'Anmodning sendt';

  @override
  String get wantsToBeFriends => 'Vil gerne være venner';

  @override
  String get comingLater => 'Kommer senere';

  @override
  String get renameGroup => 'Omdøb gruppe';

  @override
  String get leaveGroupQuestion => 'Forlad gruppen?';

  @override
  String get leaveGroupExplanation =>
      'Du beholder skrivebeskyttet historik fra dine medlemsperioder.';

  @override
  String get leave => 'Forlad';

  @override
  String get leaveGroup => 'Forlad gruppe';

  @override
  String get reportSubmitted =>
      'Rapporten er indsendt. Blokering er en separat handling.';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medlemmer',
      one: '1 medlem',
    );
    return '$_temp0';
  }

  @override
  String get archiveChat => 'Arkivér chat';

  @override
  String get conversationReadOnly => 'Denne samtale er skrivebeskyttet.';

  @override
  String get startConversation => 'Start samtalen.';

  @override
  String get loadEarlierMessages => 'Indlæs tidligere beskeder';

  @override
  String get messageActionsHint => 'Hold nede for beskedhandlinger';

  @override
  String get today => 'I dag';

  @override
  String get voiceMessageComingLater => 'Talebesked — kommer senere';

  @override
  String get messageHint => 'Besked…';

  @override
  String get emojiComingLater => 'Emoji — kommer senere';

  @override
  String get imageComingLater => 'Billede — kommer senere';

  @override
  String get profile => 'Profil';

  @override
  String get removeFriendQuestion => 'Fjern ven?';

  @override
  String removeFriendExplanation(String username) {
    return 'Du og $username vil ikke længere være venner.';
  }

  @override
  String blockUserQuestion(String username) {
    return 'Bloker $username?';
  }

  @override
  String get blockExplanation =>
      'I forsvinder fra hinandens søgning, profiler, vennelister og anmodninger. Eksisterende venskab og anmodninger annulleres.';

  @override
  String get block => 'Bloker';

  @override
  String get sendFriendRequest => 'Send venneanmodning';

  @override
  String get acceptRequest => 'Acceptér anmodning';

  @override
  String get declineRequest => 'Afvis anmodning';

  @override
  String get message => 'Besked';

  @override
  String get sendMessageRequest => 'Send beskedanmodning';

  @override
  String get removeFriend => 'Fjern ven';

  @override
  String get blockAccount => 'Bloker konto';

  @override
  String get relationshipFriends => 'Venner';

  @override
  String get friendRequestSent => 'Venneanmodning sendt';

  @override
  String get previouslyDeclined => 'Du har tidligere afvist denne anmodning';

  @override
  String get friendRequestDeclined => 'Venneanmodning afvist';

  @override
  String get account => 'Konto';

  @override
  String get friend => 'Ven';

  @override
  String get incomingRequest => 'Indgående anmodning';

  @override
  String get searchFriends => 'Søg blandt venner';

  @override
  String get noFriendsFound => 'Ingen venner fundet.';

  @override
  String get searchMinimumCharacters =>
      'Indtast mindst 3 tegn for at søge efter konti.';

  @override
  String get noAccountsFound => 'Ingen konti fundet.';

  @override
  String get accounts => 'Konti';

  @override
  String get finishedPieces => 'Færdige emner';

  @override
  String get finishedPiecesEmpty => 'Emner, der flyttes til Færdig, vises her.';

  @override
  String get viewPhoto => 'Se billede';

  @override
  String get takePhoto => 'Tag billede';

  @override
  String get uploadPhoto => 'Upload billede';

  @override
  String get chooseFromGallery => 'Vælg fra galleri';

  @override
  String get removePhoto => 'Fjern billede';

  @override
  String get changePhoto => 'Skift billede';

  @override
  String get profilePhotoPrivacy =>
      'Profilbilleder er offentlige. Cachede kopier kan blive liggende efter fjernelse.';

  @override
  String get forename => 'Fornavn';

  @override
  String get surname => 'Efternavn';

  @override
  String get readOnlyFields =>
      'Disse felter er skrivebeskyttede indtil videre.';

  @override
  String get profilePhoto => 'Profilbillede';

  @override
  String get photoLoadFailed => 'Billedet kunne ikke indlæses';

  @override
  String get shareCeramic => 'Del keramik';

  @override
  String get shareCeramicDisclosure =>
      'Hele journalopslaget, herunder noter, billeder og fremtidige ændringer, bliver synligt for alle, der kan se denne samtalebesked.';

  @override
  String get share => 'Del';

  @override
  String get chooseCeramic => 'Vælg keramik';

  @override
  String get noCeramicsToShare => 'Du har endnu ingen keramik at dele.';

  @override
  String get shareToConversation => 'Del i en samtale';

  @override
  String get noWritableConversations =>
      'Der er ingen skrivbare samtaler. Gendan en arkiveret chat, eller tilslut dig en gruppe igen, før du deler.';

  @override
  String get directConversation => 'Direkte samtale';

  @override
  String get ceramicShared => 'Keramikken er delt.';

  @override
  String get ceramicUnavailable => 'Denne keramik er ikke længere tilgængelig.';

  @override
  String openSharedCeramic(String title) {
    return 'Åbn delt keramik $title';
  }

  @override
  String get sharedCeramic => 'Delt keramik';

  @override
  String get sharedCeramicLoadFailed =>
      'Den delte keramik kunne ikke indlæses.';

  @override
  String get ceramicMessagePreview => 'Delte keramik';

  @override
  String get reportCeramicEvidenceDisclosure =>
      'Den valgte keramik, alle synlige journalfelter, alle aktuelle billeder og op til to nærliggende beskeder på hver side kopieres sikkert til gennemgang. Bevismaterialet ændres ikke, hvis keramikken redigeres eller slettes. Rapportering blokerer ikke kontoen og ændrer ikke samtalen.';

  @override
  String get measurements => 'Mål';

  @override
  String get noTags => 'Ingen tags.';

  @override
  String get timestamps => 'Tidsstempler';

  @override
  String get created => 'Oprettet';

  @override
  String get updated => 'Opdateret';

  @override
  String get navigationDiscover => 'Opdag';

  @override
  String get discoverForYou => 'Til dig';

  @override
  String get discoverLatest => 'Nyeste';

  @override
  String get discoverEmpty => 'Der er endnu ingen udgivne keramikemner.';

  @override
  String get notInterestedAction => 'Ikke interesseret';

  @override
  String get likeAction => 'Synes godt om';

  @override
  String get publishFinishedTitle => 'Vil du udgive dette færdige emne?';

  @override
  String get publishFinishedBody =>
      'Udgivne emner kan vises under Opdag og på din profil. Op til 20 billeder og de angivne offentlige oplysninger bliver synlige.';

  @override
  String get publicationAudienceEveryone =>
      'Alle: Synligt for alle aktive medlemmer undtagen personer, du har blokeret, eller som har blokeret dig.';

  @override
  String get publicationAudienceFriends =>
      'Kun venner: Din nuværende privatlivsindstilling begrænser dette emne til accepterede venner. Blokering og kontoregler gælder stadig.';

  @override
  String get publishAction => 'Udgiv';

  @override
  String get notNowAction => 'Ikke nu';

  @override
  String get unpublishAction => 'Fjern udgivelse';

  @override
  String get publicationTemporarilyUnavailable =>
      'Udgivet, men skjult indtil emnet er Færdigt og har et billede.';

  @override
  String get publicationModerationRemoved =>
      'Fjernet af moderation. Du kan ikke udgive emnet igen, mens moderationslåsen er aktiv.';

  @override
  String get discoverSessionRefreshed => 'Anbefalingerne er opdateret.';

  @override
  String get publicationUnavailable =>
      'Det udgivne keramikemne er ikke tilgængeligt';

  @override
  String get publicationReportEvidenceDisclosure =>
      'De nuværende offentlige oplysninger og op til 20 synlige billeder gemmes sikkert til moderatorgennemgang. Rapportering skjuler denne udgivelse permanent for dig.';

  @override
  String get undoAction => 'Fortryd';

  @override
  String get reportPublication => 'Rapportér udgivelse';

  @override
  String get reportReason => 'Årsag';

  @override
  String get reportExplanation => 'Forklaring';

  @override
  String get createTemplate => 'Opret skabelon';

  @override
  String get editTemplate => 'Rediger skabelon';

  @override
  String get templateName => 'Skabelonnavn';

  @override
  String get templateTitlePattern => 'Titelmønster';

  @override
  String get templateTitlePatternHelp =>
      'Sæt n i krøllede parenteser, hvor batchnummeret skal stå.';

  @override
  String get noClay => 'Intet ler';

  @override
  String get commaSeparatedTags => 'Adskil tags med kommaer.';

  @override
  String get noTemplateGlazes => 'Ingen glasurplan.';

  @override
  String get plannedFirings => 'Planlagte brændinger';

  @override
  String get noTemplateFirings => 'Ingen brændingsplan.';

  @override
  String templateGlazeSummary(int coatCount, String note) {
    String _temp0 = intl.Intl.pluralLogic(
      coatCount,
      locale: localeName,
      other: '$coatCount lag',
      one: '1 lag',
    );
    String _temp1 = intl.Intl.selectLogic(note, {'other': ' · $note'});
    return '$_temp0$_temp1';
  }

  @override
  String get addPlannedFiring => 'Tilføj planlagt brænding';

  @override
  String get tooManyTemplateTags => 'En skabelon kan højst indeholde 30 tags.';

  @override
  String get requiredField => 'Feltet skal udfyldes.';

  @override
  String get invalidNumber => 'Indtast et gyldigt ikke-negativt tal.';

  @override
  String get createFromTemplate => 'Opret fra skabelon';

  @override
  String batchQuantity(int count) {
    return 'Antal: $count';
  }

  @override
  String get startNumber => 'Startnummer';

  @override
  String get titlePreview => 'Forhåndsvisning af titler';

  @override
  String get createOneCeramic => 'Opret keramik';

  @override
  String createCeramicBatch(int count) {
    return 'Opret $count keramikemner';
  }

  @override
  String get confirmBatchCreation => 'Opret denne batch?';

  @override
  String confirmBatchCreationBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nye keramikemner',
      one: 'ét nyt keramikemne',
    );
    return 'Dette opretter $_temp0 med ny journalhistorik.';
  }

  @override
  String get batchCreated => 'Batch oprettet';

  @override
  String batchCreatedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keramikemner blev oprettet.',
      one: 'Ét keramikemne blev oprettet.',
    );
    return '$_temp0';
  }

  @override
  String get projectTemplates => 'Projektskabeloner';

  @override
  String get duplicate => 'Dupliker';

  @override
  String templateGlazeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count glasurer',
      one: '1 glasur',
      zero: 'Ingen glasurer',
    );
    return '$_temp0';
  }

  @override
  String templateFiringCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brændinger',
      one: '1 brænding',
      zero: 'Ingen brændinger',
    );
    return '$_temp0';
  }

  @override
  String get templateMaterialMissing =>
      'Et tilknyttet materiale findes ikke længere. Rediger skabelonen, før den bruges.';

  @override
  String get useTemplate => 'Brug skabelon';

  @override
  String get duplicateTemplate => 'Dupliker skabelon';

  @override
  String copyOfTemplate(String name) {
    return 'Kopi af $name';
  }

  @override
  String get deleteTemplate => 'Slet skabelon?';

  @override
  String deleteTemplateBody(String name) {
    return 'Slet “$name”? Eksisterende keramik påvirkes ikke.';
  }

  @override
  String get noProjectTemplates => 'Ingen projektskabeloner endnu';

  @override
  String get noProjectTemplatesBody =>
      'Gem en genbrugelig plan fra et keramikemne, eller opret en fra bunden.';

  @override
  String get templatesLoadFailed =>
      'Vi kunne ikke indlæse dine projektskabeloner.';

  @override
  String get batchEdit => 'Batchredigering';

  @override
  String selectedCeramics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keramikemner valgt',
      one: '1 keramik valgt',
      zero: 'Ingen keramik valgt',
    );
    return '$_temp0';
  }

  @override
  String get batchEditSafetyNote =>
      'Afsluttet historik erstattes aldrig. Eksisterende glasurarbejde og modstridende brændingsplaner springes over.';

  @override
  String get batchBasics => 'Grundlæggende oplysninger';

  @override
  String get batchTagChanges => 'Tagændringer';

  @override
  String get batchDimensionsHelp =>
      'Udfyld kun de mål, der skal anvendes på alle valgte emner.';

  @override
  String get batchPlanningHelp =>
      'Planoplysninger tilføjes kun, når eksisterende arbejde kan bevares sikkert.';

  @override
  String get changeStage => 'Skift fase';

  @override
  String get keepCurrent => 'Behold nuværende værdi';

  @override
  String get changeClay => 'Skift ler';

  @override
  String get clearClay => 'Fjern ler';

  @override
  String get setClay => 'Vælg ler';

  @override
  String get addTags => 'Tilføj tags';

  @override
  String get removeTags => 'Fjern tags';

  @override
  String get applyDimensions => 'Anvend mål';

  @override
  String get applyPlanningTemplate => 'Anvend genbrugelige planoplysninger';

  @override
  String get projectTemplate => 'Projektskabelon';

  @override
  String get none => 'Ingen';

  @override
  String get applyGlazesOnlyWhenEmpty =>
      'Anvend kun glasurplanen, hvor der ikke findes glasurlag';

  @override
  String get applySafeFiringPlans =>
      'Tilføj brændingsplaner, som ikke er i konflikt med afsluttet arbejde';

  @override
  String get reviewBatchEdit => 'Gennemse batchredigering';

  @override
  String get chooseClay => 'Vælg et ler, der skal anvendes.';

  @override
  String get confirmBatchEdit => 'Bekræft batchredigering';

  @override
  String batchEditTargetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keramikemner',
      one: 'ét keramikemne',
    );
    return 'Denne redigering omfatter $_temp0.';
  }

  @override
  String get protectedItemsWillBeSkipped => 'Beskyttet arbejde springes over:';

  @override
  String get apply => 'Anvend';

  @override
  String get batchEditComplete => 'Batchredigering færdig';

  @override
  String get batchEditPartiallyComplete => 'Batchredigering delvist færdig';

  @override
  String batchEditResult(int updated, int skipped) {
    return '$updated opdateret · $skipped sprunget over eller uændret';
  }

  @override
  String get selectAllVisible => 'Vælg alle synlige';

  @override
  String get selectCeramics => 'Vælg keramik';

  @override
  String get reviewBatchDelete => 'Gennemse sletning';

  @override
  String batchDeleteTargetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keramikemner',
      one: 'ét keramikemne',
    );
    return 'Du er ved permanent at slette $_temp0.';
  }

  @override
  String get batchDeleteWarning =>
      'Keramikemnerne samt deres billeder, planer og journalhistorik fjernes. Handlingen kan ikke fortrydes.';

  @override
  String get understandPermanentDeletion =>
      'Jeg forstår, at de valgte keramikemner slettes permanent.';

  @override
  String deleteSelectedCeramics(int count) {
    return 'Slet $count';
  }

  @override
  String batchDeleteComplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keramikemner slettet.',
      one: '1 keramikemne slettet.',
    );
    return '$_temp0';
  }

  @override
  String get batchDeleteFailed => 'Sletningen mislykkedes';

  @override
  String get batchDeleteFailedBody =>
      'Intet blev slettet. Et emne kan være ændret siden gennemgangen. Genindlæs gennemgangen, og prøv igen.';

  @override
  String get createBlankCeramic => 'Opret et tomt keramikemne';

  @override
  String get saveAsTemplate => 'Gem som skabelon';

  @override
  String templateFromCeramic(String title) {
    return '$title-skabelon';
  }

  @override
  String get templateExcludesResults =>
      'Billeder, bedømmelser, resultater, afsluttede brændinger, fasehistorik og udgivelsesdata kopieres ikke.';

  @override
  String get templateSaved => 'Projektskabelonen er gemt.';

  @override
  String get practiceAnalytics => 'Praksisanalyse';

  @override
  String get practiceAnalyticsPrivate =>
      'Private indsigter kun fra din keramik';

  @override
  String get analyticsRefreshFailed =>
      'Den nyeste analyse kunne ikke indlæses. De tidligere resultater vises.';

  @override
  String get incompleteHistory => 'Noget tidshistorik er ufuldstændig';

  @override
  String incompleteHistoryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ældre keramikemner har kun basisregistreringer og er udeladt fra tidsmålingerne.',
      one:
          'Et ældre keramikemne har kun en basisregistrering og er udeladt fra tidsmålingerne.',
    );
    return '$_temp0';
  }

  @override
  String get last90Days => 'Seneste 90 dage';

  @override
  String get lastYear => 'Seneste år';

  @override
  String get allTime => 'Hele perioden';

  @override
  String get createdAndCompleted => 'Oprettet og færdiggjort';

  @override
  String createdCompletedSummary(int created, int completed) {
    return '$created oprettet · $completed færdiggjort';
  }

  @override
  String get createdCompletedExplanation =>
      'Oprettet bruger keramikemnets oprettelsesdato. Færdiggjort bruger den første pålidelige overgang til Færdig. Ældre registreringer, der kun har et udgangspunkt, tælles ikke som færdiggørelser.';

  @override
  String get noTrustedActivityData =>
      'Der findes ingen pålidelige aktivitetsdata i perioden.';

  @override
  String get currentStages => 'Aktuelle faser';

  @override
  String get currentStagesExplanation =>
      'Tæller den aktuelle fase for dine keramikemner, der er oprettet i den valgte periode. Andre brugeres keramik og Opdag-indhold medtages ikke.';

  @override
  String get practiceTiming => 'Tid i praksis';

  @override
  String get practiceTimingExplanation =>
      'Oprettelse til Færdig måler fra oprettelse til den første pålidelige overgang til Færdig. Tid i en fase måler afsluttede besøg mellem registrerede overgange. Åbne besøg og ældre basisregistreringer udelades.';

  @override
  String get creationToFinished => 'Oprettelse til Færdig';

  @override
  String get notEnoughHistory => 'Ikke nok pålidelig historik';

  @override
  String durationWithSamples(String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count målinger',
      one: '1 måling',
    );
    return '$duration · $_temp0';
  }

  @override
  String get timeInEachStage => 'Gennemsnitlig tid i hver fase';

  @override
  String get noData => 'Ingen data';

  @override
  String sampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count målinger',
      one: '1 måling',
    );
    return '$_temp0';
  }

  @override
  String get ratingDistribution => 'Fordeling af bedømmelser';

  @override
  String get ratingExplanation =>
      'Tæller den strukturerede bedømmelse fra 1–5 på hvert af dine keramikemner i den valgte periode. Manglende bedømmelser vises separat og ikke som nul.';

  @override
  String starRating(int rating) {
    String _temp0 = intl.Intl.pluralLogic(
      rating,
      locale: localeName,
      other: '$rating stjerner',
      one: '1 stjerne',
    );
    return '$_temp0';
  }

  @override
  String get unrated => 'Ikke bedømt';

  @override
  String get mostUsedMaterials => 'Mest brugte materialer';

  @override
  String get mostUsedMaterialsExplanation =>
      'Rangerer ler og glasurer efter antallet af forskellige egne keramikemner, der bruger dem i den valgte periode.';

  @override
  String usedOnCeramics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Brugt på $count keramikemner',
      one: 'Brugt på 1 keramikemne',
    );
    return '$_temp0';
  }

  @override
  String get successfulCombinations => 'Vellykkede ler–glasur-kombinationer';

  @override
  String get successfulCombinationsExplanation =>
      'Viser kombinationer, der er brugt på mindst to bedømte keramikemner og har et gennemsnit på mindst 4. Hvert keramikemne tæller én gang pr. kombination.';

  @override
  String get noSuccessfulCombinations =>
      'Ingen kombination har endnu nok højt bedømte målinger.';

  @override
  String get firingTemperatureAccuracy => 'Planlagt mod observeret brænding';

  @override
  String get firingTemperatureExplanation =>
      'Sammenligner den planlagte måltemperatur med den observerede top for afsluttede brændinger. Inden for 10 °C regnes som tæt på målet; ufuldstændige par udelades.';

  @override
  String get noComparableFirings =>
      'Ingen afsluttet brænding har både måltemperatur og observeret top.';

  @override
  String averageTemperatureDelta(String value) {
    return 'Gennemsnitlig forskel: $value °C';
  }

  @override
  String belowTargetCount(int count) {
    return 'Under målet: $count';
  }

  @override
  String nearTargetCount(int count) {
    return 'Tæt på målet (±10 °C): $count';
  }

  @override
  String aboveTargetCount(int count) {
    return 'Over målet: $count';
  }

  @override
  String durationDaysHours(int days, int hours) {
    return '$days d $hours t';
  }

  @override
  String get howCalculated => 'Sådan beregnes det';

  @override
  String get noPracticeData => 'Ingen praksisdata endnu';

  @override
  String get noPracticeDataBody =>
      'Opret keramikemner, og registrer deres udvikling for at opbygge din private praksisanalyse.';

  @override
  String get analyticsLoadFailed => 'Din analyse kunne ikke indlæses.';

  @override
  String get materialInventory => 'Materialelager';

  @override
  String get addInventoryMaterial => 'Tilføj lagermateriale';

  @override
  String get showLowStockOnly => 'Vis kun lav lagerbeholdning';

  @override
  String get inventoryRefreshFailed =>
      'Lageret kunne ikke opdateres. De tidligere værdier vises.';

  @override
  String get lowStock => 'Lav lagerbeholdning';

  @override
  String get catalogueMaterialRemoved =>
      'Katalogmaterialet er fjernet; historikken er bevaret';

  @override
  String stockAmount(String quantity, String unit) {
    return '$quantity $unit på lager';
  }

  @override
  String get materialType => 'Materialetype';

  @override
  String get material => 'Materiale';

  @override
  String get inventoryMeasurement => 'Sådan måles denne glasur';

  @override
  String get byWeightKilograms => 'Efter vægt (kilogram)';

  @override
  String get byVolumeLitres => 'Efter volumen (liter)';

  @override
  String get glazeMeasurementHelp =>
      'Vælg den enhed, der bruges til køb og blandinger. Den kan ikke blandes med den anden enhed i dette lager.';

  @override
  String get lowStockThresholdOptional => 'Grænse for lav beholdning (valgfri)';

  @override
  String get noInventoryYet => 'Intet lager endnu';

  @override
  String get noInventoryYetBody =>
      'Tilføj ler eller glasur, og registrer derefter køb, forbrug og rettelser. Beholdningen kommer altid fra transaktionshistorikken.';

  @override
  String get inventoryLoadFailed => 'Dit materialelager kunne ikke indlæses.';

  @override
  String get editLowStockThreshold => 'Rediger grænse for lav beholdning';

  @override
  String get recordTransaction => 'Registrer transaktion';

  @override
  String get currentStock => 'Aktuel beholdning';

  @override
  String get noLowStockThreshold => 'Ingen grænse for lav beholdning';

  @override
  String thresholdValue(String value) {
    return 'Grænse for lav beholdning: $value';
  }

  @override
  String get transactionHistory => 'Transaktionshistorik';

  @override
  String get noTransactions => 'Ingen transaktioner endnu.';

  @override
  String inventoryTransactionType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'PURCHASE': 'Køb',
      'USAGE': 'Forbrug',
      'ADJUSTMENT': 'Rettelse',
      'REVERSAL': 'Tilbageførsel',
      'other': '$type',
    });
    return '$_temp0';
  }

  @override
  String get reverseTransaction => 'Tilbagefør transaktion';

  @override
  String get reverse => 'Tilbagefør';

  @override
  String get correctionReason => 'Årsag til rettelse';

  @override
  String get reversalReason => 'Årsag til tilbageførsel';

  @override
  String get transactionType => 'Transaktionstype';

  @override
  String get signedQuantity => 'Ændring i mængde (+ eller −)';

  @override
  String get quantity => 'Mængde';

  @override
  String get totalPurchaseCostOptional => 'Samlet købspris (valgfri)';

  @override
  String get isoCurrencyCode => 'ISO-valutakode';

  @override
  String get currency => 'Valuta';

  @override
  String get supplierOptional => 'Leverandør (valgfri)';

  @override
  String get referenceOptional => 'Reference (valgfri)';

  @override
  String get associatedCeramic => 'Tilknyttet keramik';

  @override
  String get ceramicIdOptional => 'Keramik-ID (valgfrit)';

  @override
  String get chooseCeramicOptional => 'Tilknyttet keramik (valgfrit)';

  @override
  String get noAssociatedCeramic => 'Ingen tilknyttet keramik';

  @override
  String get ceramicsLoadFailed => 'Keramik kunne ikke indlæses.';

  @override
  String get costEstimate => 'Prisoverslag';

  @override
  String get noCostEstimate => 'Beregn ikke pris';

  @override
  String get weightedAverageCost => 'Købsvægtet gennemsnit';

  @override
  String get purchaseCostCurrency => 'Valuta for prisoverslag';

  @override
  String get noCostedPurchaseHistory =>
      'Registrer først et køb med en samlet pris for at bruge det købsvægtede gennemsnit.';

  @override
  String get costOptionsLoadFailed =>
      'Købshistorikkens priser kunne ikke indlæses.';

  @override
  String get manualCost => 'Manuelt overslag';

  @override
  String get estimatedUsageCost => 'Anslået forbrugspris';

  @override
  String get usageIsNeverInferred =>
      'Forbrug registreres kun efter din bekræftelse. Keramik udleder aldrig forbrug fra mål eller vægt.';

  @override
  String get review => 'Gennemse';

  @override
  String get confirm => 'Bekræft';

  @override
  String get confirmInventoryTransaction => 'Bekræft lagertransaktion';

  @override
  String confirmInventoryTransactionBody(
    String type,
    String quantity,
    String unit,
    String material,
  ) {
    return '$type af $quantity $unit $material. Dette opdaterer lageret og føjer transaktionen til historikken.';
  }

  @override
  String get transactionSaved => 'Lagertransaktionen er registreret.';

  @override
  String get editTransaction => 'Rediger transaktion';

  @override
  String get confirmEditTransaction => 'Gem denne transaktionsændring?';

  @override
  String get editTransactionAuditNote =>
      'Originalen bliver i historikken. Når du gemmer, ophæves dens virkning, og den rettede transaktion tilføjes.';

  @override
  String get transactionUpdated =>
      'Transaktionen er opdateret. Den tidligere version bliver i historikken.';

  @override
  String get materialUsageAndCost => 'Materialeforbrug og pris';

  @override
  String get materialUsageIsManual =>
      'Registrer bekræftet forbrug, og se prisoverslag';

  @override
  String get estimatedMaterialCost => 'Anslået materialepris';

  @override
  String get noRecordedMaterialCost =>
      'Der er ikke registreret forbrug med pris.';

  @override
  String get costEstimateExplanation =>
      'Oprindelige totaler forbliver grupperet efter deres registrerede ISO-valuta. Når det er muligt, viser Keramik også et omregnet overslag med de seneste gemte ECB-referencekurser.';

  @override
  String get recordMaterialUsage => 'Registrer materialeforbrug';

  @override
  String get chooseInventoryMaterial =>
      'Vælg et lagermateriale. Forbrug og prisoverslag vises til bekræftelse før lagring.';

  @override
  String get noInventoryForUsage =>
      'Konfigurer et ler- eller glasurlager, før du registrerer forbrug.';

  @override
  String get inventorySpendingAndUsage => 'Lagerudgifter og forbrug';

  @override
  String get inventoryAnalyticsExplanation =>
      'Udgifter er nettobeløbet for registrerede køb efter tilbageførsler, grupperet efter oprindelig ISO-valuta. Et omregnet sammendrag bruger gemte ECB-referencekurser, når de er tilgængelige. Forbrug er nettobeløbet for bekræftet forbrug efter tilbageførsler, grupperet efter materiale og standardenhed.';

  @override
  String get noInventoryAnalytics =>
      'Der blev ikke registreret lagerkøb eller forbrug i perioden.';

  @override
  String get materialSpending => 'Materialeudgifter';

  @override
  String get recordedInventoryUsage => 'Registreret lagerforbrug';

  @override
  String get preferredCurrency => 'Foretrukken valuta';

  @override
  String automaticCurrency(String currency) {
    return 'Automatisk ($currency)';
  }

  @override
  String get currencySettingHelp =>
      'Automatisk følger din enheds region. Du kan vælge en fast valuta i stedet.';

  @override
  String convertedTotal(String amount, String currency) {
    return 'Omregnet overslag: $amount $currency';
  }

  @override
  String convertedSpending(String amount, String currency) {
    return 'Omregnede udgifter: $amount $currency';
  }

  @override
  String get currencyConversionUnavailable =>
      'En omregnet total er ikke tilgængelig. Oprindelige valutatal vises stadig.';

  @override
  String exchangeRateSource(String date, String provider) {
    return 'ECB-referencekurser fra $date ($provider)';
  }
}
