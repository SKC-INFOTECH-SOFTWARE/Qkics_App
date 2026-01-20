double calculateExpertCompletion({
  required bool hasHeadline,
  required bool hasExperience,
  required bool hasEducation,
  required bool hasCertification,
  required bool hasHonor,
}) {
  final total = 5;
  int score = 0;

  if (hasHeadline) score++;
  if (hasExperience) score++;
  if (hasEducation) score++;
  if (hasCertification) score++;
  if (hasHonor) score++;

  return score / total;
}
