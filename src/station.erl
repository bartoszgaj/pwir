-module(station).
-compile(export_all).

%Główna pętla programu stacji.
%Zawiera listę(orddict) pociągów i listę peronów.
loop({Trains,Platforms}) ->
  receive
    %Dodawania peronu
    %(źródło -> shell: funkcja add_platform/1)
    {Pid, MsgRef, {addPlatform, PlatformNumber}} ->
      %Utworzenie nowej instancji peronu
      PlatformPid = platform:start_link(PlatformNumber),
      %Dodanie peronu do listy którą przetrzymuje stacja
      NewPlatforms = orddict:store(PlatformNumber,{PlatformNumber}, Platforms),
      %Wysłanie odpowiedzi o sukcesie do procesu który wysłał wiadomość (funkcja add_platform/1)
      Pid ! {MsgRef, ok},
      %Ponowne wywołanie pętli głównej programu stacji z nową listą(orddict) peronów
      loop({Trains, NewPlatforms});

    %Wypisywanie wszystkich peronów na stacji (do debugowania)
    % (źródło -> shell: funkcja get_all_platforms/1)
    {Pid, MsgRef, {getPlatforms}} ->
      %Zwrocenie w odpowiedzi listy wszystkich peronów
      Pid ! {MsgRef, Platforms},
      %Ponowne wywołanie pętli głównej programu stacji
      loop({Trains,Platforms});

    %Dodawania pociągu
    % (źródło -> shell: funkcja add_train/2)
    {Pid, MsgRef, {addTrain, TrainName, GetOutTime}} ->
      %Utworzenie nowej instacji pociągu
      TrainPid = train:start_link(TrainName, GetOutTime),
      %Dodanie pociągu do listy pociągów którą posiada stacja
      NewTrains = orddict:store(TrainName,{TrainName,GetOutTime},Trains),
      %Wysłanie odpowiedzi o sukcesie do procesu który wysłał wiadomość (funkcja add_train/2)
      Pid ! {MsgRef, ok},
      %Ponowne wywołanie pętli głównej programu stacji z nową listą(orddict) pociągów
      loop({NewTrains, Platforms});

    %Przypisanie pociąg -> wolny peronu/czekaj
    % (źródło -> train: funkcja/pętla waiting/1)
    {TrainPid, needPlatform} ->
      io:format("Pociag potrzebuje peron~n"),
      %TODO
      loop({Trains,Platforms})

      % FreePlatforms = checkFreePlatforms(Platforms),
      % if FreePlatforms =:= []
      %   TrainPid ! {self(), noPlatform};
      % if FreePlatforms =/= []
      %   TrainPid ! {self(), goOn, hd(FreePlatforms)}
      % loop({Trains,Platforms})
  end.

%Funkcje udostępniona na zewnątrz do wystartowania stacji
%Spawnuje nową instancję init, która z koleji wywołuje loop/1 (główną pętlę programu stacji)
start() ->
  register(?MODULE, Pid=spawn(?MODULE, init, [])),
  Pid.

start_link() ->
  register(?MODULE, Pid=spawn_link(?MODULE, init, [])),
  Pid.

init() ->
  loop({Trains = orddict:new(), Platforms = orddict:new()}).


%Funkcje udostępniane zna zewnątrz. Tak naprawdę tylko przesyłają odpowiednie wiadomości do loop/1

%Dodawanie pociągu.
add_train(TrainName, GetOutTime) ->
  Ref = make_ref(),
  %Wysłanie wiadomośći do loop/1
  ?MODULE ! {self(), Ref, {addTrain, TrainName, GetOutTime}},
  receive
    {Ref, Msg} -> Msg,
    io:format("Dodano pociag ~p ~p~n", [TrainName, GetOutTime])
  after 5000 ->
    {error, timeout}
  end.

%Dodawanie peronu
add_platform(PlatformNumber) ->
  Ref = make_ref(),
  %Wysłanie wiadomośći do loop/1
  ?MODULE ! {self(), Ref, {addPlatform, PlatformNumber}},
  receive
    {Ref, Msg} -> Msg,
    io:format("Dodano peron ~p~n", [PlatformNumber])
  after 5000 ->
    {error, timeout}
  end.

%Zwraca wszystkie perony które są na stacji (do debugowania)
get_all_platforms() ->
  Ref = make_ref(),
  %Wysłanie wiadomośći do loop/1
  ?MODULE ! {self(), Ref, {getPlatforms}},
  receive
    {Ref, Platforms} -> Platforms,
    io:format("Perony: ~p~n", [Platforms])
  after 5000 ->
    {error, timeout}
  end.
