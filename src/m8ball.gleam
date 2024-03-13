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

  // let handle_to_backend = fn(msg: ToBackend, state) {
  //   io.println("got to backend")
  //   io.debug(msg)
  //   case msg {
  //     m8ball_shared.ToBackend(tb) -> {
  //       io.println("got to backend")
  //       io.debug(tb)
  //       actor.continue(0)
  //     }
  //   }
  // }
  let handle_connection_msg = fn(msg: ConnectionMsg, state: Int) -> actor.Next(
    ConnectionMsg,
    Int,
  ) {
    io.println("got to backend")
    io.debug(msg)
    let qwe: ConnectionMsg = msg
    case msg {
      m8ball_shared.OpenConnection(_tb) -> {
        // io.println("got open connection")
        // io.debug(tb)
        //   m8ball_shared.OpenConnection(client_subj) -> {
        //     process.send(
        //       client_subj,
        //       m8ball_shared.MainSubject(connection_actor_subj),
        //     )
        //   }
        actor.continue(state)
      }
    }
  }

  // _ -> actor.continue("ASD")
  let conn_actor_spec: actor.Spec(Int, ConnectionMsg) =
    actor.Spec(
      init: fn() {
        let initial_state = 0
        let comm_subj: Subject(ConnectionMsg) = process.new_subject()
        let comm_sel =
          process.new_selector()
          |> process.selecting_record2(
            atom.create_from_string("open_connection"),
            fn(val) {
              let decoded =
                // atom sub pid
                dynamic.tuple3(
                  atom.from_dynamic,
                  dynamic.dynamic,
                  dynamic.dynamic,
                )(val)
              case decoded {
                Ok(decoded_res) -> {
                  io.println("the val is")
                  // io.debug(val)

                  let open_connection_msg: m8ball_shared.ConnectionMsg =
                    m8ball_shared.OpenConnection(dynamic.unsafe_coerce(val))

                  // Ok(open_connection_msg)
                  // actor.continue(0)
                  // Ok(val)
                  // val
                  open_connection_msg
                }

                Error(_) -> {
                  todo
                }
              }
            },
          )

        actor.Ready(initial_state, comm_sel)
      },
      // // |> process.selecting(subj, fn(val) { val + 100 })
      // |> process.selecting(comm_subj, handle_to_backend),
      init_timeout: 10,
      loop: handle_connection_msg,
    )
  let assert Ok(connection_actor_subj) = actor.start_spec(conn_actor_spec)

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
      Ok(io.debug(val))
      todo
    })
    |> io.debug

  io.println("visible nodes:")
  node.visible()
  |> io.debug

  process.sleep_forever()

  // io.println("waiting")
  // // let assert Ok(m8ball_shared.SharedData(connection_msg)) =
  // let assert Ok(connection_msg) =
  //   process.select_forever(selector)
  //   |> io.debug()

  // io.println("specifically waiting to send back")
  // case connection_msg {
  //   m8ball_shared.OpenConnection(client_subj) -> {
  //     process.send(
  //       client_subj,
  //       m8ball_shared.MainSubject(connection_actor_subj),
  //     )
  //   }
  // }

  // m8ball_shared.AckConnection(_) -> {
  //   io.println("shouldn't get ack, idk how to throw")
  //   // process.send(client_subj, m8ball_shared.MainSubject(main_subj))
  // }
  // process.send(main_subj, "star")

  io.println("waiting 2nd")
  process.select_forever(selector)
  |> io.debug()

  io.println("waiting 3rd")
  process.select_forever(selector)
  |> io.debug()
}
