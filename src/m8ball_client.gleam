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
import m8ball_shared.{type SharedSubject, name_node_short_name}

pub fn main() {
  let my_short_name = name_node_short_name("m8ball_client")

  let sup_name_atom = atom.create_from_string("m8ball_sup")
  io.println("about to connect")
  let assert Ok(sup_node) =
    node.connect(atom.create_from_string("m8ball_sup@Josh-Desktop-V2"))

  let int_subject = process.new_subject()
  let float_subject = process.new_subject()
  process.send(int_subject, 1)

  node.visible()
  |> io.debug

  node.send(sup_node, atom.create_from_string("m8ball_sup_proc"), 123)
  io.println("sent message to sup_node proc")

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