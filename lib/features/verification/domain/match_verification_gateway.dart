enum VerificationStatus { pending, verified, rejected, disputed }

/// Only the backend may attest attendance, settle disputes and award Elo.
/// A local boolean or GPS coordinate is never proof of eligibility.
abstract interface class MatchVerificationGateway {
  Future<VerificationStatus> checkIn(String matchId, String venueChallenge);
  Future<VerificationStatus> confirmResult(String matchId, String resultId);
  Future<VerificationStatus> status(String matchId);
}
