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
import m8ball_shared.{
  type SharedSubject, create_full_name, set_name_node_short_name,
}

fn connect_to_main_node() {
  let host = "Josh-Desktop-V2"

  let node_name_sup = atom.create_from_string(m8ball_shared.node_name_sup)
  let name_atom_sup =
    m8ball_shared.create_full_name(atom.to_string(node_name_sup), host)
    |> atom.create_from_string

  io.println("about to connect")
  node.connect(name_atom_sup)
}

pub fn main() {
  let _my_short_name = set_name_node_short_name("m8ball_client")

  let proc_name_connection =
    atom.create_from_string(m8ball_shared.proc_name_conn)

  io.println("about to connect")
  let assert Ok(sup_node) = connect_to_main_node()

  let int_subject = process.new_subject()
  let float_subject = process.new_subject()
  process.send(int_subject, 1)

  node.visible()
  |> io.debug

  node.send(sup_node, atom.create_from_string(m8ball_shared.proc_name_sup), 123)
  io.println("sent message to sup_node proc")

  node.send(
    sup_node,
    atom.create_from_string(m8ball_shared.proc_name_conn),
    456,
  )

  process.call(
    process.new_subject(),
    fn(subject) {
      io.println("my_message2:" <> string.inspect(subject))
      process.send(subject, 999)
    },
    1_000_000,
  )
  io.println("sent processe message to subject")
}
