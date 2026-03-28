import 'dart:io';

import 'package:dart_tui/dart_tui.dart';
import 'package:dio/dio.dart';
import 'package:odin_core/odin_core.dart';
import 'package:path/path.dart' as p;

import 'cli_storage.dart';

/// Turn clipboard text into an 8-char file code when possible (raw code, URL, or line paste).
String _normalizeClipboardToToken(String raw) {
  final line = raw.split(RegExp(r'[\r\n]+')).first.trim();
  if (line.isEmpty) return '';
  try {
    return parseShareToken(line).fileCode;
  } on FormatException {
    final m = RegExp(r'[A-Za-z0-9]{8}').firstMatch(line);
    if (m != null) return m.group(0)!;
    return line;
  }
}

String _pendingTimeLeft(PendingUpload u) {
  final d = u.expiresAt.difference(DateTime.now());
  if (d.isNegative) return 'expired';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m left';
  if (m > 0) return '${m}m left';
  return 'soon';
}

String _fileSummaryFromPaths(List<String> paths) {
  if (paths.isEmpty) return '';
  final parts = paths.map((x) => p.basename(x)).join(', ');
  const maxLen = 56;
  if (parts.length <= maxLen) return parts;
  return '${parts.substring(0, maxLen - 3)}...';
}

String _pendingLineLabel(PendingUpload u) {
  final summary = u.fileSummary ?? '';
  final short = summary.length > 40
      ? '${summary.substring(0, 37)}...'
      : summary;
  final time = _pendingTimeLeft(u);
  if (short.isEmpty) return '${u.shareToken}  ($time)';
  return '${u.shareToken}  ($time)  $short';
}

/// Determinate bar matching [ProgressModel] glyphs, with a gradient on the filled segment.
String _gradientProgressView({
  required double fraction,
  required int width,
  required String label,
  required bool plainUi,
}) {
  final f = fraction.clamp(0.0, 1.0);
  final filled = (f * width).round().clamp(0, width);
  final empty = width - filled;
  final pct = (f * 100).round();
  const emptyStyle = Style(foregroundRgb: RgbColor(88, 91, 112));
  const labelStyle = Style(foregroundRgb: RgbColor(166, 173, 200));
  const pctStyle = Style(foregroundRgb: RgbColor(205, 214, 244), isBold: true);
  final filledStr = '█' * filled;
  final filledRendered = plainUi || filled == 0
      ? const Style(foregroundRgb: RgbColor(203, 166, 247)).render(filledStr)
      : gradientText(filledStr, const <RgbColor>[
          RgbColor(203, 166, 247),
          RgbColor(137, 180, 250),
          RgbColor(166, 227, 161),
        ]);
  final bar = '$filledRendered${emptyStyle.render('░' * empty)}';
  final labelPart = label.isEmpty ? '' : '${labelStyle.render(label)} ';
  return '$labelPart$bar ${pctStyle.render('$pct%')}';
}

enum _Screen {
  menu,
  uploadPick,
  uploadConfirm,
  uploadRunning,
  uploadDone,
  pendingPick,
  downloadToken,
  downloadPickDir,
  downloadRunning,
  downloadDone,
  error,
}

final class _UploadProgressMsg extends Msg {
  _UploadProgressMsg(this.sent, this.total);
  final int sent;
  final int total;
}

final class _UploadCompletedMsg extends Msg {
  _UploadCompletedMsg(this.result);
  final Result<UploadFilesSuccess, UploadFilesFailure> result;
}

final class _MetadataCompletedMsg extends Msg {
  _MetadataCompletedMsg(this.result);
  final Result<FetchFilesMetadataSuccess, FetchFilesMetadataFailure> result;
}

final class _DownloadProgressMsg extends Msg {
  _DownloadProgressMsg(this.received, this.total);
  final int received;
  final int total;
}

final class _DownloadCompletedMsg extends Msg {
  _DownloadCompletedMsg(this.result);
  final Result<DownloadFileSuccess, DownloadFileFailure> result;
}

final class _PendingUploadsUpdatedMsg extends Msg {
  _PendingUploadsUpdatedMsg(this.items);
  final List<PendingUpload> items;
}

final class _PendingDeleteResultMsg extends Msg {
  _PendingDeleteResultMsg({required this.ok, this.message});
  final bool ok;
  final String? message;
}

final class _TuiKeys implements KeyMap {
  const _TuiKeys();

  static const up = KeyBinding(
    keys: <String>['up', 'k'],
    help: (key: '↑/k', description: 'move up'),
  );
  static const down = KeyBinding(
    keys: <String>['down', 'j'],
    help: (key: '↓/j', description: 'move down'),
  );
  static const done = KeyBinding(
    keys: <String>['d'],
    help: (key: 'd', description: 'continue'),
  );
  static const selectDir = KeyBinding(
    keys: <String>['s'],
    help: (key: 's', description: 'select directory'),
  );
  static const back = KeyBinding(
    keys: <String>['esc'],
    help: (key: 'esc', description: 'back/cancel'),
  );
  static const helpKey = KeyBinding(
    keys: <String>['?'],
    help: (key: '?', description: 'toggle help'),
  );
  static const quit = KeyBinding(
    keys: <String>['q', 'ctrl+c'],
    help: (key: 'q', description: 'quit'),
  );
  static const copyToken = KeyBinding(
    keys: <String>['c'],
    help: (
      key: 'c',
      description:
          'copy token (after upload / pending list) · clear pick (upload)',
    ),
  );
  static const pasteToken = KeyBinding(
    keys: <String>['right'],
    help: (key: '→', description: 'paste clipboard at end of token field'),
  );
  static const pendingDelete = KeyBinding(
    keys: <String>['d'],
    help: (key: 'd', description: 'delete on server (pending list)'),
  );

  @override
  List<KeyBinding> get bindings => <KeyBinding>[
    up,
    down,
    done,
    selectDir,
    copyToken,
    pasteToken,
    pendingDelete,
    back,
    helpKey,
    quit,
  ];
}

final class _OdinTuiModel extends TeaModel implements OutcomeModel<int> {
  _OdinTuiModel({
    required this.repo,
    required this.program,
    required this.screen,
    required this.menu,
    required this.help,
    this.showHelp = false,
    this.filePicker,
    this.tokenInput,
    this.metadataTable,
    this.metadataError,
    this.selectedInputs = const <String>[],
    this.downloadToken = '',
    this.lastToken,
    this.lastPath,
    this.errorMessage,
    this.uploadFraction = 0,
    this.downloadFraction = 0,
    SpinnerModel? spinner,
    this.cancelToken,
    this.outcome,
    this.plainUi = false,
    this.statusBanner,
    required this.storage,
    this.pendingUploads = const <PendingUpload>[],
    this.pendingList,
    this.pendingNotice,
  }) : spinner = spinner ?? SpinnerModel(suffix: ' Working...');

  /// Main menu rows: Upload, Download, optional Pending uploads (N), Quit.
  static SelectListModel mainMenuFor({
    required List<PendingUpload> pendingUploads,
    int cursor = 0,
  }) {
    final items = <String>['Upload', 'Download'];
    if (pendingUploads.isNotEmpty) {
      items.add('Pending uploads (${pendingUploads.length})');
    }
    items.add('Quit');
    final c = cursor.clamp(0, items.length - 1);
    return SelectListModel(title: '', items: items, cursor: c);
  }

  factory _OdinTuiModel.initial({
    required OdinRepository repo,
    required Program program,
    required OdinStorage storage,
    List<PendingUpload> pendingUploads = const <PendingUpload>[],
    bool plainUi = false,
  }) {
    return _OdinTuiModel(
      repo: repo,
      program: program,
      storage: storage,
      pendingUploads: pendingUploads,
      plainUi: plainUi,
      screen: _Screen.menu,
      menu: mainMenuFor(pendingUploads: pendingUploads),
      help: HelpModel.fromKeyMap(const _TuiKeys()),
    );
  }

  final OdinRepository repo;
  final Program program;
  final _Screen screen;
  final SelectListModel menu;
  final HelpModel help;
  final bool showHelp;
  final FilePickerModel? filePicker;
  final TextInputModel? tokenInput;
  final TableModel? metadataTable;
  final String? metadataError;
  final List<String> selectedInputs;
  final String downloadToken;
  final String? lastToken;
  final String? lastPath;
  final String? errorMessage;
  final double uploadFraction;
  final double downloadFraction;
  final SpinnerModel spinner;
  final CancelToken? cancelToken;

  /// When true (e.g. `NO_COLOR`), skip RGB gradients in the view.
  final bool plainUi;

  /// Short-lived hint (e.g. after copying token to clipboard).
  final String? statusBanner;

  final OdinStorage storage;

  /// Non-expired uploads persisted for this CLI (`~/.odin/pending_uploads.json`).
  final List<PendingUpload> pendingUploads;

  /// Set on [pendingPick] only; labels from [_pendingLineLabel].
  final SelectListModel? pendingList;

  /// Status line on the pending screen (copy/delete feedback).
  final String? pendingNotice;

  @override
  final int? outcome;

  _OdinTuiModel copyWith({
    _Screen? screen,
    SelectListModel? menu,
    HelpModel? help,
    bool? showHelp,
    FilePickerModel? filePicker,
    TextInputModel? tokenInput,
    TableModel? metadataTable,
    String? metadataError,
    List<String>? selectedInputs,
    String? downloadToken,
    String? lastToken,
    String? lastPath,
    String? errorMessage,
    double? uploadFraction,
    double? downloadFraction,
    SpinnerModel? spinner,
    CancelToken? cancelToken,
    int? outcome,
    bool? plainUi,
    String? statusBanner,
    bool clearFilePicker = false,
    bool clearTokenInput = false,
    bool clearMetadata = false,
    bool clearError = false,
    bool clearStatusBanner = false,
    List<PendingUpload>? pendingUploads,
    SelectListModel? pendingList,
    String? pendingNotice,
    bool clearPendingList = false,
    bool clearPendingNotice = false,
  }) {
    return _OdinTuiModel(
      repo: repo,
      program: program,
      screen: screen ?? this.screen,
      menu: menu ?? this.menu,
      help: help ?? this.help,
      showHelp: showHelp ?? this.showHelp,
      filePicker: clearFilePicker ? null : (filePicker ?? this.filePicker),
      tokenInput: clearTokenInput ? null : (tokenInput ?? this.tokenInput),
      metadataTable: clearMetadata
          ? null
          : (metadataTable ?? this.metadataTable),
      metadataError: clearMetadata
          ? null
          : (metadataError ?? this.metadataError),
      selectedInputs: selectedInputs ?? this.selectedInputs,
      downloadToken: downloadToken ?? this.downloadToken,
      lastToken: lastToken ?? this.lastToken,
      lastPath: lastPath ?? this.lastPath,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      uploadFraction: uploadFraction ?? this.uploadFraction,
      downloadFraction: downloadFraction ?? this.downloadFraction,
      spinner: spinner ?? this.spinner,
      cancelToken: cancelToken ?? this.cancelToken,
      outcome: outcome ?? this.outcome,
      plainUi: plainUi ?? this.plainUi,
      statusBanner: clearStatusBanner
          ? null
          : (statusBanner ?? this.statusBanner),
      pendingUploads: pendingUploads ?? this.pendingUploads,
      pendingList: clearPendingList ? null : (pendingList ?? this.pendingList),
      pendingNotice: clearPendingNotice
          ? null
          : (pendingNotice ?? this.pendingNotice),
      storage: storage,
    );
  }

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) {
      if (msg.key == 'ctrl+c' || msg.key == 'q') {
        return (copyWith(outcome: 0), () => quit());
      }
      if (msg.key == '?') {
        return (copyWith(showHelp: !showHelp), null);
      }
    }

    if (msg is TickMsg) {
      final (nextSpinner, _) = spinner.update(msg);
      return (copyWith(spinner: nextSpinner as SpinnerModel), null);
    }

    if (msg is _PendingUploadsUpdatedMsg) {
      final next = msg.items;
      if (screen == _Screen.pendingPick) {
        if (next.isEmpty) {
          return (
            copyWith(
              pendingUploads: next,
              screen: _Screen.menu,
              clearPendingList: true,
              clearPendingNotice: true,
              menu: _OdinTuiModel.mainMenuFor(
                pendingUploads: next,
                cursor: menu.cursor,
              ),
            ),
            null,
          );
        }
        final pl = pendingList!;
        var nc = pl.cursor;
        if (nc >= next.length) {
          nc = next.length - 1;
        }
        return (
          copyWith(
            pendingUploads: next,
            pendingList: SelectListModel(
              title: '',
              items: next.map(_pendingLineLabel).toList(),
              cursor: nc,
            ),
          ),
          null,
        );
      }
      if (screen == _Screen.menu) {
        return (
          copyWith(
            pendingUploads: next,
            menu: _OdinTuiModel.mainMenuFor(
              pendingUploads: next,
              cursor: menu.cursor,
            ),
          ),
          null,
        );
      }
      return (copyWith(pendingUploads: next), null);
    }

    if (msg is _PendingDeleteResultMsg) {
      if (screen != _Screen.pendingPick) return (this, null);
      return _updatePendingPick(msg);
    }

    switch (screen) {
      case _Screen.menu:
        return _updateMenu(msg);
      case _Screen.uploadPick:
        return _updateUploadPick(msg);
      case _Screen.uploadConfirm:
        return _updateUploadConfirm(msg);
      case _Screen.uploadRunning:
        return _updateUploadRunning(msg);
      case _Screen.uploadDone:
        return _updateUploadDone(msg);
      case _Screen.pendingPick:
        return _updatePendingPick(msg);
      case _Screen.downloadToken:
        return _updateDownloadToken(msg);
      case _Screen.downloadPickDir:
        return _updateDownloadPickDir(msg);
      case _Screen.downloadRunning:
        return _updateDownloadRunning(msg);
      case _Screen.downloadDone:
        return _updateDownloadDone(msg);
      case _Screen.error:
        return _updateError(msg);
    }
  }

  _OdinTuiModel _withMainMenu() => copyWith(
    screen: _Screen.menu,
    clearPendingList: true,
    clearPendingNotice: true,
    menu: _OdinTuiModel.mainMenuFor(
      pendingUploads: pendingUploads,
      cursor: menu.cursor,
    ),
  );

  (Model, Cmd?) _updateMenu(Msg msg) {
    if (msg is KeyMsg && msg.key == 'enter') {
      final quitIdx = menu.items.length - 1;
      if (menu.cursor == quitIdx) {
        return (copyWith(outcome: 0), () => quit());
      }
      if (menu.cursor == 0) {
        final picker = FilePickerModel(
          currentDir: Directory.current.path,
          allowedExtensions: const <String>[],
          height: 12,
        );
        return (
          copyWith(
            screen: _Screen.uploadPick,
            filePicker: picker,
            selectedInputs: const <String>[],
          ),
          picker.init(),
        );
      }
      if (menu.cursor == 1) {
        return (
          copyWith(
            screen: _Screen.downloadToken,
            tokenInput: TextInputModel(
              label: 'Token:',
              placeholder: 'Paste token and press enter',
              value: '',
              cursorPos: 0,
            ),
            clearMetadata: true,
            clearError: true,
          ),
          null,
        );
      }
      if (pendingUploads.isNotEmpty && menu.cursor == 2) {
        return (
          copyWith(
            screen: _Screen.pendingPick,
            pendingList: SelectListModel(
              title: '',
              items: pendingUploads.map(_pendingLineLabel).toList(),
            ),
            clearPendingNotice: true,
          ),
          null,
        );
      }
      return (copyWith(outcome: 0), () => quit());
    }

    final (nextMenu, cmd) = menu.update(msg);
    return (copyWith(menu: nextMenu as SelectListModel), cmd);
  }

  (Model, Cmd?) _updatePendingPick(Msg msg) {
    final pl = pendingList;
    if (pl == null || pendingUploads.isEmpty) {
      return (
        copyWith(
          screen: _Screen.menu,
          clearPendingList: true,
          clearPendingNotice: true,
          menu: _OdinTuiModel.mainMenuFor(
            pendingUploads: pendingUploads,
            cursor: menu.cursor,
          ),
        ),
        null,
      );
    }

    if (msg is _PendingDeleteResultMsg) {
      if (!msg.ok) {
        return (copyWith(pendingNotice: msg.message ?? 'Delete failed'), null);
      }
      return (copyWith(pendingNotice: 'Deleted on server.'), null);
    }

    if (msg is KeyMsg && msg.key == 'esc') {
      return (
        copyWith(
          screen: _Screen.menu,
          clearPendingList: true,
          clearPendingNotice: true,
          menu: _OdinTuiModel.mainMenuFor(
            pendingUploads: pendingUploads,
            cursor: menu.cursor,
          ),
        ),
        null,
      );
    }

    if (msg is KeyMsg && msg.key == 'c') {
      final i = pl.cursor.clamp(0, pendingUploads.length - 1);
      final token = pendingUploads[i].shareToken;
      return (
        copyWith(pendingNotice: 'Copied token $token'),
        setClipboard(token),
      );
    }

    if (msg is KeyMsg && msg.key == 'd') {
      _deletePendingAtCursor();
      return (this, null);
    }

    final (nextList, cmd) = pl.update(msg);
    return (copyWith(pendingList: nextList as SelectListModel), cmd);
  }

  void _deletePendingAtCursor() {
    final pl = pendingList;
    if (pl == null || pendingUploads.isEmpty) return;
    final i = pl.cursor.clamp(0, pendingUploads.length - 1);
    _deletePendingOnServer(pendingUploads[i]);
  }

  void _deletePendingOnServer(PendingUpload upload) {
    Future<void>(() async {
      try {
        if (upload.deleteUrl.isEmpty) {
          program.send(
            _PendingDeleteResultMsg(
              ok: false,
              message: 'No delete URL stored for this upload.',
            ),
          );
          return;
        }
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(seconds: 25),
            validateStatus: (code) => code != null && code < 500,
            followRedirects: true,
            responseType: ResponseType.plain,
          ),
        );
        final response = await dio.get<dynamic>(upload.deleteUrl);
        final code = response.statusCode ?? 0;
        final ok = code >= 200 && code < 400;
        if (ok) {
          await storage.init();
          final list = (await storage.loadPendingUploads())
              .where((u) => u.id != upload.id)
              .toList();
          await storage.savePendingUploads(list);
          final fresh = list
              .where((u) => u.expiresAt.isAfter(DateTime.now()))
              .toList();
          program.send(_PendingUploadsUpdatedMsg(fresh));
          program.send(_PendingDeleteResultMsg(ok: true));
        } else {
          program.send(
            _PendingDeleteResultMsg(
              ok: false,
              message: 'Delete failed (HTTP $code)',
            ),
          );
        }
      } on Object catch (e) {
        program.send(_PendingDeleteResultMsg(ok: false, message: '$e'));
      }
    });
  }

  (Model, Cmd?) _updateUploadPick(Msg msg) {
    final picker = filePicker;
    if (picker == null) {
      return (
        _withMainMenu().copyWith(errorMessage: 'File picker unavailable.'),
        null,
      );
    }

    if (msg is KeyMsg) {
      if (msg.key == 'esc') return (_withMainMenu(), null);
      if (msg.key == 'd' && selectedInputs.isNotEmpty) {
        return (copyWith(screen: _Screen.uploadConfirm), null);
      }
      if (msg.key == 's') {
        final currentDir = picker.currentDir;
        if (!selectedInputs.contains(currentDir)) {
          return (
            copyWith(selectedInputs: <String>[...selectedInputs, currentDir]),
            null,
          );
        }
      }
      if (msg.key == 'c') {
        return (copyWith(selectedInputs: const <String>[]), null);
      }
    }

    final (nextPickerModel, cmd) = picker.update(msg);
    final nextPicker = nextPickerModel as FilePickerModel;
    final selected = nextPicker.selected;
    if (selected != null && !selectedInputs.contains(selected)) {
      final resetPicker = FilePickerModel(
        currentDir: nextPicker.currentDir,
        entries: nextPicker.entries,
        cursor: nextPicker.cursor,
        scrollOffset: nextPicker.scrollOffset,
        height: nextPicker.height,
        showHidden: nextPicker.showHidden,
        allowedExtensions: nextPicker.allowedExtensions,
        loading: nextPicker.loading,
      );
      return (
        copyWith(
          filePicker: resetPicker,
          selectedInputs: <String>[...selectedInputs, selected],
        ),
        cmd,
      );
    }

    return (copyWith(filePicker: nextPicker), cmd);
  }

  (Model, Cmd?) _updateUploadConfirm(Msg msg) {
    if (msg is! KeyMsg) return (this, null);
    if (msg.key == 'esc') return (copyWith(screen: _Screen.uploadPick), null);
    if (msg.key == 'enter') {
      final token = CancelToken();
      _startUpload(token);
      return (
        copyWith(
          screen: _Screen.uploadRunning,
          uploadFraction: 0,
          cancelToken: token,
          spinner: SpinnerModel(suffix: ' Uploading...'),
        ),
        null,
      );
    }
    return (this, null);
  }

  (Model, Cmd?) _updateUploadRunning(Msg msg) {
    if (msg is KeyMsg && msg.key == 'esc') {
      cancelToken?.cancel('Cancelled by user');
      return (
        _withMainMenu().copyWith(clearError: true, cancelToken: CancelToken()),
        null,
      );
    }

    if (msg case _UploadProgressMsg(:final sent, :final total)) {
      if (total <= 0) return (this, null);
      final fraction = (sent / total).clamp(0, 1).toDouble();
      return (copyWith(uploadFraction: fraction), null);
    }

    if (msg case _UploadCompletedMsg(:final result)) {
      return result.resolve(
        (success) {
          _persistPendingUpload(success);
          return (
            copyWith(
              screen: _Screen.uploadDone,
              lastToken: success.token,
              clearError: true,
              cancelToken: CancelToken(),
            ),
            null,
          );
        },
        (failure) {
          return (
            copyWith(
              screen: _Screen.error,
              errorMessage: failure.message ?? 'Upload failed',
              cancelToken: CancelToken(),
            ),
            null,
          );
        },
      );
    }

    return (this, null);
  }

  (Model, Cmd?) _updateUploadDone(Msg msg) {
    if (msg is! KeyMsg) return (this, null);
    if (msg.key == 'c' && (lastToken?.isNotEmpty ?? false)) {
      return (
        copyWith(statusBanner: 'Token copied to clipboard.'),
        setClipboard(lastToken!),
      );
    }
    if (msg.key == 'enter' || msg.key == 'esc') {
      return (_withMainMenu().copyWith(clearStatusBanner: true), null);
    }
    if (statusBanner != null) {
      return (copyWith(clearStatusBanner: true), null);
    }
    return (this, null);
  }

  (Model, Cmd?) _updateDownloadToken(Msg msg) {
    final input = tokenInput;
    if (input == null) return (_withMainMenu(), null);

    if (msg is ClipboardMsg) {
      final fragment = _normalizeClipboardToToken(msg.content);
      if (fragment.isEmpty) return (this, null);
      final merged = _mergeIntoTextInput(input, fragment);
      return (copyWith(tokenInput: merged), null);
    }

    if (msg is KeyMsg && msg.key == 'esc') {
      return (_withMainMenu(), null);
    }
    if (msg is KeyMsg &&
        msg.key == 'right' &&
        input.cursorPos >= input.value.length) {
      return (this, () => readClipboard());
    }
    if (msg is KeyMsg && msg.key == 'enter') {
      final token = input.value.trim();
      if (token.isEmpty) {
        return (
          copyWith(
            screen: _Screen.error,
            errorMessage: 'Token cannot be empty.',
          ),
          null,
        );
      }
      final picker = FilePickerModel(
        currentDir: Directory.current.path,
        allowedExtensions: const <String>[],
        height: 10,
      );
      _startFetchMetadata(token);
      return (
        copyWith(
          screen: _Screen.downloadPickDir,
          downloadToken: token,
          filePicker: picker,
          clearMetadata: true,
        ),
        picker.init(),
      );
    }

    final (updatedInput, cmd) = input.update(msg);
    return (copyWith(tokenInput: updatedInput as TextInputModel), cmd);
  }

  (Model, Cmd?) _updateDownloadPickDir(Msg msg) {
    final picker = filePicker;
    if (picker == null) return (_withMainMenu(), null);

    if (msg case _MetadataCompletedMsg(:final result)) {
      return result.resolve(
        (success) {
          final rows = <List<String>>[
            for (final file
                in success.filesMetadata.files ?? const <FileMetadata>[])
              <String>[
                p.basename(file.path ?? ''),
                file.path ?? '',
                file.size == null ? '' : formatBytes(file.size!),
              ],
          ];
          final table = TableModel(
            columns: const <TableColumn>[
              TableColumn(title: 'Name', width: 24),
              TableColumn(title: 'Path', width: 36),
              TableColumn(title: 'Size', width: 12),
            ],
            rows: rows,
            height: 6,
          );
          return (copyWith(metadataTable: table, metadataError: null), null);
        },
        (failure) {
          return (
            copyWith(
              metadataError: failure.message ?? 'Could not load metadata',
              clearMetadata: true,
            ),
            null,
          );
        },
      );
    }

    if (msg is KeyMsg) {
      if (msg.key == 'esc') return (_withMainMenu(), null);
      if (msg.key == 's') return _beginDownloadFromDir(picker.currentDir);
      if (msg.key == 'enter' && picker.selected != null) {
        final selected = picker.selected!;
        final dir = FileSystemEntity.isDirectorySync(selected)
            ? selected
            : p.dirname(selected);
        return _beginDownloadFromDir(dir);
      }
    }

    final (nextPickerModel, cmd) = picker.update(msg);
    final nextPicker = nextPickerModel as FilePickerModel;

    TableModel? nextTable = metadataTable;
    Cmd? nextCmd = cmd;
    if (msg is KeyMsg && metadataTable != null) {
      final (updatedTableModel, tableCmd) = metadataTable!.update(msg);
      nextTable = updatedTableModel as TableModel;
      nextCmd = batch(<Cmd?>[cmd, tableCmd]);
    }

    return (
      copyWith(filePicker: nextPicker, metadataTable: nextTable),
      nextCmd,
    );
  }

  (Model, Cmd?) _beginDownloadFromDir(String dir) {
    final token = CancelToken();
    _startDownload(dir, token);
    return (
      copyWith(
        screen: _Screen.downloadRunning,
        downloadFraction: 0,
        cancelToken: token,
        spinner: SpinnerModel(suffix: ' Downloading...'),
      ),
      null,
    );
  }

  (Model, Cmd?) _updateDownloadRunning(Msg msg) {
    if (msg is KeyMsg && msg.key == 'esc') {
      cancelToken?.cancel('Cancelled by user');
      return (_withMainMenu(), null);
    }
    if (msg case _DownloadProgressMsg(:final received, :final total)) {
      if (total <= 0) return (this, null);
      final fraction = (received / total).clamp(0, 1).toDouble();
      return (copyWith(downloadFraction: fraction), null);
    }
    if (msg case _DownloadCompletedMsg(:final result)) {
      return result.resolve(
        (success) {
          return (
            copyWith(
              screen: _Screen.downloadDone,
              lastPath: success.outputPath,
              clearError: true,
            ),
            null,
          );
        },
        (failure) {
          return (
            copyWith(
              screen: _Screen.error,
              errorMessage: failure.message ?? 'Download failed',
            ),
            null,
          );
        },
      );
    }
    return (this, null);
  }

  (Model, Cmd?) _updateDownloadDone(Msg msg) {
    if (msg is! KeyMsg) return (this, null);
    if (msg.key == 'enter' || msg.key == 'esc') {
      return (_withMainMenu(), null);
    }
    return (this, null);
  }

  (Model, Cmd?) _updateError(Msg msg) {
    if (msg is! KeyMsg) return (this, null);
    if (msg.key == 'enter' || msg.key == 'esc') {
      return (_withMainMenu().copyWith(clearError: true), null);
    }
    return (this, null);
  }

  void _persistPendingUpload(UploadFilesSuccess success) {
    final paths = List<String>.from(selectedInputs);
    Future<void>(() async {
      try {
        final deleteUrl = success.deleteToken ?? '';
        await storage.init();
        var list = await storage.loadPendingUploads();
        list = list.where((u) => u.expiresAt.isAfter(DateTime.now())).toList();
        if (deleteUrl.isNotEmpty) {
          list = list.where((u) => u.deleteUrl != deleteUrl).toList();
        }
        final now = DateTime.now();
        final summaryLabel = _fileSummaryFromPaths(paths);
        list.insert(
          0,
          PendingUpload(
            id: now.millisecondsSinceEpoch.toString(),
            shareToken: success.token,
            deleteUrl: deleteUrl,
            expiresAt: now.add(Duration(hours: kPendingUploadTtlHours)),
            createdAt: now,
            fileSummary: summaryLabel.isEmpty ? null : summaryLabel,
          ),
        );
        await storage.savePendingUploads(list);
        final fresh = await storage.loadPendingUploads();
        program.send(
          _PendingUploadsUpdatedMsg(
            fresh.where((u) => u.expiresAt.isAfter(DateTime.now())).toList(),
          ),
        );
      } on Object {
        // Ignore persistence failures (read-only home, etc.).
      }
    });
  }

  void _startUpload(CancelToken token) {
    Future<void>(() async {
      try {
        final result = await repo.uploadFilesAnonymous(
          request: UploadFilesRequest(
            files: const <File>[],
            inputPaths: selectedInputs,
            cancelToken: token,
            onSendProgress: (sent, total) =>
                program.send(_UploadProgressMsg(sent, total)),
          ),
        );
        program.send(_UploadCompletedMsg(result));
      } on FileSystemException catch (e) {
        program.send(
          _UploadCompletedMsg(
            Failure(
              UploadFilesFailure(
                message: 'Input error: ${e.path ?? ''} ${e.message}',
              ),
            ),
          ),
        );
      } catch (e) {
        program.send(
          _UploadCompletedMsg(
            Failure(UploadFilesFailure(message: e.toString())),
          ),
        );
      }
    });
  }

  void _startFetchMetadata(String token) {
    Future<void>(() async {
      final result = await repo.fetchFilesMetadata(
        request: FetchFilesMetadataRequest(token: token),
      );
      program.send(_MetadataCompletedMsg(result));
    });
  }

  /// Inserts [fragment] at [input]'s cursor (used after clipboard read).
  TextInputModel _mergeIntoTextInput(TextInputModel input, String fragment) {
    final limit = input.charLimit;
    var insert = fragment;
    if (limit > 0) {
      final room = limit - input.value.length;
      if (room <= 0) return input;
      if (insert.length > room) insert = insert.substring(0, room);
    }
    final newValue =
        input.value.substring(0, input.cursorPos) +
        insert +
        input.value.substring(input.cursorPos);
    final newPos = input.cursorPos + insert.length;
    return input.copyWith(value: newValue, cursorPos: newPos);
  }

  void _startDownload(String dir, CancelToken token) {
    Future<void>(() async {
      final result = await repo.downloadFile(
        request: DownloadFileRequest(
          token: downloadToken,
          savePath: dir,
          cancelToken: token,
          onReceiveProgress: (received, total) =>
              program.send(_DownloadProgressMsg(received, total)),
        ),
      );
      program.send(_DownloadCompletedMsg(result));
    });
  }

  String _brandTitle() {
    if (plainUi) {
      return const Style(isBold: true).render('ODIN CLI');
    }
    return gradientText('ODIN CLI', const <RgbColor>[
      RgbColor(203, 166, 247),
      RgbColor(137, 180, 250),
      RgbColor(166, 227, 161),
    ]);
  }

  String _sectionTitle(String text) {
    if (plainUi) {
      return const Style(
        foregroundRgb: RgbColor(203, 166, 247),
        isBold: true,
      ).render(text);
    }
    return gradientText(text, const <RgbColor>[
      RgbColor(203, 166, 247),
      RgbColor(137, 180, 250),
    ]);
  }

  @override
  View view() {
    final body = StringBuffer();

    switch (screen) {
      case _Screen.menu:
        final tagline = const Style(
          isDim: true,
        ).render('Encrypted share · pick an action');
        final listBlock = menu.view().content;
        final navHint = const Style(isDim: true).render('↑/↓ j/k · enter');
        body.writeln(
          joinHorizontal(0.0, <String>[
            joinVertical(0.0, <String>[tagline, '', listBlock]),
            navHint,
          ]),
        );
        if (pendingUploads.isNotEmpty) {
          body.writeln();
          body.writeln(
            const Style(isDim: true).render(
              'Select "Pending uploads" to scroll, copy token (c), or delete on server (d).',
            ),
          );
        }
      case _Screen.uploadPick:
        body.writeln(_sectionTitle('Upload'));
        body.writeln(
          const Style(isDim: true).render(
            'Pick files or folders · enter add file · s add cwd · d continue',
          ),
        );
        body.writeln();
        body.write(filePicker?.view().content ?? '');
        body.writeln();
        body.writeln();
        body.writeln(
          const Style(
            isBold: true,
          ).render('Selected (${selectedInputs.length})'),
        );
        if (selectedInputs.isEmpty) {
          body.writeln(const Style(isDim: true).render('  (none)'));
        } else {
          for (final input in selectedInputs.take(8)) {
            final isDir = FileSystemEntity.isDirectorySync(input);
            body.writeln(
              '  ${const Style(foregroundRgb: RgbColor(166, 227, 161)).render('-')} '
              '${p.basename(input)}${isDir ? '/' : ''}',
            );
          }
          if (selectedInputs.length > 8) {
            body.writeln(
              const Style(
                isDim: true,
              ).render('  ... ${selectedInputs.length - 8} more'),
            );
          }
        }
        body.writeln();
        body.writeln(
          const Style(
            isDim: true,
          ).render('enter open · s dir · d done · c clear · esc back'),
        );
      case _Screen.uploadConfirm:
        final hasDirectory = selectedInputs.any(
          FileSystemEntity.isDirectorySync,
        );
        final totalBytes = selectedInputs.fold<int>(0, (sum, path) {
          if (File(path).existsSync()) return sum + File(path).lengthSync();
          return sum;
        });
        body.writeln(_sectionTitle('Confirm upload'));
        body.writeln('Items: ${selectedInputs.length}');
        if (hasDirectory) {
          body.writeln(
            const Style(
              isDim: true,
            ).render('Folders → combined .zip (roots preserved)'),
          );
        } else {
          body.writeln('Size: ${formatBytes(totalBytes)}');
        }
        body.writeln();
        body.writeln(
          const Style(isDim: true).render('enter upload · esc back'),
        );
      case _Screen.uploadRunning:
        body.writeln(_sectionTitle('Uploading'));
        body.writeln();
        body.writeln(spinner.view().content);
        body.writeln();
        body.writeln(
          _gradientProgressView(
            fraction: uploadFraction,
            width: 48,
            label: 'Progress',
            plainUi: plainUi,
          ),
        );
        body.writeln();
        body.writeln(const Style(isDim: true).render('esc cancel'));
      case _Screen.uploadDone:
        body.writeln(_sectionTitle('Upload complete'));
        body.writeln();
        final tok = lastToken ?? '';
        final tokenLine = joinHorizontal(0.0, <String>[
          const Style(isBold: true).render('Token  '),
          if (plainUi)
            Style(foregroundRgb: const RgbColor(166, 227, 161)).render(tok)
          else
            gradientText(tok, const <RgbColor>[
              RgbColor(166, 227, 161),
              RgbColor(137, 180, 250),
            ]),
        ]);
        body.writeln(tokenLine);
        final banner = statusBanner;
        if (banner != null) {
          body.writeln();
          body.writeln(
            const Style(foregroundRgb: RgbColor(166, 227, 161)).render(banner),
          );
        }
        body.writeln();
        body.writeln(
          const Style(isDim: true).render('c copy · enter menu · esc menu'),
        );
      case _Screen.pendingPick:
        body.writeln(_sectionTitle('Pending uploads'));
        body.writeln(
          const Style(isDim: true).render(
            '↑/↓ j/k move · c copy token · d delete on server · esc back',
          ),
        );
        body.writeln();
        if (pendingList != null) {
          body.write(pendingList!.view().content);
        }
        final notice = pendingNotice;
        if (notice != null && notice.isNotEmpty) {
          body.writeln();
          body.writeln(
            const Style(foregroundRgb: RgbColor(166, 227, 161)).render(notice),
          );
        }
      case _Screen.downloadToken:
        body.writeln(_sectionTitle('Download'));
        body.writeln(
          const Style(isDim: true).render(
            'Paste or type an 8-character code · → at end reads clipboard',
          ),
        );
        body.writeln();
        body.write(tokenInput?.view().content ?? '');
        body.writeln();
        body.writeln();
        body.writeln(
          const Style(isDim: true).render('enter continue · esc menu'),
        );
      case _Screen.downloadPickDir:
        body.writeln(_sectionTitle('Save to folder'));
        body.writeln();
        body.write(filePicker?.view().content ?? '');
        body.writeln();
        body.writeln();
        body.writeln(const Style(isBold: true).render('Metadata'));
        if (metadataTable != null) {
          body.writeln(metadataTable!.view().content);
        } else if (metadataError != null) {
          body.writeln('  $metadataError');
        } else {
          body.writeln(const Style(isDim: true).render('  Loading...'));
        }
        body.writeln();
        body.writeln(
          const Style(isDim: true).render('s here · enter on file · esc back'),
        );
      case _Screen.downloadRunning:
        body.writeln(_sectionTitle('Downloading'));
        body.writeln();
        body.writeln(spinner.view().content);
        body.writeln();
        body.writeln(
          _gradientProgressView(
            fraction: downloadFraction,
            width: 48,
            label: 'Progress',
            plainUi: plainUi,
          ),
        );
        body.writeln();
        body.writeln(const Style(isDim: true).render('esc cancel'));
      case _Screen.downloadDone:
        body.writeln(_sectionTitle('Download complete'));
        body.writeln();
        body.writeln('Saved to: ${lastPath ?? ''}');
        body.writeln();
        body.writeln(const Style(isDim: true).render('enter · esc → menu'));
      case _Screen.error:
        body.writeln(
          const Style(
            foregroundRgb: RgbColor(243, 139, 168),
            isBold: true,
          ).render('Error'),
        );
        body.writeln();
        body.writeln(errorMessage ?? 'Unknown error');
        body.writeln();
        body.writeln(const Style(isDim: true).render('enter · esc → menu'));
    }

    final footer = showHelp
        ? help.view().content
        : const Style(isDim: true).render('Press ? for key help.');

    final composed = joinVertical(0.0, <String>[
      _brandTitle(),
      '',
      body.toString().trimRight(),
      '',
      footer,
    ]);

    return newView(composed);
  }
}

Future<int> runTui({
  required OdinRepository repo,
  required bool isJson,
  required bool noColor,
  required bool verbose,
}) async {
  final options = <ProgramOption>[
    withCellRenderer(),
    if (noColor) withColorProfile(ColorProfile.noColor),
  ];

  final program = Program(
    options: const ProgramOptions(
      altScreen: true,
      tickInterval: Duration(milliseconds: 100),
    ),
    programOptions: options,
  );
  final storage = CliOdinStorage();
  await storage.init();
  final loaded = await storage.loadPendingUploads();
  final pending = loaded
      .where((u) => u.expiresAt.isAfter(DateTime.now()))
      .toList();

  final model = _OdinTuiModel.initial(
    repo: repo,
    program: program,
    storage: storage,
    pendingUploads: pending,
    plainUi: noColor,
  );
  final code = await program.runForResult<int>(model);
  return code ?? 0;
}
