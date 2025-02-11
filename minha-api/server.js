const express = require("express");
const cors = require("cors");
const app = express();

app.use(cors());
app.use(express.json());

app.get("/match/user", (req, res) => {
    res.json([
        {
            id: "1",
            teamOne: { abbreviation: "Time1", logoPath: "/path/to/logo1.png" },
            teamTwo: { abbreviation: "Time2", logoPath: "/path/to/logo2.png" },
            teamOneScore: 2,
            teamTwoScore: 3,
            matchDate: "2025-02-10"
        }
    ]);
});

app.listen(8080, () => {
    console.log("API rodando em http://localhost:8080");
});
