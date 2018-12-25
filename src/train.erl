-module(train).
-compile(export_all).


waiting({Creator, Name, GetOutTime}) ->
  Creator ! {self(), needPlatform},
  receive
    {Creator, noPlatform} ->
      waiting({Creator,Name, GetOutTime});
    {Creator, goOn, Platform} ->
      onPlatform({Creator, Name, GetOutTime, Platform})
  end.

onPlatform({Creator, Name, GetOutTime, Platform}) ->
  null.



start(TrainName, GetOutTime) ->
  spawn(?MODULE, init, [self(), TrainName, GetOutTime]).

start_link(TrainName, GetOutTime) ->
  spawn_link(?MODULE, init, [self(), TrainName, GetOutTime]).

init(Creator, TrainName, GetOutTime) ->
  waiting({Creator, TrainName, GetOutTime}).


% Server to pid tego, co tworzy traina.
