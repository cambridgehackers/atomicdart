import 'package:path/path.dart' as pathos;

import 'package:analyzer_experimental/src/error.dart';
import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/parser.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:analyzer_experimental/src/generated/source_io.dart';
import 'package:analyzer_experimental/src/string_source.dart';

export 'package:analyzer_experimental/src/error.dart';
export 'package:analyzer_experimental/src/generated/ast.dart';
export 'package:analyzer_experimental/src/generated/error.dart';
export 'package:analyzer_experimental/src/generated/utilities_dart.dart';

CompilationUnit parseDartLambdaString(String contents, String path) {
  var errorCollector = new _ErrorCollector();
  var sourceFactory = new SourceFactory.con2([new FileUriResolver()]);

  var absolutePath = pathos.absolute(path);
  var source = sourceFactory.forUri(pathos.toUri(absolutePath).toString());
  if (source == null) {
    throw new ArgumentError("Can't get source for path $path");
  }
  if (!source.exists()) {
    throw new ArgumentError("Source $source doesn't exist");
  }

  var scanner = new StringScanner(source, contents, errorCollector);
  var token = scanner.tokenize();
  var parser = new Parser(source, errorCollector);
  var unit = parser.parseCompilationUnit(token);
  unit.lineInfo = new LineInfo(scanner.lineStarts);

  if (errorCollector.hasErrors) throw errorCollector.group;

  return unit;
}

/// A simple error listener that collects errors into an [AnalysisErrorGroup].
class _ErrorCollector extends AnalysisErrorListener {
  final _errors = <AnalysisError>[];

  /// Whether any errors where collected.
  bool get hasErrors => !_errors.isEmpty;

  /// The group of errors collected.
  AnalyzerErrorGroup get group =>
    new AnalyzerErrorGroup.fromAnalysisErrors(_errors);

  _ErrorCollector();

  void onError(AnalysisError error) => _errors.add(error);
}

class MyAstVisitor extends GeneralizingASTVisitor<Object> {
      MyAstVisitor() : super() {}

      Object visitFunctionExpressionInvocation(n) {
         print("visitFunctionExpressionInvocation $n");
	 return super.visitFunctionExpressionInvocation(n);
      }
      Object visitMethodInvocation(n) {
         print("visitMethodInvocation $n");
	 return super.visitMethodInvocation(n);
      }
}