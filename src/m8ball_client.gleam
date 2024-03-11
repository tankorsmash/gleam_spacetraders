import gleam/io
// import gleam/erlang/os
// import gleam/string
import gleam/option.{type Option}
import gleam/result
import gleam/list
import gleam/int
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Queries, Raw, Url}
import gleam/dynamic
import gleeunit/should
import gleam/otp/supervisor.{add, returning, worker}
import gleam/otp/actor
// import gleam/otp/task
import gleam/otp/system
import gleam/erlang/process
import gleam/erlang/node
import gleam/erlang/atom.{type Atom}

@external(erlang, "net_kernel", "start")
pub fn net_kernel_start_shortname(name: List(Atom)) -> Result(Atom, Nil)

pub fn main() {
  let name_atom = atom.create_from_string("m8ball_client")
  // |> result.unwrap(panic("Failed to start net_kernel ketchup"))
  let shortnames_atom = atom.create_from_string("shortnames")
  // |> result.unwrap(funpanic("Failed to start net_kernel shortnames"))
  let my_short_name = net_kernel_start_shortname([name_atom, shortnames_atom])

  let sup_name_atom = atom.create_from_string("m8ball_sup")
  io.println("about to connect")
  node.connect(atom.create_from_string("m8ball_sup@Josh-Desktop-V2"))
  io.println("hiya")
}
