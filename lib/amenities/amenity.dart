/// [Amenity] represents any such facility that ought to be running through out the app's life cycle
/// and is required to achieve some heavy-lifting on behalf of the app (usually in the background).
///
/// An example would be a [NotificationsAmenity] or [DeepLinksAmenity].
abstract class Amenity<BootDataType> {
  /// A life cycle method that's called right when the app starts.
  ///
  /// Set up any listeners, streams, etc here.
  Future<BootDataType> bootUp();

  /// A callback method that's called once the amenity has bootedUp.
  ///
  /// [data] is same as the return value captured on executing bootUp.
  void onBootUp(BootDataType data);

  /// A life cycle method that's called right when the app is about to be terminated.
  ///
  /// Close any listeners, streams, etc here.
  void bootDown();
}
