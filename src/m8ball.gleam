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

pub fn create_connection_actor(subject_to_backend) {
  let handle_connection_msg = fn(msg: ConnectionMsg, state: Int) -> actor.Next(
    ConnectionMsg,
    Int,
  ) {
    io.println("got to backend")
    io.debug(msg)
    let qwe: ConnectionMsg = msg
    case msg {
      m8ball_shared.OpenConnection(_tb) -> {
        actor.continue(state)
      }
      m8ball_shared.AckConnection(_tb) -> {
        actor.continue(state)
      }
    }
  }

  let conn_actor_spec: actor.Spec(Int, ConnectionMsg) =
    actor.Spec(
      init: fn() {
        let initial_state = 0
        let comm_sel =
          process.new_selector()
          |> process.selecting_record2(
            atom.create_from_string("open_connection"),
            fn(val) {
              let decoded =
                dynamic.tuple3(
                  atom.from_dynamic,
                  dynamic.dynamic,
                  dynamic.dynamic,
                )(val)
              case decoded {
                Ok(decoded_res) -> {
                  io.println("the val is")

                  let assert m8ball_shared.OpenConnection(client_subj): m8ball_shared.ConnectionMsg =
                    m8ball_shared.OpenConnection(dynamic.unsafe_coerce(val))

                  actor.send(
                    client_subj,
                    m8ball_shared.MainSubjectAttached(subject_to_backend),
                  )

                  m8ball_shared.OpenConnection(dynamic.unsafe_coerce(val))
                }

                Error(_) -> {
                  todo
                }
              }
            },
          )

        actor.Ready(initial_state, comm_sel)
      },
      init_timeout: 10,
      loop: handle_connection_msg,
    )
  actor.start_spec(conn_actor_spec)
}

pub fn supervisor_test() {
  let proc_name_conn = m8ball_shared.proc_name_conn

  let handle_to_backend = fn(msg: ToBackend, _state: Int) {
    io.println("got to backend")
    io.debug(msg)
    case msg {
      m8ball_shared.ToBackend(tb) -> {
        io.println("got to backend, I think that's pretty neat")
        io.debug(tb)
        actor.continue(0)
      }
    }
  }
  let assert Ok(subject_to_backend) = actor.start(0, handle_to_backend)
  let assert Ok(connection_actor_subj) =
    create_connection_actor(subject_to_backend)
  connection_actor_subj
  let assert Ok(connection_pid) =
    actor.to_erlang_start_result(Ok(connection_actor_subj))

  io.println("conn pid")
  io.debug(connection_pid)
  let assert Ok(_) =
    process.register(connection_pid, atom.create_from_string(proc_name_conn))

  let actor_init = fn(name) {
    fn() { actor.Ready(name, process.new_selector()) }
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
        // let num_children = 30_000
        let num_children = 0
        list.repeat(Nil, num_children)
        |> list.fold(from: children, with: fn(children, _) {
          add(children, returning_child_spec)
        })
      },
    ),
  )
  |> should.be_ok

  // process.receive(subject, 10)

  // register self's proc name
  let assert Ok(Nil) =
    process.self()
    |> process.register(atom.create_from_string(m8ball_shared.proc_name_sup))

  let main_subj: process.Subject(m8ball_shared.MainData) = process.new_subject()
  let selector =
    process.new_selector()
    |> process.selecting_record2(
      atom.create_from_string("open_connection"),
      fn(val) {
        let decoded =
          dynamic.tuple3(
            //atom
            atom.from_dynamic,
            // subject
            dynamic.dynamic,
            // pid
            dynamic.dynamic,
          )(val)
        use decoded_res <- result.try(decoded)

        io.println("the val is")
        io.debug(val)

        let open_connection_msg: m8ball_shared.ConnectionMsg =
          m8ball_shared.OpenConnection(dynamic.unsafe_coerce(val))

        Ok(open_connection_msg)
      },
    )
    |> process.selecting_anything(fn(val) {
      io.debug(val)
      todo
    })
    |> io.debug

  io.println("visible nodes:")
  node.visible()
  |> io.debug

  process.sleep_forever()
}
