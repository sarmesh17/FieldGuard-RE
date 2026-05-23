class UpdateTaskRequest {
  final String? status;
  final String? remarks;
  final String? changeReason;
  final String? cancelReason;
  final String? cancelImage;

  const UpdateTaskRequest({
    this.status,
    this.remarks,
    this.changeReason,
    this.cancelReason,
    this.cancelImage,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (status != null) map['status'] = status;
    if (remarks != null) map['remarks'] = remarks;
    if (changeReason != null && changeReason!.isNotEmpty) {
      map['changeReason'] = changeReason;
    }
    if (cancelReason != null) map['cancelReason'] = cancelReason;
    if (cancelImage != null) map['cancelImage'] = cancelImage;
    return map;
  }
}
