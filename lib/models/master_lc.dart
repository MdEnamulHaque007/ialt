class MasterLC {
  final String id;
  final int slNo;
  final String tagNo;
  final String project;
  final String applicant;
  final String scNo;
  final String lcNo;
  final String ttNo;
  final String masterLcDate;
  final double masterLcValue;
  final double masterLcQty;
  final DateTime? createdAt;

  MasterLC({
    required this.id,
    required this.slNo,
    required this.tagNo,
    required this.project,
    required this.applicant,
    required this.scNo,
    required this.lcNo,
    required this.ttNo,
    required this.masterLcDate,
    required this.masterLcValue,
    required this.masterLcQty,
    this.createdAt,
  });

  // Firestore থেকে MasterLC object তৈরি
  factory MasterLC.fromFirestore(String id, Map<String, dynamic> data) {
    return MasterLC(
      id: id,
      slNo: (data['sl_no'] as num?)?.toInt() ?? 0,
      tagNo: data['tag_no']?.toString() ?? '',
      project: data['project']?.toString() ?? '',
      applicant: data['applicant']?.toString() ?? '',
      scNo: data['sc_no']?.toString() ?? '',
      lcNo: data['lc_no']?.toString() ?? '',
      ttNo: data['tt_no']?.toString() ?? '',
      masterLcDate: data['master_lc_date']?.toString() ?? '',
      masterLcValue: (data['master_lc_value'] as num?)?.toDouble() ?? 0.0,
      masterLcQty: (data['master_lc_qty'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as dynamic).toDate()
          : null,
    );
  }

  // Firestore এ save করার জন্য Map
  Map<String, dynamic> toFirestore() {
    return {
      'sl_no': slNo,
      'tag_no': tagNo,
      'project': project,
      'applicant': applicant,
      'sc_no': scNo,
      'lc_no': lcNo,
      'tt_no': ttNo,
      'master_lc_date': masterLcDate,
      'master_lc_value': masterLcValue,
      'master_lc_qty': masterLcQty,
      'created_at': createdAt ?? DateTime.now(),
    };
  }

  // Edit করার জন্য copy
  MasterLC copyWith({
    String? tagNo,
    String? project,
    String? applicant,
    String? scNo,
    String? lcNo,
    String? ttNo,
    String? masterLcDate,
    double? masterLcValue,
    double? masterLcQty,
  }) {
    return MasterLC(
      id: id,
      slNo: slNo,
      tagNo: tagNo ?? this.tagNo,
      project: project ?? this.project,
      applicant: applicant ?? this.applicant,
      scNo: scNo ?? this.scNo,
      lcNo: lcNo ?? this.lcNo,
      ttNo: ttNo ?? this.ttNo,
      masterLcDate: masterLcDate ?? this.masterLcDate,
      masterLcValue: masterLcValue ?? this.masterLcValue,
      masterLcQty: masterLcQty ?? this.masterLcQty,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'MasterLC(id: $id, tagNo: $tagNo, project: $project)';
}
