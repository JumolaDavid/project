import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// All domain and network modules errors are wrapped in implementations
/// of this class to ensure unification of the errors received.

abstract class DocumentedException with EquatableMixin implements Exception {
  final String message;
  final Object cause;

  DocumentedException({this.message, this.cause}){
    FirebaseCrashlytics.instance.recordError(toString(), null);
  }

  @override
  List<Object> get props => <Object>[message, cause];

  @override
  String toString() {
    return message ??
        (cause is Exception
            ? cause.toString()
            : "$runtimeType"
                "${message == null ? "" : "\nMessage: $message"}"
                "${cause == null ? "" : "\nCause: ${cause.toString()}"}");
  }
}
