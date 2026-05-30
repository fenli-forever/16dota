# flutter_gemma pulls in MediaPipe APIs that reference optional proto classes.
# They are not needed by the app at runtime, but R8 treats the references as
# missing classes during release minification.
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
