import 'package:flutter/material.dart';

/// Um banner de notificação que aparece na parte superior da tela
/// para informar ao usuário que ele precisa verificar a conta.
class VerificationBanner extends StatelessWidget {
  final String message; // NOVO: Mensagem customizável
  final String buttonLabel; // NOVO: Texto do botão customizável
  final VoidCallback onPressed; // NOVO: Ação customizável do botão
  final Color backgroundColor; // NOVO: Cor de fundo customizável
  final Color textColor; // NOVO: Cor do texto customizável
  final IconData? icon; // NOVO: Ícone opcional

  const VerificationBanner({
    super.key,
    this.message = 'Your account must be validated.', // PADRÃO: Mensagem padrão
    this.buttonLabel = 'Validate now', // PADRÃO: Texto padrão do botão
    required this.onPressed, // Ação do botão é obrigatória
    this.backgroundColor = Colors.orange, // PADRÃO: Cor laranja para atenção
    this.textColor = Colors.white, // PADRÃO: Texto branco para contraste
    this.icon = Icons.warning_amber_rounded, // PADRÃO: Ícone de aviso
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor, // Usa a cor de fundo customizável
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // PADRÃO: Padding simétrico
      child: SafeArea( // PADRÃO: Para evitar invasão da barra de status
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (icon != null) // NOVO: Exibe o ícone se ele existir
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(icon, color: textColor), // Ícone com a cor do texto
              ),
            Expanded(
              child: Text(
                message, // Usa a mensagem customizável
                style: TextStyle(color: textColor, fontSize: 14.0), // Usa a cor e tamanho do texto customizáveis
              ),
            ),
            TextButton(
              onPressed: onPressed, // Usa a ação customizável do botão
              child: Text(
                buttonLabel, // Usa o texto do botão customizável
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}