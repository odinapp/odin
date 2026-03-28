import 'dart:io';

import 'package:dart_tui/dart_tui.dart';
import 'package:dio/dio.dart';
import 'package:odin_core/odin_core.dart';
import 'package:path/path.dart' as p;

enum _Screen {
  menu,
  uploadPick,
  uploadConfirm,
  uploadRunning,
  uploadDone,
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

  @override
  List<KeyBinding> get bindings => <KeyBinding>[
    up,
    down,
    done,
    selectDir,
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
  }) : spinner = spinner ?? SpinnerModel(suffix: ' Working...');

  factory _OdinTuiModel.initial({
    required OdinRepository repo,
    required Program program,
  }) {
    return _OdinTuiModel(
      repo: repo,
      program: program,
      screen: _Screen.menu,
      menu: SelectListModel(
        title: 'Odin CLI',
        items: const <String>['Upload', 'Download', 'Quit'],
      ),
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
    bool clearFilePicker = false,
    bool clearTokenInput = false,
    bool clearMetadata = false,
    bool clearError = false,
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

  (Model, Cmd?) _updateMenu(Msg msg) {
    if (msg is KeyMsg && msg.key == 'enter') {
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
      return (copyWith(outcome: 0), () => quit());
    }

    final (nextMenu, cmd) = menu.update(msg);
    return (copyWith(menu: nextMenu as SelectListModel), cmd);
  }

  (Model, Cmd?) _updateUploadPick(Msg msg) {
    final picker = filePicker;
    if (picker == null) {
      return (
        copyWith(
          screen: _Screen.menu,
          errorMessage: 'File picker unavailable.',
        ),
        null,
      );
    }

    if (msg is KeyMsg) {
      if (msg.key == 'esc') return (copyWith(screen: _Screen.menu), null);
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
        copyWith(
          screen: _Screen.menu,
          clearError: true,
          cancelToken: CancelToken(),
        ),
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
    if (msg.key == 'enter' || msg.key == 'esc') {
      return (copyWith(screen: _Screen.menu), null);
    }
    return (this, null);
  }

  (Model, Cmd?) _updateDownloadToken(Msg msg) {
    final input = tokenInput;
    if (input == null) return (copyWith(screen: _Screen.menu), null);

    if (msg is KeyMsg && msg.key == 'esc') {
      return (copyWith(screen: _Screen.menu), null);
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
    if (picker == null) return (copyWith(screen: _Screen.menu), null);

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
      if (msg.key == 'esc') return (copyWith(screen: _Screen.menu), null);
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
      return (copyWith(screen: _Screen.menu), null);
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
      return (copyWith(screen: _Screen.menu), null);
    }
    return (this, null);
  }

  (Model, Cmd?) _updateError(Msg msg) {
    if (msg is! KeyMsg) return (this, null);
    if (msg.key == 'enter' || msg.key == 'esc') {
      return (copyWith(screen: _Screen.menu, clearError: true), null);
    }
    return (this, null);
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

  @override
  View view() {
    final b = StringBuffer();
    b.writeln(const Style(isBold: true).render('ODIN CLI'));
    b.writeln();
    switch (screen) {
      case _Screen.menu:
        b.write(menu.view().content);
      case _Screen.uploadPick:
        b.writeln(
          'Upload: pick files/dirs (enter add file, s add current dir, d continue)',
        );
        b.writeln();
        b.write(filePicker?.view().content ?? '');
        b.writeln();
        b.writeln();
        b.writeln('Selected items (${selectedInputs.length}):');
        if (selectedInputs.isEmpty) {
          b.writeln('  (none)');
        } else {
          for (final input in selectedInputs.take(8)) {
            final isDir = FileSystemEntity.isDirectorySync(input);
            b.writeln('  - ${p.basename(input)}${isDir ? '/' : ''}');
          }
          if (selectedInputs.length > 8) {
            b.writeln('  ... ${selectedInputs.length - 8} more');
          }
        }
        b.writeln(
          'Keys: enter add/open · s add current dir · d continue · c clear · esc back',
        );
      case _Screen.uploadConfirm:
        final hasDirectory = selectedInputs.any(
          FileSystemEntity.isDirectorySync,
        );
        final totalBytes = selectedInputs.fold<int>(0, (sum, path) {
          if (File(path).existsSync()) return sum + File(path).lengthSync();
          return sum;
        });
        b.writeln('Upload confirm');
        b.writeln('Selected items: ${selectedInputs.length}');
        if (hasDirectory) {
          b.writeln(
            'Packaging: combined .zip will be created before upload (root folders preserved)',
          );
        } else {
          b.writeln('Total size: ${formatBytes(totalBytes)}');
        }
        b.writeln();
        b.writeln('Press enter to start upload, esc to go back.');
      case _Screen.uploadRunning:
        b.writeln('Uploading...');
        b.writeln();
        b.writeln(spinner.view().content);
        b.writeln();
        b.writeln(
          ProgressModel(
            fraction: uploadFraction,
            label: 'Progress',
            width: 48,
          ).view().content,
        );
        b.writeln('Press esc to cancel.');
      case _Screen.uploadDone:
        b.writeln('Upload complete.');
        b.writeln();
        b.writeln('Token: ${lastToken ?? ''}');
        b.writeln();
        b.writeln('Press enter to return to menu.');
      case _Screen.downloadToken:
        b.writeln('Download: enter token');
        b.writeln();
        b.write(tokenInput?.view().content ?? '');
        b.writeln();
        b.writeln();
        b.writeln('Press enter to continue, esc to menu.');
      case _Screen.downloadPickDir:
        b.writeln('Download: choose output directory');
        b.writeln();
        b.write(filePicker?.view().content ?? '');
        b.writeln();
        b.writeln();
        b.writeln('Metadata (optional):');
        if (metadataTable != null) {
          b.writeln(metadataTable!.view().content);
        } else if (metadataError != null) {
          b.writeln('  $metadataError');
        } else {
          b.writeln('  Loading metadata...');
        }
        b.writeln();
        b.writeln('Keys: s save here · enter choose selected · esc back');
      case _Screen.downloadRunning:
        b.writeln('Downloading...');
        b.writeln();
        b.writeln(spinner.view().content);
        b.writeln();
        b.writeln(
          ProgressModel(
            fraction: downloadFraction,
            label: 'Progress',
            width: 48,
          ).view().content,
        );
        b.writeln('Press esc to cancel.');
      case _Screen.downloadDone:
        b.writeln('Download complete.');
        b.writeln();
        b.writeln('Saved to: ${lastPath ?? ''}');
        b.writeln();
        b.writeln('Press enter to return to menu.');
      case _Screen.error:
        b.writeln('Error');
        b.writeln();
        b.writeln(errorMessage ?? 'Unknown error');
        b.writeln();
        b.writeln('Press enter to return to menu.');
    }

    if (showHelp) {
      b.writeln();
      b.writeln(help.view().content);
    } else {
      b.writeln();
      b.writeln(const Style(isDim: true).render('Press ? for key help.'));
    }

    return newView(b.toString());
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
  final model = _OdinTuiModel.initial(repo: repo, program: program);
  final code = await program.runForResult<int>(model);
  return code ?? 0;
}
