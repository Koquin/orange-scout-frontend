import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:OrangeScoutFE/view/createTeamScreen.dart';
// Import your DTOs
import 'package:OrangeScoutFE/dto/team_dto.dart';
import 'package:OrangeScoutFE/dto/player_dto.dart'; // Import PlayerDTO

// Import your controllers
import 'package:OrangeScoutFE/controller/player_controller.dart';
import 'package:OrangeScoutFE/controller/team_controller.dart';

// Import your utility
import 'package:OrangeScoutFE/util/persistent_snackbar.dart';


class EditTeamScreen extends StatefulWidget {
  final int teamId;

  const EditTeamScreen({super.key, required this.teamId});

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  // CORREÇÃO: Mude a lista para PlayerDTO
  List<PlayerDTO> players = [];
  bool isLoading = true;
  bool _hasError = false; // Novo: Para erros críticos de carregamento

  final PlayerController _playerController = PlayerController();
  final TeamController _teamController = TeamController();

  // Variáveis para edição de detalhes do time (se forem editadas nesta tela)
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _abbreviationController = TextEditingController();
  String? _logoPath; // Caminho da logo
  File? _selectedImage; // Imagem selecionada para upload
  bool _isFetchingDetails = false; // Para controlar o carregamento dos detalhes do time

  final String fallbackImage = "assets/images/TeamShieldIcon-cutout.png"; // Garanta que esta variável seja acessível globalmente ou no estado


  @override
  void initState() {
    super.initState();
    _setPortraitOrientation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'EditTeamPlayersScreen',
        screenClass: 'EditTeamScreenState',
        parameters: {'team_id': widget.teamId},
      );
    });
    // Chamadas para carregar detalhes do time e jogadores
    _fetchTeamDetails(); // Para preencher nome/logo/abrev. (se editável nesta tela)
    _fetchPlayers();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _abbreviationController.dispose();
    super.dispose();
  }

  // Garante orientação de retrato para esta tela
  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Busca os detalhes do time existente para preencher o formulário (se necessário para edição de detalhes).
  /// Esta lógica foi consolidada no CreateTeamScreen para evitar duplicação,
  /// mas se EditTeamScreen também tiver campos de nome/logo, a lógica é assim.
  Future<void> _fetchTeamDetails() async {
    setState(() {
      _isFetchingDetails = true;
      isLoading = true; // Para desabilitar tudo enquanto carrega
    });
    FirebaseAnalytics.instance.logEvent(name: 'fetch_team_details_attempt_edit_screen', parameters: {'team_id': widget.teamId});
    FirebaseCrashlytics.instance.log('Trying to fetch team details to edit: ${widget.teamId}');

    final TeamDTO? fetchedTeamData = await _teamController.fetchTeamDetails(widget.teamId);

    if (mounted) {
      if (fetchedTeamData != null) {
        // Preencher controladores com os dados do time
        _teamNameController.text = fetchedTeamData.teamName;
        _abbreviationController.text = fetchedTeamData.abbreviation;
        _logoPath = fetchedTeamData.logoPath;
        if (_logoPath != null && (_logoPath!.startsWith('/data/') || _logoPath!.startsWith('file://') || File(_logoPath!).existsSync())) {
          _selectedImage = File(_logoPath!);
        } else {
          _selectedImage = null;
        }
        FirebaseAnalytics.instance.logEvent(name: 'team_details_fetched_success_edit_screen', parameters: {'team_id': widget.teamId});
      } else {
        PersistentSnackbar.show(
          context: context,
          message: 'Failed to fetch team details or team not found.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
        FirebaseAnalytics.instance.logEvent(name: 'fetch_team_details_failed_edit_screen', parameters: {'team_id': widget.teamId, 'reason': 'not_found'});
        Navigator.pop(context); // Volta se não conseguir carregar os detalhes
      }
    }
    setState(() {
      _isFetchingDetails = false;
      isLoading = false; // Reabilita a UI
    });
  }


  Future<void> _fetchPlayers() async {
    setState(() {
      isLoading = true;
      _hasError = false; // Reseta o estado de erro
    });
    FirebaseAnalytics.instance.logEvent(name: 'fetch_players_for_team_attempt', parameters: {'team_id': widget.teamId});
    FirebaseCrashlytics.instance.log('Trying to fetch player for the team: ${widget.teamId}.');

    try {
      // CORREÇÃO: O controlador já retorna List<PlayerDTO>
      List<PlayerDTO> fetchedPlayers = await _playerController.fetchPlayersByTeamId(widget.teamId);

      setState(() {
        players = fetchedPlayers; // Atribui diretamente a lista de PlayerDTOs
        isLoading = false;
      });

      if (fetchedPlayers.isEmpty && mounted) {
        PersistentSnackbar.show(
          context: context,
          message: 'No player found for this team, add some!',
          backgroundColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          icon: Icons.info_outline,
        );
        FirebaseAnalytics.instance.logEvent(name: 'no_players_found_for_team');
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Error fetching players for the team: ${widget.teamId}');
      setState(() {
        isLoading = false;
        _hasError = true;
      });
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: 'Error fetching players. Try again.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
      }
    }
  }

  /// Adiciona uma nova linha para um jogador (estado local antes de salvar no backend).
  void addNewPlayerRow() {
    setState(() {
      // CORREÇÃO: Adiciona um PlayerDTO "vazio" para o novo jogador
      players.add(PlayerDTO(
        idPlayer: null, // ID nulo para novo jogador
        playerName: '',
        jerseyNumber: '',
        // teamId e teamName serão preenchidos na hora de enviar ao backend
      ));
    });
    FirebaseAnalytics.instance.logEvent(name: 'add_new_player_row');
  }

  /// Confirma e salva um novo jogador no backend.
  Future<void> confirmNewPlayer(int index, String name, String number) async {
    if (name.isEmpty || number.isEmpty) {
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: "Please, fill both fields (name and number).",
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
        );
      }
      FirebaseAnalytics.instance.logEvent(name: 'add_player_failed', parameters: {'reason': 'empty_fields_dialog'});
      return;
    }

    setState(() => isLoading = true);
    // CORREÇÃO: Chama o controlador com os dados corretos
    final PlayerOperationResult result = await _playerController.addPlayer(
      playerName: name,
      jerseyNumber: number,
      teamId: widget.teamId, // Passa o ID do time
    );

    if (mounted) {
      if (result.success) {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? "Player added successfully!",
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
        await _fetchPlayers(); // Atualiza a lista após adicionar
      } else {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Unknown error adding player.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
      }
    }
    setState(() => isLoading = false);
  }

  /// Deleta um jogador do backend.
  Future<void> deletePlayer(int index) async {
    final PlayerDTO playerToDelete = players[index]; // CORREÇÃO: Pega o PlayerDTO
    final id = playerToDelete.idPlayer; // CORREÇÃO: Acessa idPlayer

    if (id == null) {
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: 'Error: Player ID not found to deletion.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
        );
      }
      FirebaseAnalytics.instance.logEvent(name: 'delete_player_failed', parameters: {'reason': 'player_id_null'});
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm player deletion'),
        content: const Text('Are you sure to delete this player?'),
        actions: [
          TextButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(name: 'delete_player_canceled');
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(name: 'delete_player_confirmed');
              Navigator.of(context).pop(true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == null || !confirm) return;

    setState(() => isLoading = true);
    // CORREÇÃO: Chama o controlador e trata o resultado
    final PlayerOperationResult result = await _playerController.deletePlayer(id);

    if (mounted) {
      if (result.success) {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? "Player successfully deleted!",
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
        await _fetchPlayers(); // Atualiza a lista após deletar
      } else {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Unknown error deleting player.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
      }
    }
    setState(() => isLoading = false);
  }

  /// Edita um jogador existente no backend.
  Future<void> editPlayer(int index) async {
    final PlayerDTO playerToEdit = players[index]; // CORREÇÃO: Pega o PlayerDTO
    final id = playerToEdit.idPlayer; // CORREÇÃO: Acessa idPlayer

    if (id == null) {
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: 'Error: Player ID not found to edit.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
        );
      }
      FirebaseAnalytics.instance.logEvent(name: 'edit_player_failed', parameters: {'reason': 'player_id_null'});
      return;
    }

    setState(() => isLoading = true);
    // CORREÇÃO: Chama o controlador e trata o resultado
    final PlayerOperationResult result = await _playerController.editPlayer(
      playerId: id,
      playerName: playerToEdit.playerName, // CORREÇÃO: Acessa playerName
      jerseyNumber: playerToEdit.jerseyNumber, // CORREÇÃO: Acessa jerseyNumber
    );

    if (mounted) {
      if (result.success) {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? "Jogador atualizado com sucesso!",
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
        await _fetchPlayers(); // Atualiza a lista após editar
      } else {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Unknown error updating player.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
      }
    }
    setState(() => isLoading = false);
  }

  /// Exibe um diálogo para editar nome e número de um jogador existente.
  void showEditDialog(int index) {
    FirebaseAnalytics.instance.logEvent(name: 'edit_player_dialog_opened', parameters: {'player_id': players[index].idPlayer}); // CORREÇÃO: idPlayer
    final PlayerDTO player = players[index]; // CORREÇÃO: PlayerDTO
    final TextEditingController nameController = TextEditingController(text: player.playerName); // CORREÇÃO: playerName
    final TextEditingController numberController = TextEditingController(text: player.jerseyNumber); // CORREÇÃO: jerseyNumber

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Edit player", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Jersey number", labelStyle: TextStyle(color: Colors.white70)), // Localizado
                style: const TextStyle(color: Colors.white),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Apenas dígitos
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Player name", labelStyle: TextStyle(color: Colors.white70)), // Localizado
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
              onPressed: () {
                FirebaseAnalytics.instance.logEvent(name: 'edit_player_dialog_canceled');
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save", style: TextStyle(color: Colors.green)),
              onPressed: () {
                FirebaseAnalytics.instance.logEvent(name: 'edit_player_dialog_saved');
                // CORREÇÃO: Atualiza o PlayerDTO no estado local antes de chamar o backend
                setState(() {
                  players[index] = players[index].copyWith( // Usa copyWith para atualizar PlayerDTO
                    playerName: nameController.text,
                    jerseyNumber: numberController.text,
                  );
                });
                Navigator.of(context).pop();
                editPlayer(index); // Chama o método para enviar ao backend
              },
            ),
          ],
        );
      },
    );
  }

  /// Deleta um time completo do backend.
  Future<void> _deleteTeam() async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_team_button_tapped_edit_screen');
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm team deletion'),
          content: const Text('Are you sure to delete this team ? This cannot be undone and all players will be deleted.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                FirebaseAnalytics.instance.logEvent(name: 'delete_team_canceled');
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAnalytics.instance.logEvent(name: 'delete_team_confirmed');
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == null || !confirmDelete) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    // CORREÇÃO: Chama o controlador e trata o resultado
    final TeamOperationResult result = await _teamController.deleteTeam(widget.teamId);

    if (mounted) {
      if (result.success) {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Team successfully deleted!',
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
        Navigator.pop(context, true); // Retorna 'true' para a tela pai (TeamsScreen)
      } else {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Failed deleting team.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  /// Constrói uma linha de jogador no ListView (existente ou novo).
  Widget _buildPlayerRow(PlayerDTO player, int index) { // CORREÇÃO: Parâmetro PlayerDTO
    // Se o jogador é novo (ainda não salvo), exibe os campos de entrada
    if (player.idPlayer == null) { // CORREÇÃO: idPlayer para verificar se é novo
      TextEditingController nameController = TextEditingController(text: player.playerName);
      TextEditingController numberController = TextEditingController(text: player.jerseyNumber);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField( // Use TextField for inline editing
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: "Nº",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    // Update the local DTO in state as user types
                    players[index] = players[index].copyWith(jerseyNumber: value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: TextField( // Use TextField for inline editing
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Name", // Localizado
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    // Update the local DTO in state as user types
                    players[index] = players[index].copyWith(playerName: value);
                  },
                ),
              ),
              // Botão de confirmar apenas para novos jogadores
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  FirebaseAnalytics.instance.logEvent(name: 'add_new_player_confirm_button_tapped');
                  // CORREÇÃO: Passa os valores dos controladores, não do player local
                  confirmNewPlayer(index, nameController.text, numberController.text);
                },
              ),
            ],
          ),
        ),
      );
    }

    // Para jogadores já existentes e salvos
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: SizedBox(
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  player.jerseyNumber, // CORREÇÃO: Acessa jerseyNumber
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  player.playerName, // CORREÇÃO: Acessa playerName
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            FirebaseAnalytics.instance.logEvent(name: 'player_popup_menu_selected', parameters: {'action': value});
            if (value == 'edit') {
              showEditDialog(index);
            } else if (value == 'delete') {
              deletePlayer(index);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text("Edit player")), // Localizado
            const PopupMenuItem(value: 'delete', child: Text("Delete player")), // Localizado
          ],
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ),
    );
  }

  /// Constrói o botão "Novo jogador".
  Widget buildNewPlayerButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: TextButton(
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(name: 'new_player_button_tapped');
            addNewPlayerRow();
          },
          child: const Text("New player", style: TextStyle(color: Colors.orange)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setPortraitOrientation();
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit team'), // Título fixo para edição, ou pode ser TeamName
        backgroundColor: const Color(0xFFFF4500),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(name: 'edit_team_players_back_button_tapped', parameters: {'team_id': widget.teamId});
            Navigator.pop(context, true); // Pop with true to indicate possible changes
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 28),
            tooltip: 'Edit team details', // Localizado
            onPressed: isLoading ? null : () async { // Desabilita se estiver carregando
              FirebaseAnalytics.instance.logEvent(name: 'edit_team_details_button_tapped', parameters: {'team_id': widget.teamId});
              // Navega para CreateTeamScreen para editar os detalhes do time (nome, abreviação, logo)
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTeamScreen(teamId: widget.teamId),
                ),
              );
              // Se a tela de edição de detalhes retornar 'true', atualiza a lista de jogadores
              if (result == true) {
                _fetchTeamDetails(); // Refresh details (name, logo)
                if (mounted) {
                  PersistentSnackbar.show(
                    context: context,
                    message: "Team details updated!",
                    backgroundColor: Colors.blueGrey.shade700,
                    textColor: Colors.white,
                    icon: Icons.refresh,
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white, size: 28),
            tooltip: 'Delete team', // Localizado
            onPressed: isLoading ? null : _deleteTeam, // Desabilita se estiver carregando
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF84442E),
              Color(0xFF3A2E2E),
            ],
            stops: [0.0, 0.7],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: _isFetchingDetails || isLoading // Mostra loading para busca de detalhes OU operações de jogador
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _hasError // Exibe erro se houver um problema crítico de carregamento
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error fetching players.', style: TextStyle(color: Colors.red, fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _fetchPlayers, child: const Text('Try again')),
            ],
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Novo: Exibe o nome do time sendo editado
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                _teamNameController.text.isNotEmpty ? _teamNameController.text : 'Fetching team name...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: players.length + 1, // +1 para o botão "Novo jogador"
                itemBuilder: (context, index) {
                  if (index < players.length) {
                    return _buildPlayerRow(players[index], index); // Usa _buildPlayerRow
                  } else {
                    return buildNewPlayerButton(); // Usa buildNewPlayerButton
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}