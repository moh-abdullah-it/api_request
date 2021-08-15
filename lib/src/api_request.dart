enum ContentDataType { formData, bodyData }

mixin ApiRequest {
  ContentDataType? get contentDataType => ContentDataType.bodyData;
  Map<String, dynamic> toMap();
}
