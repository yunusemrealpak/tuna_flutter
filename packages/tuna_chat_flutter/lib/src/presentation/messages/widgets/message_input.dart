import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.channelId,
    required this.onSend,
    this.isSending = false,
    this.onTypingChanged,
    this.hintText = 'Message...',
  });

  final String channelId;

  /// Called when the user taps send.
  /// [fileBytes] and [fileName] are non-null when the user has selected a file.
  final void Function(
    String text,
    List<int>? fileBytes,
    String? fileName,
  ) onSend;

  final bool isSending;
  final void Function(bool isTyping)? onTypingChanged;
  final String hintText;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  // Selected attachment state.
  List<int>? _fileBytes;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      widget.onTypingChanged?.call(hasText);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes!;
        _fileName = result.files.single.name;
      });
    }
  }

  void _clearAttachment() {
    setState(() {
      _fileBytes = null;
      _fileName = null;
    });
  }

  bool get _canSend =>
      (_hasText || _fileBytes != null) && !widget.isSending;

  void _send() {
    final text = _controller.text.trim();
    // Allow sending attachment with empty text (empty string placeholder).
    if ((!_hasText && _fileBytes == null) || widget.isSending) return;
    widget.onSend(
      text.isEmpty ? ' ' : text,
      _fileBytes,
      _fileName,
    );
    _controller.clear();
    _clearAttachment();
    widget.onTypingChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Selected file chip ─────────────────────────────────────────
            if (_fileName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Chip(
                  avatar: const Icon(Icons.attach_file, size: 16),
                  label: Text(
                    _fileName!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: _clearAttachment,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            // ── Text field + buttons row ───────────────────────────────────
            Row(
              children: [
                // Attachment picker button.
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Attach file',
                  onPressed: widget.isSending ? null : _pickFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !widget.isSending,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: widget.isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send_rounded),
                          onPressed: _canSend ? _send : null,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
