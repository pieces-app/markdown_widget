import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:runtime_client/particle.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/configs.dart';
import '../../span_node.dart';

///Tag: [MarkdownTag.a]
///
///Link reference definitions, A link reference definition consists of a link label
///link will always be wrapped by other tags, such as [MarkdownTag.p]

class LinkNode extends ElementNode {
  final Map<String, String> attributes;
  final LinkConfig linkConfig;

  LinkNode(this.attributes, this.linkConfig);

  @override
  InlineSpan build() {
    final url = attributes['href'] ?? '';

    // Instead of wrapping everything in a WidgetSpan, return a list of inline spans
    // for the text content and only use WidgetSpan for the copy button
    List<InlineSpan> spans = [];

    // Add the link text spans that can be selected
    for (final child in children) {
      spans.add(_toLinkInlineSpan(
        child.build(),
            () => _onLinkTap(linkConfig, url),
      ));
    }

    // Add a space after the text
    if (children.isNotEmpty) {
      spans.add(TextSpan(text: ' '));
    }

    // Only use WidgetSpan for the copy button
    if (linkConfig.onCopy != null) {
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: CopyActionButton(
          content: url,
          micro: true,
          tooltip: 'Copy URL: $url',
          copyCallback: linkConfig.onCopy,
        ),
      ));
    }

    // Return a TextSpan that wraps all the spans
    return TextSpan(
      children: spans,
      style: style,
    );
  }

  void _onLinkTap(LinkConfig linkConfig, String url) {
    if (linkConfig.onTap != null) {
      linkConfig.onTap?.call(url);
    } else {
      launchUrl(Uri.parse(url));
    }
  }

  @override
  TextStyle get style => parentStyle?.merge(linkConfig.style) ?? linkConfig.style;
}

///config class for link, tag: a
class LinkConfig implements LeafConfig {
  final TextStyle style;
  final ValueCallback<String>? onTap;
  final Future<void> Function(String)? onCopy;

  const LinkConfig({
    this.style = const TextStyle(color: Color(0xff0969da), decoration: TextDecoration.underline),
    this.onTap,
    this.onCopy,
  });

  @nonVirtual
  @override
  String get tag => MarkdownTag.a.name;
}

// add a tap gesture recognizer to the span.
InlineSpan _toLinkInlineSpan(InlineSpan span, VoidCallback onTap) {
  if (span is TextSpan) {
    span = TextSpan(
      text: span.text,
      children: span.children?.map((e) => _toLinkInlineSpan(e, onTap)).toList(),
      style: span.style,
      recognizer: TapGestureRecognizer()..onTap = onTap,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  } else if (span is WidgetSpan) {
    span = WidgetSpan(
      child: InkWell(
        child: span.child,
        onTap: onTap,
      ),
      alignment: span.alignment,
      baseline: span.baseline,
      style: span.style,
    );
  }
  return span;
}
