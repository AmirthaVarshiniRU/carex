class Exercise {
  final String id;
  final String name;
  final String description;
  final int duration;
  final int reps;
  final String? imageUrl;
  final String videoUrl;
  final String instructions;
  final String benefits;
  final String precautions;
  final int difficulty;
  final String category;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.reps,
    this.imageUrl,
    required this.videoUrl,
    required this.instructions,
    required this.benefits,
    required this.precautions,
    required this.difficulty,
    required this.category,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      duration: map['duration'] as int,
      reps: map['reps'] as int,
      imageUrl: map['imageUrl'] as String?,
      videoUrl: map['videoUrl'] as String,
      instructions: map['instructions'] as String,
      benefits: map['benefits'] as String,
      precautions: map['precautions'] as String,
      difficulty: map['difficulty'] as int,
      category: map['category'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'reps': reps,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'instructions': instructions,
      'benefits': benefits,
      'precautions': precautions,
      'difficulty': difficulty,
      'category': category,
    };
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    int? duration,
    int? reps,
    String? imageUrl,
    String? videoUrl,
    String? instructions,
    String? benefits,
    String? precautions,
    int? difficulty,
    String? category,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      reps: reps ?? this.reps,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      instructions: instructions ?? this.instructions,
      benefits: benefits ?? this.benefits,
      precautions: precautions ?? this.precautions,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
    );
  }
}
