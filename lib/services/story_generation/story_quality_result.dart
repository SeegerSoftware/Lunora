import 'package:equatable/equatable.dart';

/// Résultat du score qualité local (0–100), sans appel LLM.
class StoryQualityResult extends Equatable {
  const StoryQualityResult({
    required this.score,
    required this.isValid,
    required this.issues,
    this.lengthPoints = 0,
    this.namePoints = 0,
    this.structurePoints = 0,
    this.fluencyPoints = 0,
    this.tonePoints = 0,
    this.endingPoints = 0,
    this.narrativePoints = 0,
    this.profilePoints = 0,
    this.narrativeGuardPassed = true,
  });

  /// Score total sur 100.
  final int score;

  /// Seuil produit : score >= 70.
  final bool isValid;

  /// Problèmes détectés (lisible humain / logs).
  final List<String> issues;

  final int lengthPoints;
  final int namePoints;
  final int structurePoints;
  final int fluencyPoints;
  final int tonePoints;
  final int endingPoints;
  final int narrativePoints;
  final int profilePoints;
  final bool narrativeGuardPassed;

  @override
  List<Object?> get props => [
        score,
        isValid,
        issues,
        lengthPoints,
        namePoints,
        structurePoints,
        fluencyPoints,
        tonePoints,
        endingPoints,
        narrativePoints,
        profilePoints,
        narrativeGuardPassed,
      ];
}
