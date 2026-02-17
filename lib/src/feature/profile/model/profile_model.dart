import 'dart:convert';

final class CreateProfile {
  const CreateProfile({
    required this.uuid,
    required this.firstName,
    required this.dob,
    this.middleName,
    this.lastName,
    this.createdAt,
    this.updatedAt,
  });

  final String uuid;

  final String firstName;
  final String? middleName;
  final String? lastName;

  final DateTime dob;
  final int? createdAt;
  final int? updatedAt;

  factory CreateProfile.defaults({
    required String firstName,
    required DateTime dob,
    String? uuid,
    String? middleName,
    String? lastName,
    int? createdAt,
    int? updatedAt,
  }) {
    final timeStamp = DateTime.now().millisecondsSinceEpoch;

    /// Make do uuid for now, okay for scaffolding.
    final uuid = "${timeStamp ^ firstName.hashCode}";

    return CreateProfile(
      uuid: uuid,
      firstName: firstName,
      dob: dob,
      middleName: middleName ?? "",
      lastName: lastName ?? "",
      createdAt: timeStamp,
      updatedAt: timeStamp,
    );
  }
}

final class UpdateProfile {
  const UpdateProfile({
    required this.uuid,
    this.firstName,
    this.dob,
    this.middleName,
    this.lastName,
    this.createdAt,
    this.updatedAt,
  });

  final String uuid;

  final String? firstName;
  final String? middleName;
  final String? lastName;

  final DateTime? dob;
  final int? createdAt;
  final int? updatedAt;

  factory UpdateProfile.defaults({
    required String uuid,
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dob,
    int? createdAt,
    int? updatedAt,
  }) {
    return UpdateProfile(
      uuid: uuid,
      firstName: firstName,
      dob: dob,
      middleName: middleName ?? "",
      lastName: lastName ?? "",
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

final class Profile {
  const Profile({
    required this.uuid,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.dob,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uuid;

  final String firstName;
  final String middleName;
  final String lastName;

  final DateTime dob;
  final int createdAt;
  final int updatedAt;

  factory Profile.fromCreateProfile(CreateProfile cp) {
    final ts = switch (cp.createdAt) {
      null => DateTime.now().millisecondsSinceEpoch,
      _ => cp.createdAt!,
    };

    return Profile(
      uuid: cp.uuid,
      firstName: cp.firstName,
      middleName: cp.middleName ?? "",
      lastName: cp.lastName ?? "",
      dob: cp.dob,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  factory Profile.fromJsonString(String jsonString) =>
      .fromJson(jsonDecode(jsonString));

  factory Profile.fromJson(Map<String, dynamic> json) {
    if (json case {
      'uuid': String uuid,
      'firstName': String firstName,
      'middleName': String middleName,
      'lastName': String lastName,
      'dob': String dob,
      'createdAt': int createdAt,
      'updatedAt': int updatedAt,
    }) {
      return Profile(
        uuid: uuid,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        dob: DateTime.parse(dob),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } else {
      throw FormatException('Invalid JSON format for Profile', json);
    }
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'firstName': firstName,
    'middleName': middleName,
    'lastName': lastName,
    'dob': dob.toIso8601String(),
    'createdAt': createdAt,
    'updatedAt': createdAt,
  };
}
