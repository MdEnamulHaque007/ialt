class ActivityLog {
  final String id;
  final String action;
  final String details;
  final String user;
  final String module;
  final String slNo;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.action,
    required this.details,
    required this.user,
    required this.module,
    required this.slNo,
    required this.timestamp,
  });

  factory ActivityLog.fromFirestore(String id, Map<String, dynamic> data) {
    return ActivityLog(
      id: id,
      action: data['action']?.toString() ?? '',
      details: data['details']?.toString() ?? '',
      user: data['user']?.toString() ?? '',
      module: data['module']?.toString() ?? '',
      slNo: data['slNo']?.toString() ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'details': details,
      'user': user,
      'module': module,
      'slNo': slNo,
      'timestamp': timestamp,
    };
  }
}
