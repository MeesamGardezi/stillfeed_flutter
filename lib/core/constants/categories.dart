enum VideoCategory {
  nature,
  philosophy,
  skills,
  art,
  science,
  other;

  String get displayName {
    switch (this) {
      case VideoCategory.nature:
        return 'Nature';
      case VideoCategory.philosophy:
        return 'Philosophy';
      case VideoCategory.skills:
        return 'Skills';
      case VideoCategory.art:
        return 'Art';
      case VideoCategory.science:
        return 'Science';
      case VideoCategory.other:
        return 'Other';
    }
  }

  static VideoCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'nature':
        return VideoCategory.nature;
      case 'philosophy':
        return VideoCategory.philosophy;
      case 'skills':
        return VideoCategory.skills;
      case 'art':
        return VideoCategory.art;
      case 'science':
        return VideoCategory.science;
      default:
        return VideoCategory.other;
    }
  }

  String toJson() {
    return name;
  }
}

enum Feeling {
  calm,
  neutral,
  overstimulated;

  String get displayName {
    switch (this) {
      case Feeling.calm:
        return 'Calm & Present';
      case Feeling.neutral:
        return 'Neutral';
      case Feeling.overstimulated:
        return 'Overstimulated';
    }
  }

  String get emoji {
    switch (this) {
      case Feeling.calm:
        return '😌';
      case Feeling.neutral:
        return '😐';
      case Feeling.overstimulated:
        return '😵‍💫';
    }
  }

  String toJson() {
    return name;
  }
}