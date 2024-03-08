import gleam/io
import dotenv
import gleam/erlang/os

pub fn main() {
  dotenv.config()
  let assert Ok(token) = os.get_env("SPACETRADERS_TOKEN")
  io.println("Hello from spacetraders!: " <> token)
}
