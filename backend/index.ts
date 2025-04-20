import express from "express";
import { logging } from "./middlewares/logger";

const app = express();
const port = process.env.PORT || 8080;
const logger = console.log;

app.use(express.json());
app.use(logging(logger));

app.get("/", (req, res) => {
  res.json({ message: "Hello skribblers" });
});

app.listen(port, function () {
  logger(`Server started on: http://localhost:${port}`);
});
