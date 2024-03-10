import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/option.{type Option}
import gleam/result
import gleam/list
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Queries, Raw, Url}
import gleam/dynamic
import gleeunit/should
import st_response
import gleam/otp/supervisor.{add, returning, worker}
import gleam/otp/actor
import gleam/otp/task
import gleam/erlang/process

// [{kernel,
// 	[{distributed, [{m8ball,
// 		5000,
// 		['a@Josh-Desktop-V2', {'b@Josh-Desktop-V2', 'c@Josh-Desktop-V2'}]}]},
// 	{sync_nodes_mandatory, ['b@Josh-Desktop-V2', 'c@Josh-Desktop-V2']},
// 	{sync_nodes_timeout, 30000}
// 	]}].

// const config_a: supervisor.Spec(arg,return) = supervisor.Spec(arg, max_frequency: 30000, frequency_period:5000, init: fn(

pub fn supervisor_test() {
  let subject = process.new_subject()

  // Children send their name back to the test process during
  // initialisation so that we can tell they (re)started
  let child =
    worker(fn(name) {
      actor.start_spec(
        actor.Spec(
          init: fn() {
            process.send(subject, #(name, process.self()))
            actor.Ready(name, process.new_selector())
          },
          init_timeout: 10,
          loop: fn(_msg, state) { actor.continue(state) },
        ),
      )
    })

  // Each child returns the next name, which is their name + 1
  let child =
    child
    |> returning(fn(name, _subject) { name + 1 })

  supervisor.start_spec(
    supervisor.Spec(
      argument: 1,
      frequency_period: 1,
      max_frequency: 5,
      init: fn(children) {
        children
        |> add(child)
        |> add(child)
        |> add(child)
      },
    ),
  )
  |> should.be_ok

  // Assert children have started
  let assert Ok(#(1, p)) = process.receive(subject, 10)
  let assert Ok(#(2, _)) = process.receive(subject, 10)
  let assert Ok(#(3, _)) = process.receive(subject, 10)
  let assert Error(Nil) = process.receive(subject, 10)

  // Kill first child an assert they all restart
  process.kill(p)
  let assert Ok(#(1, p1)) = process.receive(subject, 10)
  let assert Ok(#(2, p2)) = process.receive(subject, 10)
  let assert Ok(#(3, _)) = process.receive(subject, 10)
  let assert Error(Nil) = process.receive(subject, 10)

  // Kill second child an assert the following children restart
  process.kill(p2)
  let assert Ok(#(2, _)) = process.receive(subject, 10)
  let assert Ok(#(3, _)) = process.receive(subject, 10)
  let assert Error(Nil) = process.receive(subject, 10)
  let assert True = process.is_alive(p1)
}
