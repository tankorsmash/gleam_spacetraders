import gleam/io
import dotenv
// import gleam_stdlib
import gleam/erlang/os
import gleam/string
import gleam/list
import gleam/bool
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should
import st_response.{type Response}
import contract.{type Contract, decode_contract_response}

fn create_client() -> Client {
  let assert Ok(token) = os.get_env("SPACETRADERS_TOKEN")
  let client =
    falcon.new(
      base_url: Url("https://api.spacetraders.io/v2/"),
      headers: [#("Authorization", "Bearer " <> token)],
      timeout: falcon.default_timeout,
    )
  client
}

pub fn expect_status(status: Int) {
  fn(resp: FalconResponse(anything)) {
    should.be_true(resp.status == status)
    resp
  }
}

fn extract_data(resp: Response(data)) -> data {
  resp.data
}

const contract_id: String = "clthywl03m46cs60cl8ezck89"

pub fn main() {
  dotenv.config()

  let client = create_client()
  client
  // |> contract.get_my_contracts
  // |> should.be_ok
  // |> expect_status(200)
  // |> core.extract_body
  // |> extract_data
  // |> fn(b) { list.at(b, 0) }
  // |> should.be_ok
  // |> fn(contract: Contract) {
  //   io.debug(
  //     "Has contract been accepted ?: "
  //     <> bool.to_string(contract.accepted),
  //   )
  //   contract
  // }
  // |> io.debug

  |> contract.accept_contract(contract_id)
  |> should.be_ok
  |> expect_status(200)
  |> core.extract_body
  |> io.debug
}
