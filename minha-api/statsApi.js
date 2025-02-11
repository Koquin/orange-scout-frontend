const express = require("express");
const cors = require("cors");
const app = express();

app.use(cors());
app.use(express.json());

app.get("/stats/:matchId", (req, res) => {
    const { matchId } = req.params;
    
    // Simulação de dados de estatísticas para uma partida específica
    const stats = [
        {
            playerId: "p1",
            playerName: "Jogador 1",
            team: "Time1",
            threePoints: 2,
            twoPoints: 4,
            onePoint: 3,
            missThreePoints: 1,
            missTwoPoints: 2,
            missOnePoint: 0,
            offensiveRebound: 3,
            defensiveRebound: 5,
            steal: 2,
            assist: 4,
            block: 1,
            turnover: 2,
            foul: 3
        },
        {
            playerId: "p2",
            playerName: "Jogador 2",
            team: "Time1",
            threePoints: 1,
            twoPoints: 5,
            onePoint: 2,
            missThreePoints: 2,
            missTwoPoints: 1,
            missOnePoint: 1,
            offensiveRebound: 2,
            defensiveRebound: 4,
            steal: 1,
            assist: 3,
            block: 0,
            turnover: 1,
            foul: 2
        },
        {
            playerId: "p3",
            playerName: "Jogador 3",
            team: "Time2",
            threePoints: 3,
            twoPoints: 2,
            onePoint: 1,
            missThreePoints: 0,
            missTwoPoints: 1,
            missOnePoint: 2,
            offensiveRebound: 4,
            defensiveRebound: 6,
            steal: 3,
            assist: 5,
            block: 2,
            turnover: 0,
            foul: 1
        }
    ];

    res.json({ matchId, stats });
});

app.listen(8081, () => {
    console.log("API de Estatísticas rodando em http://localhost:8081");
});
