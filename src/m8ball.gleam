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
import gleam/erlang/process.{type Subject}
import gleam/erlang/node
import gleam/erlang/atom.{type Atom}
import m8ball_shared.{
  type ClientData, type ConnectionMsg, type MainData, type SharedData,
  type ToBackend, type ToFrontend, create_full_name, set_name_node_short_name,
}

// [{kernel,
// 	[{distributed, [{m8ball,
// 		5000,
// 		['a@Josh-Desktop-V2', {'b@Josh-Desktop-V2', 'c@Josh-Desktop-V2'}]}]},
// 	{sync_nodes_mandatory, ['b@Josh-Desktop-V2', 'c@Josh-Desktop-V2']},
// 	{sync_nodes_timeout, 30000}
// 	]}].

// const config_a: supervisor.Spec(arg,return) = supervisor.Spec(arg, max_frequency: 30000, frequency_period:5000, init: fn(

@external(erlang, "net_kernel", "start")
pub fn net_kernel_start_shortname(name: List(Atom)) -> Result(Atom, Nil)

//   options: Atom,

type MySubject =
  process.Subject(MyMsg)

type MyMsg =
  #(String, process.Pid)

pub fn supervisor_test() {
  let subject: MySubject = process.new_subject()

  let short_name = set_name_node_short_name(m8ball_shared.node_name_sup)
  let proc_name_conn = m8ball_shared.proc_name_conn

  let handle_to_backend = fn(msg: ToBackend, state) {
    io.println("got to backend")
    io.debug(msg)
    case msg {
      m8ball_shared.ToBackend(tb) -> {
        io.println("got to backend")
        io.debug(tb)
        actor.continue(0)
      }
    }
  }

  let assert Ok(connection_actor_subj) =
    actor.start_spec(actor.Spec(
      init: fn() {
        let comm_subj: Subject(ToBackend) = process.new_subject()
        actor.Ready(0, process.new_selector())
      },
      // // |> process.selecting(subj, fn(val) { val + 100 })
      // |> process.selecting(comm_subj, handle_to_backend),
      init_timeout: 10,
      loop: handle_to_backend,
    ))

  // loop: fn(msg, state) {
  //   // actor.start(0, fn(msg, state) {
  //   // io.debug("got message on connection_actor" <> int.to_string(msg))
  //   io.debug("got message on connection_actor" <> string.inspect(msg))
  //   actor.continue(state)
  // },
  // let qwe: m8ball_shared.ToBackend = connection_actor_subj
  let assert Ok(connection_pid) =
    actor.to_erlang_start_result(Ok(connection_actor_subj))

  io.println("conn pid")
  io.debug(connection_pid)
  let assert Ok(_) =
    process.register(connection_pid, atom.create_from_string(proc_name_conn))

  // system.get_state(connection_actor_sub)

  let actor_init = fn(name) {
    fn() {
      // let msg = #(name, process.self())
      // process.send(subject, msg)
      //   io.println("Child started: " <> name)
      actor.Ready(name, process.new_selector())
    }
  }

  let actor_loop = fn(_msg, state) { actor.continue(state) }

  let build_actor_spec = fn(name) {
    actor.Spec(init: actor_init(name), init_timeout: 10, loop: actor_loop)
  }

  // Children send their name back to the test process during
  // initialisation so that we can tell they (re)started
  let default_child_spec =
    worker(fn(name) { actor.start_spec(build_actor_spec(name)) })

  // Each child returns the next name, which is their name + 1
  let returning_child_spec: supervisor.ChildSpec(a, String, String) =
    returning(default_child_spec, fn(name: String, _subject) -> String {
      int.parse(name)
      |> result.unwrap(1000)
      |> fn(a) { a + 1 }
      |> int.to_string
    })

  supervisor.start_spec(
    supervisor.Spec(
      argument: "1",
      frequency_period: 1,
      max_frequency: 5,
      init: fn(children) {
        // let num_children = 30_000b
        let num_children = 0
        list.repeat(Nil, num_children)
        |> list.fold(from: children, with: fn(children, _) {
          add(children, returning_child_spec)
        })
      },
    ),
  )
  |> should.be_ok

  process.receive(subject, 10)
  // Assert children have started
  // let assert Ok(#("1", p)) = process.receive(subject, 10)
  //   let assert Ok(#("2", _)) = process.receive(subject, 10)
  //   let assert Ok(#("3", _)) = process.receive(subject, 10)
  //   let assert Error(Nil) = process.receive(subject, 10)

  // register self's proc name
  let assert Ok(Nil) =
    process.self()
    |> process.register(atom.create_from_string(m8ball_shared.proc_name_sup))

  let main_subj: process.Subject(m8ball_shared.MainData) = process.new_subject()
  let selector =
    process.new_selector()
    // |> process.selecting(main_subj, fn(a) {
    //   io.println("got main data")
    //   io.debug(a)
    //   Ok(a)
    // })
    |> process.selecting_anything(fn(val) {
      io.println("trying2")
      io.debug(val)
      io.println("after2")

      let decoded = dynamic.tuple2(atom.from_dynamic, dynamic.dynamic)(val)
      use decoded_res <- result.try(decoded)

      let str_atom = atom.to_string(decoded_res.0)
      case #(str_atom, decoded_res.1) {
        #("shared_data", connection_msg) -> {
          Ok(m8ball_shared.SharedData(dynamic.unsafe_coerce(connection_msg)))
        }
        otherwise -> {
          Error([
            dynamic.DecodeError("'shared_data'", str_atom, ["top, i guess"]),
          ])
        }
      }
    })
    |> io.debug

  io.println("visible nodes:")
  node.visible()
  |> io.debug

  // process.sleep_forever()

  io.println("waiting")
  let assert Ok(m8ball_shared.SharedData(connection_msg)) =
    process.select_forever(selector)
    |> io.debug()

  io.println("specifically waiting to send back")
  case connection_msg {
    m8ball_shared.OpenConnection(client_subj) -> {
      process.send(
        client_subj,
        m8ball_shared.MainSubject(connection_actor_subj),
      )
    }
    m8ball_shared.AckConnection(_) -> {
      io.println("shouldn't get ack, idk how to throw")
      // process.send(client_subj, m8ball_shared.MainSubject(main_subj))
    }
  }

  // process.send(main_subj, "star")

  io.println("waiting 2nd")
  process.select_forever(selector)
  |> io.debug()

  io.println("waiting 3rd")
  process.select_forever(selector)
  |> io.debug()
}
