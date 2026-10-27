// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/library_data.dart';
import '../theme/tokens.dart';
import 'dialogs.dart';
import 'page_scaffold.dart';

/// Pide el nombre de una carpeta, nueva o al renombrar. Devuelve el nombre
/// sin espacios en los extremos, o null si se cancela o queda vacío.
Future<String?> showFolderNameDialog(
  BuildContext context, {
  String initialName = '',
}) async {
  final rename = initialName.isNotEmpty;
  final name = await showTextPrompt(
    context,
    title: rename ? context.l10n.folderRename : context.l10n.folderNew,
    hint: context.l10n.folderNameHint,
    initialValue: initialName,
    confirmLabel: rename ? context.l10n.commonSave : context.l10n.folderCreate,
  );
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// Confirma el borrado de una carpeta. El texto aclara que los cuadernos
/// no se borran, que es lo que más asusta de borrar una carpeta.
Future<bool> confirmDeleteFolder(BuildContext context, Folder folder) =>
    showConfirmDialog(
      context,
      title: context.l10n.folderDelete,
      message: context.l10n.folderDeleteBody(folder.name),
      confirmLabel: context.l10n.libDelete,
      destructive: true,
    );

/// Lo que se eligió en [showMoveToFolderSheet]: una carpeta (`id`), sin
/// carpeta (`id` null) o crear una nueva (`createNew`).
typedef FolderPick = ({String? id, bool createNew});

/// Hoja para elegir la carpeta de un cuaderno. Devuelve null si se cancela.
Future<FolderPick?> showMoveToFolderSheet(
  BuildContext context, {
  required List<Folder> folders,
  required String? currentId,
}) {
  return showModalBottomSheet<FolderPick>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      Widget option(IconData icon, String label, FolderPick pick) {
        final selected = !pick.createNew && pick.id == currentId;
        return ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: selected ? const Icon(Icons.check) : null,
          selected: selected,
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
          onTap: () => Navigator.pop(context, pick),
        );
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              0,
              Spacing.lg,
              Spacing.lg,
            ),
            children: [
              SheetHeader(
                icon: Icons.drive_file_move_outlined,
                title: context.l10n.folderMoveTo,
              ),
              option(Icons.folder_off_outlined, context.l10n.folderNone, (
                id: null,
                createNew: false,
              )),
              for (final f in folders)
                option(Icons.folder_outlined, f.name, (
                  id: f.id,
                  createNew: false,
                )),
              option(Icons.create_new_folder_outlined, context.l10n.folderNew, (
                id: null,
                createNew: true,
              )),
            ],
          ),
        ),
      );
    },
  );
}
