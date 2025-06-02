import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:OrangeScoutFE/dto/team_dto.dart';
import 'package:OrangeScoutFE/dto/error_response_dto.dart';

/// Uma classe para encapsular o resultado das operações de time (salvar/atualizar/deletar).
class TeamOperationResult {
  final bool success;
  final String? errorMessage;
  final String? userMessage; // Mensagem para exibir ao usuário

  TeamOperationResult({required this.success, this.errorMessage, this.userMessage});
}

/// Controlador responsável por operações relacionadas a times.
class TeamController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];
  final http.Client _httpClient;

  TeamController({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  String _getApiBaseUrl() {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL não configurada.',
        StackTrace.current,
        reason: 'Erro de configuração do controlador de time',
        fatal: false,
      );
      throw Exception('URL base da API não configurada no arquivo .env.');
    }
    return _baseUrl!;
  }

  // Helper para parsear respostas de erro do backend (mesmo do AuthController)
  String _parseBackendErrorMessage(http.Response response) {
    try {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      final errorResponse = ErrorResponse.fromJson(errorData);

      if (errorResponse.message != null && errorResponse.message!.isNotEmpty) {
        return errorResponse.message!;
      }
      if (errorResponse.error != null && errorResponse.error!.isNotEmpty) {
        return errorResponse.error!;
      }
      if (errorResponse.details != null && errorResponse.details!.isNotEmpty) {
        return errorResponse.details!.values.join('\n');
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Erro ao parsear resposta de erro do backend no TeamController',
        information: [response.body, response.statusCode.toString()],
        fatal: false,
      );
      return 'Ocorreu um erro inesperado ao processar a resposta do servidor. Status: ${response.statusCode}';
    }
    return 'Ocorreu um erro desconhecido. Status: ${response.statusCode}';
  }

  // --- Endpoints de Time ---

  /// Busca todos os times do usuário autenticado.
  /// Retorna uma lista de TeamDTOs em caso de sucesso, uma lista vazia em caso de falha ou nenhum time.
  Future<List<TeamDTO>> fetchUserTeams() async { // PADRONIZAÇÃO: Nome correto do método
    FirebaseAnalytics.instance.logEvent(name: 'fetch_user_teams_attempt');
    FirebaseCrashlytics.instance.log('Tentando buscar os times do usuário.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token não encontrado para buscar times. Usuário pode estar deslogado.');
      return [];
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/teams'); // PADRONIZAÇÃO: /teams
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final List<TeamDTO> teams = jsonData.map((json) => TeamDTO.fromJson(json)).toList();
        FirebaseAnalytics.instance.logEvent(name: 'teams_fetched_successfully', parameters: {'count': teams.length});
        FirebaseCrashlytics.instance.log('Times buscados com sucesso. Quantidade: ${teams.length}');
        return teams;
      } else if (response.statusCode == 204) { // 204 No Content significa que não há times
        FirebaseAnalytics.instance.logEvent(name: 'no_teams_found_204');
        FirebaseCrashlytics.instance.log('Nenhum time encontrado (204 No Content).');
        return [];
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Falha ao buscar times do usuário: ${response.statusCode}',
          StackTrace.current,
          reason: 'Erro de resposta do backend ao buscar times do usuário',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return [];
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Erro de conexão ao buscar times',
        fatal: false,
      );
      return [];
    }
  }

  /// Salva um novo time ou atualiza um existente.
  /// Retorna TeamOperationResult indicando sucesso ou falha.
  Future<TeamOperationResult> saveOrUpdateTeam(TeamDTO teamDTO) async { // Aceita TeamDTO
    final int? teamId = teamDTO.id;
    FirebaseAnalytics.instance.logEvent(name: 'save_or_update_team_attempt', parameters: {'team_id': teamId, 'is_new': teamId == null});
    FirebaseCrashlytics.instance.log('Tentando salvar/atualizar time. ID do Time: $teamId, Nome: ${teamDTO.teamName}');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token não encontrado para salvar time. Usuário pode estar deslogado.');
      return TeamOperationResult(success: false, errorMessage: 'Erro: Token não encontrado.', userMessage: 'Usuário não autenticado.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/teams'); // PADRONIZAÇÃO: /teams (POST)
      final response = await _httpClient.post( // POST para criação/atualização
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(teamDTO.toJson()), // Usa toJson() do TeamDTO
      );

      if (response.statusCode == 201 || response.statusCode == 200) { // Backend retorna 201 CREATED ou 200 OK
        FirebaseAnalytics.instance.logEvent(name: 'team_saved_successfully', parameters: {'team_id': teamId, 'is_new': teamId == null});
        FirebaseCrashlytics.instance.log('Time salvo com sucesso. ID: $teamId');
        return TeamOperationResult(success: true, userMessage: teamId == null ? 'Time criado com sucesso!' : 'Time atualizado com sucesso!');
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Falha ao salvar time com status HTTP: ${response.statusCode}',
          StackTrace.current,
          reason: 'Erro de resposta do backend ao salvar time',
          information: [response.body, response.request?.url.toString() ?? '', jsonEncode(teamDTO.toJson())],
          fatal: false,
        );
        return TeamOperationResult(success: false, errorMessage: 'Falha ao salvar time: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Erro de conexão ao salvar time',
        fatal: false,
      );
      return TeamOperationResult(success: false, errorMessage: 'Erro de conexão: $e', userMessage: 'Não foi possível salvar o time. Verifique sua conexão.');
    }
  }

  /// Busca os detalhes de um time específico pelo seu ID.
  /// Retorna TeamDTO em caso de sucesso, null em caso de falha.
  Future<TeamDTO?> fetchTeamDetails(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_team_details_attempt', parameters: {'team_id': teamId});
    FirebaseCrashlytics.instance.log('Tentando buscar detalhes do time: $teamId.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token não encontrado para buscar detalhes do time. Usuário pode estar deslogado.');
      return null;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/teams/$teamId'); // PADRONIZAÇÃO: /teams/{id}
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final teamDTO = TeamDTO.fromJson(jsonDecode(response.body));
        FirebaseAnalytics.instance.logEvent(name: 'team_details_fetched_successfully', parameters: {'team_id': teamId});
        FirebaseCrashlytics.instance.log('Detalhes do time buscados com sucesso. ID: $teamId.');
        return teamDTO;
      } else if (response.statusCode == 404) { // Time não encontrado
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.log('ID do Time: $teamId não encontrado. Mensagem: $errorMessage');
        return null;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Falha ao buscar detalhes do time: ${response.statusCode}',
          StackTrace.current,
          reason: 'Erro de resposta do backend ao buscar detalhes do time',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return null;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Erro de conexão ao buscar detalhes do time',
        fatal: false,
      );
      return null;
    }
  }

  /// Deleta um time pelo seu ID.
  /// Retorna true em caso de sucesso, false em caso de falha.
  Future<TeamOperationResult> deleteTeam(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_team_attempt', parameters: {'team_id': teamId});
    FirebaseCrashlytics.instance.log('Tentando deletar time: $teamId.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token não encontrado para deletar time. Usuário pode estar deslogado.');
      return TeamOperationResult(success: false, errorMessage: 'Erro: Token não encontrado.', userMessage: 'Usuário não autenticado.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/teams/$teamId'); // PADRONIZAÇÃO: /teams/{id}
      final response = await _httpClient.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) { // Backend retorna 204 No Content
        FirebaseAnalytics.instance.logEvent(name: 'team_deleted_successfully', parameters: {'team_id': teamId});
        FirebaseCrashlytics.instance.log('Time $teamId deletado com sucesso.');
        return TeamOperationResult(success: true, userMessage: 'Time deletado com sucesso!');
      } else if (response.statusCode == 404) { // Não encontrado
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.log('ID do Time: $teamId não encontrado para exclusão. Mensagem: $errorMessage');
        return TeamOperationResult(success: false, errorMessage: 'Time não encontrado: ${response.statusCode}', userMessage: errorMessage);
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Falha ao deletar time $teamId com status HTTP: ${response.statusCode}',
          StackTrace.current,
          reason: 'Erro de resposta do backend ao deletar time',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return TeamOperationResult(success: false, errorMessage: 'Falha ao deletar time: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Erro de conexão ao deletar time',
        fatal: false,
      );
      return TeamOperationResult(success: false, errorMessage: 'Erro de conexão: $e', userMessage: 'Não foi possível deletar o time. Verifique sua conexão.');
    }
  }
}