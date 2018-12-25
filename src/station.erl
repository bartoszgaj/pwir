-module(station).
-compile(export_all).


init() ->
  loop({Trains = orddict:new(), Platforms = orddict:new()}).

start() ->
  register(?MODULE, Pid=spawn(?MODULE, init, [])),
  Pid.

start_link() ->
  register(?MODULE, Pid=spawn_link(?MODULE, init, [])),
  Pid.

loop({Trains,Platforms}) ->
  receive
    {Pid, MsgRef, {addTrain, TrainName, GetOutTime}} ->
      TrainPid = train:start_link(TrainName, GetOutTime),
      NewTrains = orddict:store(TrainName,{TrainName,GetOutTime},Trains),
      Pid ! {MsgRef, ok},
      loop({NewTrains, Platforms});

    {Pid, MsgRef, {addPlatform, PlatformNumber}} ->
      PlatformPid = platform:start_link(PlatformNumber),
      NewPlatforms = orddict:store(PlatformNumber,{PlatformNumber}, Platforms),
      Pid ! {MsgRef, ok},
      loop({Trains, NewPlatforms});

    {Pid, MsgRef, {getPlatforms}} ->
      Pid ! {MsgRef, Platforms},
      loop({Trains,Platforms});

    {TrainPid, needPlatform} ->
      io:format("Pociag potrzebuje peron~n"),
      loop({Trains,Platforms})

      % FreePlatforms = checkFreePlatforms(Platforms),
      % if FreePlatforms =:= []
      %   TrainPid ! {self(), noPlatform};
      % if FreePlatforms =/= []
      %   TrainPid ! {self(), goOn, hd(FreePlatforms)}
      % loop({Trains,Platforms})



  end.

add_train(TrainName, GetOutTime) ->
  Ref = make_ref(),
  ?MODULE ! {self(), Ref, {addTrain, TrainName, GetOutTime}},
  receive
    {Ref, Msg} -> Msg,
    io:format("Dodano pociag ~p ~p~n", [TrainName, GetOutTime])
  after 5000 ->
    {error, timeout}
  end.

add_platform(PlatformNumber) ->
  Ref = make_ref(),
  ?MODULE ! {self(), Ref, {addPlatform, PlatformNumber}},
  receive
    {Ref, Msg} -> Msg,
    io:format("Dodano peron ~p~n", [PlatformNumber])
  after 5000 ->
    {error, timeout}
  end.

get_all_platforms() ->
  Ref = make_ref(),
  ?MODULE ! {self(), Ref, {getPlatforms}},
  receive
    {Ref, Platforms} -> Platforms,
    io:format("Dodano peron ~p~n", [Platforms])
  after 5000 ->
    {error, timeout}
  end.
