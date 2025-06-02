import 'package:flutter/material.dart';

/// Um utilitário para exibir e ocultar Snackbars persistentes de forma padronizada,
/// com opções de customização visual para se adequar ao tema do aplicativo.
class PersistentSnackbar {
  /// Exibe um SnackBar persistente no `ScaffoldMessenger` do contexto fornecido.
  ///
  /// Ele remove qualquer SnackBar atualmente visível antes de mostrar um novo.
  /// Opcionalmente, pode incluir uma ação e customizações visuais.
  ///
  /// [context]: O BuildContext do widget a partir do qual o SnackBar será exibido.
  /// [message]: A mensagem principal a ser exibida no SnackBar.
  /// [actionLabel]: O texto do botão de ação no SnackBar (opcional).
  /// [onActionPressed]: A função a ser executada quando o botão de ação é pressionado (opcional).
  /// [duration]: A duração pela qual o SnackBar ficará visível. Padrão é 4 segundos.
  ///             Defina como null ou Duration.zero para um SnackBar que só pode ser ocultado manualmente.
  /// [backgroundColor]: A cor de fundo do SnackBar. Padrão é a cor de fundo do tema.
  /// [textColor]: A cor do texto da mensagem. Padrão é a cor do texto no SnackBar do tema.
  /// [icon]: Um ícone opcional para exibir à esquerda da mensagem.
  /// [iconColor]: A cor do ícone.
  static void show({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor, // NOVO: Cor de fundo customizável
    Color? textColor,      // NOVO: Cor do texto customizável
    IconData? icon,        // NOVO: Ícone customizável
    Color? iconColor,      // NOVO: Cor do ícone
  }) {
    // Remover qualquer SnackBar atualmente visível para evitar empilhamento
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    // Obtém o tema atual para defaults
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Personaliza a cor de fundo
        backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHighest, // Ou theme.snackBarTheme.backgroundColor
        duration: duration,
        behavior: SnackBarBehavior.floating, // Flutuante para dar um visual mais moderno

        content: Row(
          children: [
            if (icon != null) // NOVO: Adiciona o ícone se ele for fornecido
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(icon, color: iconColor ?? colorScheme.onSurface), // Cor do ícone
              ),
            Expanded( // Expande o texto para preencher o espaço restante
              child: Text(
                message,
                style: TextStyle(color: textColor ?? colorScheme.onSurface), // Cor do texto
              ),
            ),
          ],
        ),
        action: (actionLabel != null && onActionPressed != null)
            ? SnackBarAction(
          label: actionLabel,
          onPressed: onActionPressed,
          textColor: textColor ?? colorScheme.primary, // Cor do texto da ação (pode ser a cor primária do tema)
        )
            : null,
      ),
    );
  }

  /// Oculta qualquer SnackBar atualmente visível.
  ///
  /// [context]: O BuildContext a partir do qual o SnackBar está sendo exibido.
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }
}