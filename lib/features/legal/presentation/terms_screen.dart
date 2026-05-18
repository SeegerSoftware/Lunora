import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../routing/safe_navigation.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String routePath = '/terms';
  static const String versionLabel = '18 mai 2026';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ElunaiAppBar(
        title: 'CGU',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePopOrGo('/welcome'),
        ),
      ),
      body: LunoraScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: ListView(
            padding: LunoraSpacing.screen,
            children: [
              LunoraFadeIn(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conditions générales d’utilisation',
                        style: LunoraTextStyles.sectionTitle(theme.textTheme),
                      ),
                      const SizedBox(height: LunoraSpacing.xs),
                      Text(
                        'Version du $versionLabel',
                        style: _mutedStyle(theme),
                      ),
                      const SizedBox(height: LunoraSpacing.lg),
                      _LegalNotice(
                        text:
                            'Ces CGU encadrent l’accès et l’utilisation de l’application Elunai, aussi appelée Lunora dans certains supports de projet. Elles ne remplacent pas une politique de confidentialité, des mentions légales complètes ni les conditions de la boutique d’applications utilisée.',
                      ),
                      const SizedBox(height: LunoraSpacing.lg),
                      ..._sections.map(
                        (section) => _TermsSection(section: section),
                      ),
                      const SizedBox(height: LunoraSpacing.xl),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.safePopOrGo('/welcome'),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Retour'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.section});

  final _TermsContent section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: LunoraSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: _titleStyle(theme)),
          const SizedBox(height: LunoraSpacing.xs),
          ...section.paragraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: LunoraSpacing.sm),
              child: Text(paragraph, style: _bodyStyle(theme)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalNotice extends StatelessWidget {
  const _LegalNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LunoraColors.nightBlueLift.withValues(alpha: 0.10),
        borderRadius: LunoraSpacing.radiusMd,
        border: Border.all(
          color: LunoraColors.forestGreen.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LunoraSpacing.md),
        child: Text(text, style: _bodyStyle(theme)),
      ),
    );
  }
}

TextStyle? _titleStyle(ThemeData theme) {
  return theme.textTheme.titleSmall?.copyWith(
    color: LunoraColors.storybookInk,
    fontWeight: FontWeight.w900,
    height: 1.25,
  );
}

TextStyle? _bodyStyle(ThemeData theme) {
  return theme.textTheme.bodyMedium?.copyWith(
    color: LunoraColors.storybookInk.withValues(alpha: 0.82),
    height: 1.5,
  );
}

TextStyle? _mutedStyle(ThemeData theme) {
  return theme.textTheme.bodySmall?.copyWith(
    color: LunoraColors.storybookInkMuted,
    height: 1.4,
  );
}

class _TermsContent {
  const _TermsContent({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}

const List<_TermsContent> _sections = [
  _TermsContent(
    title: '1. Objet',
    paragraphs: [
      'Les présentes conditions générales d’utilisation définissent les règles applicables à l’utilisation d’Elunai, une application de génération et de lecture d’histoires personnalisées pour enfants.',
      'L’application est destinée aux parents, représentants légaux ou adultes autorisés. Les enfants peuvent écouter ou lire les histoires sous la responsabilité d’un adulte.',
    ],
  ),
  _TermsContent(
    title: '2. Acceptation des CGU',
    paragraphs: [
      'La création d’un compte, la connexion, l’utilisation de l’application ou la souscription à une offre payante impliquent l’acceptation des présentes CGU.',
      'Si vous n’acceptez pas les CGU, vous devez cesser d’utiliser l’application.',
    ],
  ),
  _TermsContent(
    title: '3. Compte utilisateur',
    paragraphs: [
      'L’utilisateur crée un compte avec une adresse e-mail, un mot de passe ou un fournisseur d’authentification pris en charge. Il doit fournir des informations exactes et garder ses identifiants confidentiels.',
      'Toute activité réalisée depuis le compte est réputée effectuée par l’utilisateur, sauf preuve d’une utilisation frauduleuse non imputable à celui-ci.',
    ],
  ),
  _TermsContent(
    title: '4. Profil enfant',
    paragraphs: [
      'L’application peut demander des informations sur l’enfant, par exemple son prénom, son année de naissance, ses thèmes préférés, ses sensibilités ou les sujets à éviter, afin de personnaliser les histoires.',
      'L’utilisateur garantit qu’il est parent, représentant légal ou autorisé à renseigner ces informations. Il s’engage à ne pas saisir de données inutiles, sensibles ou excessives.',
    ],
  ),
  _TermsContent(
    title: '5. Génération d’histoires',
    paragraphs: [
      'Les histoires sont générées automatiquement à partir des informations fournies et peuvent varier d’une utilisation à l’autre. Elles sont proposées à des fins de divertissement, de lecture et de rituel familial.',
      'Les contenus générés ne constituent pas un conseil médical, psychologique, éducatif professionnel ou thérapeutique. L’adulte reste responsable de vérifier que l’histoire est adaptée à l’enfant avant lecture.',
      'L’application met en œuvre des mécanismes de modération et de sécurité, sans garantir l’absence totale d’erreur, d’imprécision ou de contenu inadapté.',
    ],
  ),
  _TermsContent(
    title: '6. Abonnement et paiement',
    paragraphs: [
      'Certaines fonctionnalités peuvent nécessiter un abonnement payant. L’offre actuellement présentée dans l’application est l’offre Elunai, facturée CHF 5.99 par mois, sauf indication différente affichée au moment de la souscription.',
      'Les paiements sont traités par Stripe ou par la boutique d’applications concernée selon le canal utilisé. Les conditions de paiement, de renouvellement, de résiliation et de remboursement applicables sont celles affichées lors de l’achat et celles du prestataire de paiement ou de la boutique.',
      'L’accès aux fonctionnalités payantes peut être suspendu ou limité si le paiement échoue, si l’abonnement expire ou si une fraude est suspectée.',
    ],
  ),
  _TermsContent(
    title: '7. Utilisation acceptable',
    paragraphs: [
      'L’utilisateur s’engage à utiliser l’application de manière loyale, licite et conforme à sa destination.',
      'Il est interdit de tenter de contourner les protections techniques, d’accéder au compte d’un tiers, de perturber le service, d’utiliser l’application pour produire des contenus illicites, violents, haineux, discriminatoires, sexuels, harcelants ou portant atteinte aux droits d’autrui.',
    ],
  ),
  _TermsContent(
    title: '8. Propriété intellectuelle',
    paragraphs: [
      'L’application, son interface, ses éléments graphiques, son code, ses marques, ses noms, ses textes non générés par l’utilisateur et sa structure sont protégés par les droits de propriété intellectuelle applicables.',
      'L’utilisateur conserve les droits qu’il détient sur les informations qu’il saisit. Il autorise leur utilisation technique dans la mesure nécessaire au fonctionnement, à la personnalisation et à la sécurisation du service.',
      'Les histoires générées sont fournies pour un usage personnel et familial. Toute exploitation commerciale, redistribution massive ou publication publique sans autorisation préalable est interdite.',
    ],
  ),
  _TermsContent(
    title: '9. Données personnelles',
    paragraphs: [
      'L’application utilise notamment Firebase pour l’authentification et le stockage, un backend serveur pour les opérations sensibles, OpenAI pour la génération de contenu et Stripe pour les paiements.',
      'Les traitements de données personnelles doivent être détaillés dans une politique de confidentialité séparée. L’utilisateur peut demander la suppression de son compte et des données associées depuis l’espace parent lorsque cette fonctionnalité est disponible.',
      'Pour les mineurs, l’utilisation et la saisie des données doivent être encadrées par un parent, un représentant légal ou un adulte autorisé.',
    ],
  ),
  _TermsContent(
    title: '10. Disponibilité du service',
    paragraphs: [
      'L’application est fournie avec un objectif de disponibilité raisonnable. Des interruptions peuvent survenir pour maintenance, mise à jour, incident technique, évolution de prestataires tiers ou cas de force majeure.',
      'L’éditeur peut modifier, suspendre ou arrêter tout ou partie des fonctionnalités, notamment pour améliorer le service, renforcer la sécurité ou respecter une obligation légale.',
    ],
  ),
  _TermsContent(
    title: '11. Responsabilité',
    paragraphs: [
      'L’éditeur ne peut être tenu responsable des dommages indirects, pertes de données imputables à un tiers, indisponibilités externes, mauvaise utilisation du service ou conséquences d’une lecture non supervisée par un adulte.',
      'La responsabilité de l’éditeur ne saurait excéder les montants effectivement payés par l’utilisateur pour le service sur les douze derniers mois, sauf disposition légale contraire.',
    ],
  ),
  _TermsContent(
    title: '12. Suspension et suppression',
    paragraphs: [
      'L’éditeur peut suspendre ou supprimer un compte en cas de violation des CGU, fraude, risque de sécurité, demande légale ou usage portant atteinte au service ou à des tiers.',
      'L’utilisateur peut demander la suppression de son compte. Cette suppression peut entraîner la perte définitive des profils enfant, histoires, mémoires narratives et données associées, sous réserve des obligations légales de conservation.',
    ],
  ),
  _TermsContent(
    title: '13. Modification des CGU',
    paragraphs: [
      'Les CGU peuvent être modifiées pour tenir compte des évolutions de l’application, de l’offre, des prestataires, de la législation ou des exigences de sécurité.',
      'La version applicable est celle disponible dans l’application au moment de l’utilisation. En cas de modification substantielle, une information adaptée pourra être affichée dans l’application.',
    ],
  ),
  _TermsContent(
    title: '14. Droit applicable',
    paragraphs: [
      'Sauf règle impérative contraire, les présentes CGU sont régies par le droit suisse lorsque l’éditeur est établi en Suisse, ou par le droit applicable au lieu d’établissement de l’éditeur si celui-ci diffère.',
      'En cas de litige, l’utilisateur est invité à contacter l’éditeur afin de rechercher une solution amiable avant toute démarche contentieuse.',
    ],
  ),
  _TermsContent(
    title: '15. Contact',
    paragraphs: [
      'Pour toute question relative aux CGU, à l’application, à un compte ou à une demande de suppression, l’utilisateur peut contacter l’éditeur par les moyens de support indiqués dans l’application, sur le site officiel ou sur la fiche de la boutique d’applications.',
    ],
  ),
];
