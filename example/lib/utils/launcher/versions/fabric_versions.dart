/// Fabric Meta also lists technical and experimental game versions that are
/// not part of the normal release and snapshot catalog.
bool isRegularFabricGameVersion(Object? version) {
  if (version is! String) return false;
  return RegExp(r'^(?:\d+\.\d+(?:\.\d+)?(?:-(?:pre|rc)\d+)?|\d{2}w\d{2}[a-z])$').hasMatch(version);
}
