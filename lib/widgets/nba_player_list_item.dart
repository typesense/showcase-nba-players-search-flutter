import 'package:flutter/material.dart';
import 'package:showcase_typesense_flutter/models/nba_player.dart';
import '../utils/nba_team_color.dart';

class NbaPlayerListItem extends StatelessWidget {
  const NbaPlayerListItem({
    required this.player,
    super.key,
  });

  final NBAPlayer player;

  @override
  Widget build(BuildContext context) {
    final teamColor = nbaTeamColors[player.team]?['rgb'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(
                      player.team,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Color.fromRGBO(
                        teamColor[0], teamColor[1], teamColor[2], 1),
                    padding: const EdgeInsets.only(
                        top: 10, bottom: 10, left: 2, right: 2),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${player.playerName} ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: player.country,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        player.draftYear != 'Undrafted'
                            ? 'Drafted in ${player.draftYear}'
                            : player.draftYear,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      )
                    ],
                  ),
                ],
              ),
              MutedText(
                player.season,
              )
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 25,
            runSpacing: 10,
            children: [
              MutedText(
                  '${covertCMToFeet(player.height)} (${(player.height / 100).toStringAsFixed(2)}m) / ${(player.weight * 2.2046).round()}lbs (${player.weight.round()}kg)'),
              Wrap(
                spacing: 20,
                children: [
                  PlayerStat(statName: 'GP:', stat: player.gp),
                  PlayerStat(statName: 'PTS:', stat: player.pts),
                  PlayerStat(statName: 'REB:', stat: player.reb),
                  PlayerStat(statName: 'AST:', stat: player.ast),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MutedText extends Text {
  const MutedText(
    super.data, {
    super.key,
    style,
  }) : super(
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        );
}

class PlayerStat extends StatelessWidget {
  const PlayerStat({
    required this.statName,
    required this.stat,
    super.key,
  });

  final String statName;
  final dynamic stat;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: statName,
              style: const TextStyle(
                fontSize: 10,
              ),
            ),
            TextSpan(text: ' $stat'),
          ],
        ),
      );
}

covertCMToFeet(double n) {
  var realFeet = ((n * 0.393700) / 12);
  var feet = realFeet.floor();
  var inches = ((realFeet - feet) * 12).floor();
  return '$feet\'$inches"';
}
