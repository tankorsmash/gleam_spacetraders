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
import m8ball_shared.{type SharedData, set_name_node_short_name}

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

  let assert Ok(connection_actor_subj) =
    actor.start_spec(actor.Spec(
      init: fn() {
        // let msg = #(name, process.self())
        // process.send(subject, msg)
        //   io.println("Child started: " <> name)
        let subj = process.new_subject()
        actor.Ready(
          0,
          process.new_selector()
            |> process.selecting(subj, fn(val) { val + 100 }),
        )
      },
      init_timeout: 10,
      loop: fn(msg, state) {
        // actor.start(0, fn(msg, state) {
        // io.debug("got message on connection_actor" <> int.to_string(msg))
        io.debug("got message on connection_actor" <> string.inspect(msg))

        actor.continue(state)
      },
    ))
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

  // io.println("sending subject")
  // process.send(process.new_subject(), "hello")

  // let s = process.new_subject()
  //   let selector =
  //     process.new_selector()
  //     |> process.selecting_anything(_, for: s, mapping: fn(_) {
  //       io.println("got message")
  //     })
  //     |> process.select_forever
  // let selector: Selector(SharedData) =
  let selector =
    process.new_selector()
    // |> process.selecting_anything(dynamic.tuple2(dynamic.string, dynamic.string))
    // |> process.selecting(s, dynamic.int)
    // |> process.selecting(s, dynamic.int)
    // |> process.selecting_record2(m8ball_shared.SharedData, dynamic.int)
    // |> process.selecting_anything(dynamic.int)
    // |> process.selecting_anything(fn(a) { a })
    // |> process.selecting(process.new_subject(), fn(a) { io.debug(a) })
    // |> process.selecting_anything(fn(a) { io.debug(a) })
    // |> process.selecting_anything(dynamic.decode1(
    //   m8ball_shared.SharedData,
    //   dynamic.int,
    // ))
    // |> process.selecting_anything(fn(a) {
    //   io.println("trying")
    //   // let assert Ok(qwe) = atom.from_dynamic(a)
    //   io.debug(a)
    //   io.println("after")
    //   dynamic.decode1(m8ball_shared.SharedData, dynamic.int)(a)
    // })
    |> process.selecting_anything(fn(val) {
      io.println("trying2")
      // let assert Ok(qwe) = atom.from_dynamic(a)
      io.debug(val)
      io.println("after2")
      dynamic.decode1(
        fn(atom_int: #(Atom, Int)) {
          let atom = atom_int.0
          io.debug(atom == atom.create_from_string("SharedData"))
          let val = atom_int.1
          io.debug(atom)
          io.debug(atom.to_string(atom))
          m8ball_shared.SharedData(val)
        },
        dynamic.tuple2(atom.from_dynamic, dynamic.int),
      )(val)
    })
    // use d <- process.selecting_anything(dynamic.int)
    // d
    // |> process.map_selector(m8ball_shared.SharedData)
    // }
    // use val: Int <- dynamic.int
    // m8ball_shared.SharedData(val)
    // })
    // |> process.selecting(process.new_subject(), int.to_string)
    |> io.debug

  io.println("visible nodes:")
  node.visible()
  |> io.debug

  // process.sleep_forever()

  io.println("waiting")
  process.select_forever(selector)
  |> io.debug()

  io.println("waiting 2nd")
  process.select_forever(selector)
  |> io.debug()

  io.println("waiting 3rd")
  process.select_forever(selector)
  |> io.debug()
}
