class NBAPlayer {
  NBAPlayer({
    required this.playerName,
    required this.team,
    required this.country,
    required this.season,
    required this.height,
    required this.weight,
    required this.college,
    required this.draftYear,
    required this.gp,
    required this.pts,
    required this.reb,
    required this.ast,
  });

  factory NBAPlayer.fromJson(Map<String, dynamic> json) => NBAPlayer(
        playerName: json['player_name'],
        team: json['team_abbreviation'],
        country: json['country'],
        season: json['season'],
        height: json['player_height'],
        weight: json['player_weight'],
        college: json['college'],
        draftYear: json['draft_year'],
        gp: json['gp'],
        pts: json['pts'],
        reb: json['reb'],
        ast: json['ast'],
      );

  final String playerName;
  final String team;
  final String country;
  final String season;
  final double height;
  final double weight;
  final String? college;
  final String draftYear;

  final double gp;
  final double pts;
  final double reb;
  final double ast;
}
