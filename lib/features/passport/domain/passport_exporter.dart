import 'dart:typed_data';

/// Render an approved summary as 1080 x 1920 PNG with explicit sharing consent.
abstract interface class PassportExporter {
  Future<Uint8List> exportPng(
    String confirmedMatchId, {
    required bool includeHealth,
    required bool includeParticipantNames,
  });
}
