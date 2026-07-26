import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/objects/chat_report_dto.dart';
import 'package:flutter/widgets.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// Temporary source-compatible fallback while the generated localization command
// is unavailable. Generated instance getters take precedence after regeneration.
extension DiscoverAppLocalizations on AppLocalizations {
  bool get _da => localeName.toLowerCase().startsWith('da');
  String get navigationDiscover => _da ? 'Opdag' : 'Discover';
  String get discoverForYou => _da ? 'Til dig' : 'For You';
  String get discoverLatest => _da ? 'Nyeste' : 'Latest';
  String get discoverEmpty => _da
      ? 'Der er endnu ingen udgivne keramikemner.'
      : 'No published ceramics are available yet.';
  String get notInterestedAction =>
      _da ? 'Ikke interesseret' : 'Not interested';
  String get likeAction => _da ? 'Synes godt om' : 'Like';
  String get publishFinishedTitle => _da
      ? 'Vil du udgive dette færdige emne?'
      : 'Publish this finished piece?';
  String get publishFinishedBody => _da
      ? 'Udgivne emner kan vises under Opdag og på din profil. Op til 20 billeder og de angivne offentlige oplysninger bliver synlige.'
      : 'Published pieces can appear in Discover and on your profile. Up to 20 images and the listed public details will be visible.';
  String get publishAction => _da ? 'Udgiv' : 'Publish';
  String get notNowAction => _da ? 'Ikke nu' : 'Not now';
  String get unpublishAction => _da ? 'Fjern udgivelse' : 'Unpublish';
  String get publicationTemporarilyUnavailable => _da
      ? 'Udgivet, men skjult indtil emnet er Færdigt og har et billede.'
      : 'Published, but hidden until the piece is Finished and has an image.';
  String get publicationModerationRemoved => _da
      ? 'Fjernet af moderation. Du kan ikke udgive emnet igen, mens moderationslåsen er aktiv.'
      : 'Removed by moderation. You cannot republish this piece while the moderation lock is active.';
  String get publicationUnavailable => _da
      ? 'Udgivet keramik er ikke tilgængelig'
      : 'Published ceramic unavailable';
  String get publicationReportEvidenceDisclosure => _da
      ? 'De nuværende offentlige oplysninger og op til 20 synlige billeder gemmes sikkert til moderatorgennemgang. Rapportering skjuler denne udgivelse permanent for dig.'
      : 'The current public details and up to 20 visible images will be securely preserved for moderator review. Reporting permanently hides this publication episode from you.';
  String publicationReportCategory(String value) => switch (value) {
    'SPAM' => reportSpam,
    'HARASSMENT_OR_HATE' => _da ? 'Chikane eller had' : 'Harassment or hate',
    'SEXUAL_CONTENT' => reportSexualContent,
    'VIOLENCE_OR_DANGEROUS' =>
      _da ? 'Vold eller farligt indhold' : 'Violence or dangerous content',
    'STOLEN_WORK_OR_IP' =>
      _da
          ? 'Stjålet værk eller ophavsret'
          : 'Stolen work or intellectual property',
    _ => other,
  };
  String get undoAction => _da ? 'Fortryd' : 'Undo';
  String get reportPublication =>
      _da ? 'Rapportér udgivelse' : 'Report publication';
  String get reportReason => _da ? 'Årsag' : 'Reason';
  String get reportExplanation => _da ? 'Forklaring' : 'Explanation';
  String get submitReport => _da ? 'Send rapport' : 'Submit report';
}

// Source-compatible fallback used until `flutter gen-l10n` can be completed.
// These members are ignored in favor of generated instance members afterward.
extension PremiumFeatureAppLocalizations on AppLocalizations {
  bool get _premiumDa => localeName.toLowerCase().startsWith('da');
  String get createTemplate =>
      _premiumDa ? 'Opret skabelon' : 'Create template';
  String get editTemplate => _premiumDa ? 'Rediger skabelon' : 'Edit template';
  String get templateName => _premiumDa ? 'Skabelonnavn' : 'Template name';
  String get templateTitlePattern =>
      _premiumDa ? 'Titelmønster' : 'Title pattern';
  String get templateTitlePatternHelp => _premiumDa
      ? 'Sæt n i krøllede parenteser, hvor batchnummeret skal stå.'
      : 'Place n inside braces where the batch number should appear.';
  String get noClay => _premiumDa ? 'Intet ler' : 'No clay';
  String get commaSeparatedTags =>
      _premiumDa ? 'Adskil tags med kommaer.' : 'Separate tags with commas.';
  String get noTemplateGlazes =>
      _premiumDa ? 'Ingen glasurplan.' : 'No glaze plan.';
  String get plannedFirings =>
      _premiumDa ? 'Planlagte brændinger' : 'Planned firings';
  String get noTemplateFirings =>
      _premiumDa ? 'Ingen brændingsplan.' : 'No firing plan.';
  String templateGlazeSummary(int coats, String note) {
    final count = _premiumDa
        ? coats == 1
              ? '1 lag'
              : '$coats lag'
        : coats == 1
        ? '1 coat'
        : '$coats coats';
    return note.trim().isEmpty ? count : '$count · $note';
  }

  String get addPlannedFiring =>
      _premiumDa ? 'Tilføj planlagt brænding' : 'Add planned firing';
  String get tooManyTemplateTags => _premiumDa
      ? 'En skabelon kan højst indeholde 30 tags.'
      : 'A template can contain at most 30 tags.';
  String get requiredField =>
      _premiumDa ? 'Feltet skal udfyldes.' : 'This field is required.';
  String get invalidNumber => _premiumDa
      ? 'Indtast et gyldigt ikke-negativt tal.'
      : 'Enter a valid non-negative number.';
  String get createFromTemplate =>
      _premiumDa ? 'Opret fra skabelon' : 'Create from template';
  String batchQuantity(int count) =>
      _premiumDa ? 'Antal: $count' : 'Quantity: $count';
  String get startNumber => _premiumDa ? 'Startnummer' : 'Starting number';
  String get titlePreview =>
      _premiumDa ? 'Forhåndsvisning af titler' : 'Title preview';
  String get createOneCeramic =>
      _premiumDa ? 'Opret keramik' : 'Create ceramic';
  String createCeramicBatch(int count) =>
      _premiumDa ? 'Opret $count keramikemner' : 'Create $count ceramics';
  String get confirmBatchCreation =>
      _premiumDa ? 'Opret denne batch?' : 'Create this batch?';
  String confirmBatchCreationBody(int count) => _premiumDa
      ? 'Dette opretter ${count == 1 ? 'ét nyt keramikemne' : '$count nye keramikemner'} med ny journalhistorik.'
      : 'This will create ${count == 1 ? 'one new ceramic' : '$count new ceramics'} with fresh journal history.';
  String get batchCreated => _premiumDa ? 'Batch oprettet' : 'Batch created';
  String batchCreatedBody(int count) => _premiumDa
      ? count == 1
            ? 'Ét keramikemne blev oprettet.'
            : '$count keramikemner blev oprettet.'
      : count == 1
      ? 'One ceramic was created.'
      : '$count ceramics were created.';
  String get projectTemplates =>
      _premiumDa ? 'Projektskabeloner' : 'Project templates';
  String get duplicate => _premiumDa ? 'Dupliker' : 'Duplicate';
  String templateGlazeCount(int count) => _premiumDa
      ? count == 0
            ? 'Ingen glasurer'
            : count == 1
            ? '1 glasur'
            : '$count glasurer'
      : count == 0
      ? 'No glazes'
      : count == 1
      ? '1 glaze'
      : '$count glazes';
  String templateFiringCount(int count) => _premiumDa
      ? count == 0
            ? 'Ingen brændinger'
            : count == 1
            ? '1 brænding'
            : '$count brændinger'
      : count == 0
      ? 'No firings'
      : count == 1
      ? '1 firing'
      : '$count firings';
  String get templateMaterialMissing => _premiumDa
      ? 'Et tilknyttet materiale findes ikke længere. Rediger skabelonen, før den bruges.'
      : 'A referenced material is no longer available. Edit the template before using it.';
  String get useTemplate => _premiumDa ? 'Brug skabelon' : 'Use template';
  String get duplicateTemplate =>
      _premiumDa ? 'Dupliker skabelon' : 'Duplicate template';
  String copyOfTemplate(String name) =>
      _premiumDa ? 'Kopi af $name' : 'Copy of $name';
  String get deleteTemplate =>
      _premiumDa ? 'Slet skabelon?' : 'Delete template?';
  String deleteTemplateBody(String name) => _premiumDa
      ? 'Slet “$name”? Eksisterende keramik påvirkes ikke.'
      : 'Delete “$name”? Existing ceramics will not be affected.';
  String get noProjectTemplates =>
      _premiumDa ? 'Ingen projektskabeloner endnu' : 'No project templates yet';
  String get noProjectTemplatesBody => _premiumDa
      ? 'Gem en genbrugelig plan fra et keramikemne, eller opret en fra bunden.'
      : 'Save a reusable plan from a ceramic or create one from scratch.';
  String get templatesLoadFailed => _premiumDa
      ? 'Vi kunne ikke indlæse dine projektskabeloner.'
      : 'We could not load your project templates.';
  String get batchEdit => _premiumDa ? 'Batchredigering' : 'Batch edit';
  String selectedCeramics(int count) => _premiumDa
      ? count == 0
            ? 'Ingen keramik valgt'
            : count == 1
            ? '1 keramik valgt'
            : '$count keramikemner valgt'
      : count == 0
      ? 'No ceramics selected'
      : count == 1
      ? '1 ceramic selected'
      : '$count ceramics selected';
  String get batchEditSafetyNote => _premiumDa
      ? 'Afsluttet historik erstattes aldrig. Eksisterende glasurarbejde og modstridende brændingsplaner springes over.'
      : 'Completed history is never replaced. Existing glaze work and conflicting firing plans will be skipped.';
  String get batchBasics =>
      _premiumDa ? 'Grundlæggende oplysninger' : 'Basics';
  String get batchTagChanges =>
      _premiumDa ? 'Tagændringer' : 'Tag changes';
  String get batchDimensionsHelp => _premiumDa
      ? 'Udfyld kun de mål, der skal anvendes på alle valgte emner.'
      : 'Enter only the dimensions to apply to every selected piece.';
  String get batchPlanningHelp => _premiumDa
      ? 'Planoplysninger tilføjes kun, når eksisterende arbejde kan bevares sikkert.'
      : 'Planning information is added only when existing work can be preserved safely.';
  String get changeStage => _premiumDa ? 'Skift fase' : 'Change stage';
  String get keepCurrent =>
      _premiumDa ? 'Behold nuværende værdi' : 'Keep current value';
  String get changeClay => _premiumDa ? 'Skift ler' : 'Change clay';
  String get clearClay => _premiumDa ? 'Fjern ler' : 'Clear clay';
  String get setClay => _premiumDa ? 'Vælg ler' : 'Set clay';
  String get addTags => _premiumDa ? 'Tilføj tags' : 'Add tags';
  String get removeTags => _premiumDa ? 'Fjern tags' : 'Remove tags';
  String get applyDimensions => _premiumDa ? 'Anvend mål' : 'Apply dimensions';
  String get applyPlanningTemplate => _premiumDa
      ? 'Anvend genbrugelige planoplysninger'
      : 'Apply reusable planning information';
  String get projectTemplate =>
      _premiumDa ? 'Projektskabelon' : 'Project template';
  String get none => _premiumDa ? 'Ingen' : 'None';
  String get applyGlazesOnlyWhenEmpty => _premiumDa
      ? 'Anvend kun glasurplanen, hvor der ikke findes glasurlag'
      : 'Apply glaze plan only where no glaze applications exist';
  String get applySafeFiringPlans => _premiumDa
      ? 'Tilføj brændingsplaner, som ikke er i konflikt med afsluttet arbejde'
      : 'Add firing plans that do not conflict with completed work';
  String get reviewBatchEdit =>
      _premiumDa ? 'Gennemse batchredigering' : 'Review batch edit';
  String get chooseClay => _premiumDa
      ? 'Vælg et ler, der skal anvendes.'
      : 'Choose a clay to apply.';
  String get confirmBatchEdit =>
      _premiumDa ? 'Bekræft batchredigering' : 'Confirm batch edit';
  String batchEditTargetCount(int count) => _premiumDa
      ? 'Denne redigering omfatter ${count == 1 ? 'ét keramikemne' : '$count keramikemner'}.'
      : 'This edit targets ${count == 1 ? 'one ceramic' : '$count ceramics'}.';
  String get protectedItemsWillBeSkipped => _premiumDa
      ? 'Beskyttet arbejde springes over:'
      : 'Protected work will be skipped:';
  String get apply => _premiumDa ? 'Anvend' : 'Apply';
  String get batchEditComplete =>
      _premiumDa ? 'Batchredigering færdig' : 'Batch edit complete';
  String get batchEditPartiallyComplete => _premiumDa
      ? 'Batchredigering delvist færdig'
      : 'Batch edit partially complete';
  String batchEditResult(int updated, int skipped) => _premiumDa
      ? '$updated opdateret · $skipped sprunget over eller uændret'
      : '$updated updated · $skipped skipped or unchanged';
  String get selectAllVisible =>
      _premiumDa ? 'Vælg alle synlige' : 'Select all visible';
  String get selectCeramics => _premiumDa ? 'Vælg keramik' : 'Select ceramics';
  String get createBlankCeramic =>
      _premiumDa ? 'Opret et tomt keramikemne' : 'Create a blank ceramic';
  String get reviewBatchDelete =>
      _premiumDa ? 'Gennemse sletning' : 'Review deletion';
  String batchDeleteTargetCount(int count) => _premiumDa
      ? 'Du er ved permanent at slette ${count == 1 ? 'ét keramikemne' : '$count keramikemner'}.'
      : 'You are about to permanently delete ${count == 1 ? 'one ceramic' : '$count ceramics'}.';
  String get batchDeleteWarning => _premiumDa
      ? 'Keramikemnerne samt deres billeder, planer og journalhistorik fjernes. Handlingen kan ikke fortrydes.'
      : 'The ceramics and their images, plans, and journal history will be removed. This cannot be undone.';
  String get understandPermanentDeletion => _premiumDa
      ? 'Jeg forstår, at de valgte keramikemner slettes permanent.'
      : 'I understand that the selected ceramics will be permanently deleted.';
  String deleteSelectedCeramics(int count) =>
      _premiumDa ? 'Slet $count' : 'Delete $count';
  String batchDeleteComplete(int count) => _premiumDa
      ? '${count == 1 ? '1 keramikemne slettet' : '$count keramikemner slettet'}.'
      : '${count == 1 ? '1 ceramic deleted' : '$count ceramics deleted'}.';
  String get batchDeleteFailed =>
      _premiumDa ? 'Sletningen mislykkedes' : 'Deletion failed';
  String get batchDeleteFailedBody => _premiumDa
      ? 'Intet blev slettet. Et emne kan være ændret siden gennemgangen. Genindlæs gennemgangen, og prøv igen.'
      : 'Nothing was deleted. A piece may have changed since review. Reload the review and try again.';
  String get saveAsTemplate =>
      _premiumDa ? 'Gem som skabelon' : 'Save as template';
  String templateFromCeramic(String title) =>
      _premiumDa ? '$title-skabelon' : '$title template';
  String get templateExcludesResults => _premiumDa
      ? 'Billeder, bedømmelser, resultater, afsluttede brændinger, fasehistorik og udgivelsesdata kopieres ikke.'
      : 'Images, ratings, outcomes, completed firings, stage history, and publication data are not copied.';
  String get templateSaved =>
      _premiumDa ? 'Projektskabelonen er gemt.' : 'Project template saved.';
  String get practiceAnalytics =>
      _premiumDa ? 'Praksisanalyse' : 'Practice analytics';
  String get practiceAnalyticsPrivate => _premiumDa
      ? 'Private indsigter kun fra din keramik'
      : 'Private insights from your ceramics only';
  String get analyticsRefreshFailed => _premiumDa
      ? 'Den nyeste analyse kunne ikke indlæses. De tidligere resultater vises.'
      : 'The latest analytics could not be loaded. Showing the previous results.';
  String get incompleteHistory => _premiumDa
      ? 'Noget tidshistorik er ufuldstændig'
      : 'Some timing history is incomplete';
  String incompleteHistoryBody(int count) => _premiumDa
      ? '$count ældre keramikemne${count == 1 ? '' : 'r'} har kun basisregistreringer og er udeladt fra tidsmålingerne.'
      : '$count older ceramic${count == 1 ? '' : 's'} ${count == 1 ? 'has' : 'have'} only baseline stage records and ${count == 1 ? 'is' : 'are'} excluded from duration metrics.';
  String get last90Days => _premiumDa ? 'Seneste 90 dage' : 'Last 90 days';
  String get lastYear => _premiumDa ? 'Seneste år' : 'Last year';
  String get allTime => _premiumDa ? 'Hele perioden' : 'All time';
  String get createdAndCompleted =>
      _premiumDa ? 'Oprettet og færdiggjort' : 'Created and completed';
  String createdCompletedSummary(int created, int completed) => _premiumDa
      ? '$created oprettet · $completed færdiggjort'
      : '$created created · $completed completed';
  String get createdCompletedExplanation => _premiumDa
      ? 'Oprettet bruger oprettelsesdatoen. Færdiggjort bruger den første pålidelige overgang til Færdig. Ældre basisregistreringer udelades.'
      : 'Created uses the creation date. Completed uses the first trustworthy Finished transition. Older baseline-only records are excluded.';
  String get noTrustedActivityData => _premiumDa
      ? 'Der findes ingen pålidelige aktivitetsdata i perioden.'
      : 'No trustworthy activity is available in this period.';
  String get currentStages => _premiumDa ? 'Aktuelle faser' : 'Current stages';
  String get currentStagesExplanation => _premiumDa
      ? 'Tæller den aktuelle fase for dine keramikemner i perioden.'
      : 'Counts the current stage of your ceramics in the selected period.';
  String get practiceTiming => _premiumDa ? 'Tid i praksis' : 'Practice timing';
  String get practiceTimingExplanation => _premiumDa
      ? 'Målingerne bruger kun pålidelige, afsluttede faseovergange.'
      : 'Timing uses only trustworthy, closed stage transitions.';
  String get creationToFinished =>
      _premiumDa ? 'Oprettelse til Færdig' : 'Creation to Finished';
  String get notEnoughHistory => _premiumDa
      ? 'Ikke nok pålidelig historik'
      : 'Not enough trustworthy history';
  String durationWithSamples(String duration, int count) =>
      '$duration · ${sampleCount(count)}';
  String get timeInEachStage => _premiumDa
      ? 'Gennemsnitlig tid i hver fase'
      : 'Average time in each stage';
  String get noData => _premiumDa ? 'Ingen data' : 'No data';
  String sampleCount(int count) => _premiumDa
      ? '$count ${count == 1 ? 'måling' : 'målinger'}'
      : '$count ${count == 1 ? 'sample' : 'samples'}';
  String get ratingDistribution =>
      _premiumDa ? 'Fordeling af bedømmelser' : 'Rating distribution';
  String get ratingExplanation => _premiumDa
      ? 'Manglende strukturerede bedømmelser vises separat og ikke som nul.'
      : 'Missing structured ratings are shown separately, not as zero.';
  String starRating(int rating) => _premiumDa
      ? '$rating ${rating == 1 ? 'stjerne' : 'stjerner'}'
      : '$rating ${rating == 1 ? 'star' : 'stars'}';
  String get unrated => _premiumDa ? 'Ikke bedømt' : 'Unrated';
  String get mostUsedMaterials =>
      _premiumDa ? 'Mest brugte materialer' : 'Most-used materials';
  String get mostUsedMaterialsExplanation => _premiumDa
      ? 'Rangerer materialer efter antallet af forskellige egne keramikemner.'
      : 'Ranks materials by the number of distinct owned ceramics.';
  String usedOnCeramics(int count) => _premiumDa
      ? 'Brugt på $count keramikemne${count == 1 ? '' : 'r'}'
      : 'Used on $count ceramic${count == 1 ? '' : 's'}';
  String get successfulCombinations => _premiumDa
      ? 'Vellykkede ler–glasur-kombinationer'
      : 'Successful clay–glaze combinations';
  String get successfulCombinationsExplanation => _premiumDa
      ? 'Kræver mindst to bedømte keramikemner og et gennemsnit på mindst 4.'
      : 'Requires at least two rated ceramics and an average rating of 4 or higher.';
  String get noSuccessfulCombinations => _premiumDa
      ? 'Ingen kombination har endnu nok højt bedømte målinger.'
      : 'No combination has enough highly rated samples yet.';
  String get firingTemperatureAccuracy => _premiumDa
      ? 'Planlagt mod observeret brænding'
      : 'Planned versus observed firing';
  String get firingTemperatureExplanation => _premiumDa
      ? 'Sammenligner mål og observeret top for afsluttede brændinger.'
      : 'Compares target and observed peak for completed firings.';
  String get noComparableFirings => _premiumDa
      ? 'Ingen afsluttet brænding har både mål og observeret top.'
      : 'No completed firing has both a target and an observed peak.';
  String averageTemperatureDelta(String value) => _premiumDa
      ? 'Gennemsnitlig forskel: $value °C'
      : 'Average difference: $value°C';
  String belowTargetCount(int count) =>
      _premiumDa ? 'Under målet: $count' : 'Below target: $count';
  String nearTargetCount(int count) => _premiumDa
      ? 'Tæt på målet (±10 °C): $count'
      : 'Near target (±10°C): $count';
  String aboveTargetCount(int count) =>
      _premiumDa ? 'Over målet: $count' : 'Above target: $count';
  String durationDaysHours(int days, int hours) =>
      _premiumDa ? '$days d $hours t' : '$days d $hours h';
  String get howCalculated =>
      _premiumDa ? 'Sådan beregnes det' : 'How this is calculated';
  String get noPracticeData =>
      _premiumDa ? 'Ingen praksisdata endnu' : 'No practice data yet';
  String get noPracticeDataBody => _premiumDa
      ? 'Opret keramikemner, og registrer deres udvikling for at opbygge din private praksisanalyse.'
      : 'Create ceramics and record their progress to build your private practice analytics.';
  String get analyticsLoadFailed => _premiumDa
      ? 'Din analyse kunne ikke indlæses.'
      : 'Your analytics could not be loaded.';
  String get materialInventory =>
      _premiumDa ? 'Materialelager' : 'Material inventory';
  String get addInventoryMaterial =>
      _premiumDa ? 'Tilføj lagermateriale' : 'Add inventory material';
  String get showLowStockOnly =>
      _premiumDa ? 'Vis kun lav lagerbeholdning' : 'Show low-stock only';
  String get inventoryRefreshFailed => _premiumDa
      ? 'Lageret kunne ikke opdateres. De tidligere værdier vises.'
      : 'The inventory could not be refreshed. Previous values are shown.';
  String get lowStock => _premiumDa ? 'Lav lagerbeholdning' : 'Low stock';
  String get catalogueMaterialRemoved => _premiumDa
      ? 'Katalogmaterialet er fjernet; historikken er bevaret'
      : 'Catalogue material removed; history retained';
  String stockAmount(String quantity, String unit) =>
      _premiumDa ? '$quantity $unit på lager' : '$quantity $unit in stock';
  String get materialType => _premiumDa ? 'Materialetype' : 'Material type';
  String get material => _premiumDa ? 'Materiale' : 'Material';
  String get clay => _premiumDa ? 'Ler' : 'Clay';
  String get glaze => _premiumDa ? 'Glasur' : 'Glaze';
  String get inventoryMeasurement =>
      _premiumDa ? 'Sådan måles denne glasur' : 'How this glaze is measured';
  String get byWeightKilograms =>
      _premiumDa ? 'Efter vægt (kilogram)' : 'By weight (kilograms)';
  String get byVolumeLitres =>
      _premiumDa ? 'Efter volumen (liter)' : 'By volume (litres)';
  String get glazeMeasurementHelp => _premiumDa
      ? 'Vælg den enhed, der bruges til køb og blandinger. Enheder kan ikke blandes i samme lager.'
      : 'Choose the unit used for purchases and mixed batches. Units cannot be mixed in one inventory.';
  String get lowStockThresholdOptional => _premiumDa
      ? 'Grænse for lav beholdning (valgfri)'
      : 'Low-stock threshold (optional)';
  String get noInventoryYet =>
      _premiumDa ? 'Intet lager endnu' : 'No inventory yet';
  String get noInventoryYetBody => _premiumDa
      ? 'Tilføj ler eller glasur, og registrer køb, forbrug og rettelser.'
      : 'Add a clay or glaze, then record purchases, usage, and corrections.';
  String get inventoryLoadFailed => _premiumDa
      ? 'Dit materialelager kunne ikke indlæses.'
      : 'Your material inventory could not be loaded.';
  String get editLowStockThreshold => _premiumDa
      ? 'Rediger grænse for lav beholdning'
      : 'Edit low-stock threshold';
  String get recordTransaction =>
      _premiumDa ? 'Registrer transaktion' : 'Record transaction';
  String get currentStock => _premiumDa ? 'Aktuel beholdning' : 'Current stock';
  String get noLowStockThreshold =>
      _premiumDa ? 'Ingen grænse for lav beholdning' : 'No low-stock threshold';
  String thresholdValue(String value) => _premiumDa
      ? 'Grænse for lav beholdning: $value'
      : 'Low-stock threshold: $value';
  String get transactionHistory =>
      _premiumDa ? 'Transaktionshistorik' : 'Transaction history';
  String get noTransactions =>
      _premiumDa ? 'Ingen transaktioner endnu.' : 'No transactions yet.';
  String inventoryTransactionType(String type) => switch (type) {
    'PURCHASE' => _premiumDa ? 'Køb' : 'Purchase',
    'USAGE' => _premiumDa ? 'Forbrug' : 'Usage',
    'ADJUSTMENT' => _premiumDa ? 'Rettelse' : 'Correction',
    'REVERSAL' => _premiumDa ? 'Tilbageførsel' : 'Reversal',
    _ => type,
  };
  String get reverseTransaction =>
      _premiumDa ? 'Tilbagefør transaktion' : 'Reverse transaction';
  String get reverse => _premiumDa ? 'Tilbagefør' : 'Reverse';
  String get correctionReason =>
      _premiumDa ? 'Årsag til rettelse' : 'Correction reason';
  String get reversalReason =>
      _premiumDa ? 'Årsag til tilbageførsel' : 'Reason for reversal';
  String get transactionType =>
      _premiumDa ? 'Transaktionstype' : 'Transaction type';
  String get signedQuantity =>
      _premiumDa ? 'Ændring i mængde (+ eller −)' : 'Quantity change (+ or −)';
  String get quantity => _premiumDa ? 'Mængde' : 'Quantity';
  String get totalPurchaseCostOptional => _premiumDa
      ? 'Samlet købspris (valgfri)'
      : 'Total purchase cost (optional)';
  String get isoCurrencyCode =>
      _premiumDa ? 'ISO-valutakode' : 'ISO currency code';
  String get supplierOptional =>
      _premiumDa ? 'Leverandør (valgfri)' : 'Supplier (optional)';
  String get referenceOptional =>
      _premiumDa ? 'Reference (valgfri)' : 'Reference (optional)';
  String get associatedCeramic =>
      _premiumDa ? 'Tilknyttet keramik' : 'Associated ceramic';
  String get ceramicIdOptional =>
      _premiumDa ? 'Keramik-ID (valgfrit)' : 'Ceramic ID (optional)';
  String get chooseCeramicOptional => _premiumDa
      ? 'Tilknyttet keramik (valgfrit)'
      : 'Associated ceramic (optional)';
  String get noAssociatedCeramic =>
      _premiumDa ? 'Ingen tilknyttet keramik' : 'No associated ceramic';
  String get ceramicsLoadFailed => _premiumDa
      ? 'Keramik kunne ikke indlæses.'
      : 'Ceramics could not be loaded.';
  String get costEstimate => _premiumDa ? 'Prisoverslag' : 'Cost estimate';
  String get noCostEstimate =>
      _premiumDa ? 'Beregn ikke pris' : 'Do not estimate cost';
  String get weightedAverageCost =>
      _premiumDa ? 'Købsvægtet gennemsnit' : 'Purchase-weighted average';
  String get purchaseCostCurrency =>
      _premiumDa ? 'Valuta for prisoverslag' : 'Estimate currency';
  String get noCostedPurchaseHistory => _premiumDa
      ? 'Registrer først et køb med en samlet pris for at bruge det købsvægtede gennemsnit.'
      : 'Record a purchase with a total cost before using the purchase-weighted average.';
  String get costOptionsLoadFailed => _premiumDa
      ? 'Købshistorikkens priser kunne ikke indlæses.'
      : 'Purchase-history costs could not be loaded.';
  String get manualCost => _premiumDa ? 'Manuelt overslag' : 'Manual estimate';
  String get estimatedUsageCost =>
      _premiumDa ? 'Anslået forbrugspris' : 'Estimated usage cost';
  String get usageIsNeverInferred => _premiumDa
      ? 'Forbrug registreres kun efter din bekræftelse og udledes aldrig automatisk.'
      : 'Usage is recorded only after your confirmation and is never inferred automatically.';
  String get review => _premiumDa ? 'Gennemse' : 'Review';
  String get confirm => _premiumDa ? 'Bekræft' : 'Confirm';
  String get confirmInventoryTransaction =>
      _premiumDa ? 'Bekræft lagertransaktion' : 'Confirm inventory transaction';
  String confirmInventoryTransactionBody(
    String type,
    String quantity,
    String unit,
    String material,
  ) => _premiumDa
      ? '$type af $quantity $unit $material. Dette opdaterer lageret og føjer transaktionen til historikken.'
      : '$type $quantity $unit of $material. This updates your stock and adds the transaction to its history.';
  String get transactionSaved => _premiumDa
      ? 'Lagertransaktionen er registreret.'
      : 'Inventory transaction recorded.';
  String get editTransaction =>
      _premiumDa ? 'Rediger transaktion' : 'Edit transaction';
  String get confirmEditTransaction => _premiumDa
      ? 'Gem denne transaktionsændring?'
      : 'Save this transaction edit?';
  String get editTransactionAuditNote => _premiumDa
      ? 'Originalen bliver i historikken. Når du gemmer, ophæves dens virkning, og den rettede transaktion tilføjes.'
      : 'The original stays in history. Saving cancels its effect and adds the corrected transaction.';
  String get transactionUpdated => _premiumDa
      ? 'Transaktionen er opdateret. Den tidligere version bliver i historikken.'
      : 'Transaction updated. The previous version remains in history.';
  String get materialUsageAndCost =>
      _premiumDa ? 'Materialeforbrug og pris' : 'Material usage and cost';
  String get materialUsageIsManual => _premiumDa
      ? 'Registrer bekræftet forbrug, og se prisoverslag'
      : 'Record confirmed usage and view cost estimates';
  String get estimatedMaterialCost =>
      _premiumDa ? 'Anslået materialepris' : 'Estimated material cost';
  String get noRecordedMaterialCost => _premiumDa
      ? 'Der er ikke registreret forbrug med pris.'
      : 'No costed usage has been recorded.';
  String get costEstimateExplanation => _premiumDa
      ? 'Totaler grupperes efter ISO-valuta. Valutaer omregnes aldrig.'
      : 'Totals are grouped by ISO currency. Currencies are never converted.';
  String get recordMaterialUsage =>
      _premiumDa ? 'Registrer materialeforbrug' : 'Record material usage';
  String get chooseInventoryMaterial => _premiumDa
      ? 'Vælg et lagermateriale. Forbruget bekræftes før lagring.'
      : 'Choose an inventory material. Usage is confirmed before saving.';
  String get noInventoryForUsage => _premiumDa
      ? 'Konfigurer et materialelager, før du registrerer forbrug.'
      : 'Configure a material inventory before recording usage.';
  String get inventorySpendingAndUsage =>
      _premiumDa ? 'Lagerudgifter og forbrug' : 'Inventory spending and usage';
  String get inventoryAnalyticsExplanation => _premiumDa
      ? 'Viser nettokøb og bekræftet nettoforbrug efter tilbageførsler.'
      : 'Shows net purchases and confirmed net usage after reversals.';
  String get noInventoryAnalytics => _premiumDa
      ? 'Der blev ikke registreret lagerkøb eller forbrug i perioden.'
      : 'No inventory purchases or usage were recorded in this period.';
  String get materialSpending =>
      _premiumDa ? 'Materialeudgifter' : 'Material spending';
  String get recordedInventoryUsage =>
      _premiumDa ? 'Registreret lagerforbrug' : 'Recorded inventory usage';
  String get preferredCurrency =>
      _premiumDa ? 'Foretrukken valuta' : 'Preferred currency';
  String automaticCurrency(String currency) =>
      _premiumDa ? 'Automatisk ($currency)' : 'Automatic ($currency)';
  String get currencySettingHelp => _premiumDa
      ? 'Automatisk følger din enheds region. Du kan vælge en fast valuta i stedet.'
      : 'Automatic follows your device region. You can select a fixed currency instead.';
  String get currency => _premiumDa ? 'Valuta' : 'Currency';
  String convertedTotal(String amount, String currency) => _premiumDa
      ? 'Omregnet overslag: $amount $currency'
      : 'Converted estimate: $amount $currency';
  String convertedSpending(String amount, String currency) => _premiumDa
      ? 'Omregnede udgifter: $amount $currency'
      : 'Converted spending: $amount $currency';
  String get currencyConversionUnavailable => _premiumDa
      ? 'En omregnet total er ikke tilgængelig. Oprindelige valutatal vises stadig.'
      : 'A converted total is unavailable. Original currency totals are still shown.';
  String exchangeRateSource(String provider, String date) => _premiumDa
      ? '$provider-referencekurser fra $date'
      : '$provider reference rates from $date';
}

String localizedCostEstimateExplanation(AppLocalizations l10n) =>
    l10n.localeName.toLowerCase().startsWith('da')
    ? 'Oprindelige totaler forbliver grupperet efter deres registrerede ISO-valuta. Når det er muligt, viser Keramik også et omregnet overslag med de seneste gemte ECB-referencekurser.'
    : 'Original totals remain grouped by their recorded ISO currency. When available, Keramik also shows a converted estimate using the latest cached ECB reference rates.';

String localizedInventoryAnalyticsExplanation(AppLocalizations l10n) =>
    l10n.localeName.toLowerCase().startsWith('da')
    ? 'Udgifter vises i oprindelig valuta samt som et omregnet sammendrag med gemte ECB-referencekurser, når de er tilgængelige. Forbrug er bekræftet nettoforbrug efter tilbageførsler.'
    : 'Spending is shown in its original currency and as a converted summary using cached ECB reference rates when available. Usage is confirmed net usage after reversals.';

extension LocalizedChatReportCategory on ChatReportCategory {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    ChatReportCategory.spam => l10n.reportSpam,
    ChatReportCategory.harassment => l10n.reportHarassment,
    ChatReportCategory.hate => l10n.reportHate,
    ChatReportCategory.sexualContent => l10n.reportSexualContent,
    ChatReportCategory.violence => l10n.reportViolence,
    ChatReportCategory.other => l10n.other,
  };
}

extension LocalizedChatReportValidationError on ChatReportValidationError {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    ChatReportValidationError.chooseReason => l10n.reportChooseReason,
    ChatReportValidationError.otherExplanationRequired =>
      l10n.reportOtherExplanationRequired,
    ChatReportValidationError.explanationTooLong =>
      l10n.reportExplanationTooLong,
  };
}

extension LocalizedAccountThemeMode on AccountThemeMode {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    AccountThemeMode.system => l10n.themeSystem,
    AccountThemeMode.light => l10n.themeLight,
    AccountThemeMode.dark => l10n.themeDark,
  };
}

extension LocalizedMeasurementSystem on MeasurementSystem {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    MeasurementSystem.metric => l10n.measurementMetric,
    MeasurementSystem.imperial => l10n.measurementImperial,
  };
}

extension LocalizedPrivacyAudience on PrivacyAudience {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    PrivacyAudience.everyone => l10n.privacyEveryone,
    PrivacyAudience.friends => l10n.privacyFriends,
    PrivacyAudience.friendsOfFriends => l10n.privacyFriendsOfFriends,
    PrivacyAudience.noOne => l10n.privacyNoOne,
  };
}

String localizedStageName(AppLocalizations l10n, String canonicalName) {
  return switch (canonicalName) {
    'Ideas' => l10n.stageIdeas,
    'Thrown' => l10n.stageThrown,
    'Trimmed' => l10n.stageTrimmed,
    'Bisqued' => l10n.stageBisqued,
    'Glazed' => l10n.stageGlazed,
    'Finished' => l10n.stageFinished,
    _ => canonicalName,
  };
}

String localizedTemplateTitlePatternHelp(AppLocalizations l10n) {
  final dynamic generatedValue = (l10n as dynamic).templateTitlePatternHelp;
  if (generatedValue is String) return generatedValue;
  if (generatedValue is Function) {
    return Function.apply(generatedValue, const ['{n}']) as String;
  }
  return l10n.localeName.toLowerCase().startsWith('da')
      ? 'Sæt n i krøllede parenteser, hvor batchnummeret skal stå.'
      : 'Place n inside braces where the batch number should appear.';
}

String localizedConfirmInventoryTransactionBody(
  AppLocalizations l10n,
  String type,
  String quantity,
  String unit,
  String material,
) {
  return l10n.localeName.toLowerCase().startsWith('da')
      ? '$type af $quantity $unit $material. Dette opdaterer lageret og føjer transaktionen til historikken.'
      : '$type $quantity $unit of $material. This updates your stock and adds the transaction to its history.';
}
