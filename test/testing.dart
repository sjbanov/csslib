// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Common definitions used for setting up the test environment. */
library testing;

import 'package:csslib/parser.dart';
import 'package:csslib/visitor.dart';
import 'package:csslib/src/messages.dart';
import 'package:csslib/src/options.dart';
import 'package:test/test.dart';

export 'package:csslib/src/options.dart';

const simpleOptionsWithCheckedAndWarningsAsErrors = const PreprocessorOptions(
    useColors: false,
    checked: true,
    warningsAsErrors: true,
    inputFile: 'memory');

const simpleOptions =
    const PreprocessorOptions(useColors: false, inputFile: 'memory');

const options = const PreprocessorOptions(
    useColors: false, warningsAsErrors: true, inputFile: 'memory');

/**
 * Spin-up CSS parser in checked mode to detect any problematic CSS.  Normally,
 * CSS will allow any property/value pairs regardless of validity; all of our
 * tests (by default) will ensure that the CSS is really valid.
 */
StyleSheet parseCss(String cssInput,
        {List<Message> errors, PreprocessorOptions opts}) =>
    parse(cssInput,
        errors: errors,
        options:
            opts == null ? simpleOptionsWithCheckedAndWarningsAsErrors : opts);

/**
 * Spin-up CSS parser in checked mode to detect any problematic CSS.  Normally,
 * CSS will allow any property/value pairs regardless of validity; all of our
 * tests (by default) will ensure that the CSS is really valid.
 */
StyleSheet compileCss(String cssInput,
        {List<Message> errors,
        PreprocessorOptions opts,
        bool polyfill: false,
        List<StyleSheet> includes: null}) =>
    compile(cssInput,
        errors: errors,
        options:
            opts == null ? simpleOptionsWithCheckedAndWarningsAsErrors : opts,
        polyfill: polyfill,
        includes: includes);

StyleSheet polyFillCompileCss(input,
        {List<Message> errors, PreprocessorOptions opts}) =>
    compileCss(input, errors: errors, polyfill: true, opts: opts);

/** CSS emitter walks the style sheet tree and emits readable CSS. */
final _emitCss = new CssPrinter();

/** Simple Visitor does nothing but walk tree. */
final _cssVisitor = new Visitor();

/** Pretty printer for CSS. */
String prettyPrint(StyleSheet ss) {
  // Walk the tree testing basic Vistor class.
  walkTree(ss);
  return (_emitCss..visitTree(ss, pretty: true)).toString();
}

/**
 * Helper function to emit compact (non-pretty printed) CSS for suite test
 * comparsions.  Spaces, new lines, etc. are reduced for easier comparsions of
 * expected suite test results.
 */
String compactOuptut(StyleSheet ss) {
  walkTree(ss);
  return (_emitCss..visitTree(ss, pretty: false)).toString();
}

/** Walks the style sheet tree does nothing; insures the basic walker works. */
void walkTree(StyleSheet ss) {
  _cssVisitor..visitTree(ss);
}

String dumpTree(StyleSheet ss) => treeToDebugString(ss);

void expectError(ErrorMeta expectedError, message) {
  expect(expectedError.similarTo(message), isTrue, reason: expectedError.diff(message));
}

class ErrorMeta {
  final _SpanMeta start;
  final _SpanMeta end;

  ErrorMeta({this.start, this.end});

  factory ErrorMeta.oneLine(int line, int columnStart, int columnEnd) {
    return ErrorMeta(
      start: _SpanMeta(line: line, column: columnStart),
      end: _SpanMeta(line: line, column: columnEnd),
    );
  }

  bool similarTo(Message message) {
    return start.line == message.span.start.line + 1 &&
        start.column == message.span.start.column + 1 &&
        end.line == message.span.end.line + 1 &&
        end.column == message.span.end.column + 1;
  }

  String diff(Message message) {
    return 'Expected hightlight '
        '${_spanStringify(start.line, end.line, start.column, end.column)}\n'
        'but found ${_spanStringify(
            message.span.start.line + 1,
            message.span.end.line + 1,
            message.span.start.column + 1,
            message.span.end.column + 1)}\n'
        '${message.toString()}';
  }

  String _spanStringify(int lineStart, int lineEnd, columnStart, columnEnd) {
    if (lineStart == lineEnd) {
      return 'on line ${lineStart} from column ${columnStart} to ${columnEnd}';
    } else {
      return 'from line ${lineStart} column ${columnStart} to line ${lineEnd} column ${columnEnd}';
    }
  }
}

class _SpanMeta {
  final int line;
  final int column;

  _SpanMeta({this.line, this.column});
}
