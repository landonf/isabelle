(*  Title:      Pure/Concurrent/timeout.ML
    Author:     Makarius

Execution with (relative) timeout.
*)

signature TIMEOUT =
sig
  exception TIMEOUT of Time.time
  val apply: Time.time -> ('a -> 'b) -> 'a -> 'b
  val print: Time.time -> string
end;

structure Timeout: TIMEOUT =
struct

exception TIMEOUT of Time.time;

fun apply timeout f x =
  Multithreading.with_attributes Multithreading.no_interrupts (fn orig_atts =>
    let
      val self = Thread.self ();
      val start = Time.now ();

      val request =
        Event_Timer.request (Time.+ (start, timeout))
          (fn () => Standard_Thread.interrupt_unsynchronized self);
      val result =
        Exn.capture (fn () => Multithreading.with_attributes orig_atts (fn _ => f x)) ();

      val stop = Time.now ();
      val was_timeout = not (Event_Timer.cancel request);
      val test = Exn.capture Multithreading.interrupted ();
    in
      if was_timeout andalso (Exn.is_interrupt_exn result orelse Exn.is_interrupt_exn test)
      then raise TIMEOUT (Time.- (stop, start))
      else (Exn.release test; Exn.release result)
    end);

fun print t = "Timeout after " ^ Time.toString t ^ "s";

end;