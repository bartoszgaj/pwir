-module(platform).
-compile(export_all).

loop({Station, Number, Trains}) ->
  receive
    {Pid, MsgRef, TrainName, platformNeeded} ->
      if Trains =:= [] ->
           Pid ! {MsgRef, ok},
           loop({Station, Number,[TrainName|Trains]});
         Trains =/= [] ->
           Pid ! {MsgRef, occupied},
           loop({Station, Number, Trains})
      end;
    {Pid, MsgRef, leave} ->
      Pid ! {MsgRef, ok},
      loop({Station, Number, []})
  end.



start(PlatformNumber) ->
  spawn(?MODULE, init, [self(), PlatformNumber]).

start_link(PlatformNumber) ->
  spawn_link(?MODULE, init, [self(), PlatformNumber]).

init(Station, Number) ->
  loop({Station, Number, []}).
