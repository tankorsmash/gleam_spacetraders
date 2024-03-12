import gleam/io
// import gleam/erlang/os
import gleam/string
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

// pub type SharedSubject =
//   process.Subject(String)

pub type SharedData {
  SharedData(Int)
}

pub const node_name_sup = "m8ball_sup"

pub const proc_name_conn = "m8ball_connection"

pub const proc_name_sup = "m8ball_supervisor"

pub fn create_full_name(name: String, host: String) -> String {
  name <> "@" <> host
}

pub fn set_name_node_short_name(node_name: String) -> Result(Atom, Nil) {
  let name_atom = atom.create_from_string(node_name)
  let shortnames_atom = atom.create_from_string("shortnames")
  let my_short_name = net_kernel_start_shortname([name_atom, shortnames_atom])
  my_short_name
}

@external(erlang, "net_kernel", "start")
pub fn net_kernel_start_shortname(name: List(Atom)) -> Result(Atom, Nil)
