import 'package:flutter/material.dart';

class ConfirmActionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmar Ação'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Texto explicativo
            Text(
              'Tem certeza de que deseja realizar esta ação?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // Botões de confirmação
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botão Cancelar
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Retorna à tela anterior
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey, // Cor do botão
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancelar'),
                ),
                SizedBox(width: 20),
                // Botão Confirmar
                ElevatedButton(
                  onPressed: () {
                    // Ação a ser executada ao confirmar
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Cor do botão
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
