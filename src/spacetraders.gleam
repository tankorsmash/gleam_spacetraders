import gleam/io
import dotenv
// import gleam_stdlib
import gleam/erlang/os
import gleam/string
import gleam/list
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

pub fn main() {
  dotenv.config()

  let client = create_client()
  // let assert Ok(contract_resp) = contract.get_my_contracts(client)
  // let contracts: List(Contract) = contract_resp.body.data
  // io.println(
  //   "Hello from spacetraders!: "
  //   <> string.join(list.map(contracts, fn(c) { c.type_ }), "-"),
  // )
  io.debug("WTF")
  let temp_client =
    falcon.new(
      base_url: Url("http://httpbin.org/"),
      headers: [],
      timeout: falcon.default_timeout,
    )
  temp_client
  |> falcon.post(
    "/status/404",
    expecting: Raw(fn(a) { Ok(a) }),
    options: [],
    body: "",
  )
  |> should.be_ok
  |> expect_status(404)
  |> io.debug
}
