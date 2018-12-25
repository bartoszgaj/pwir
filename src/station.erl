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
      NewPlatforms = orddict:store(PlatformNumber,{PlatformNumber, PlatformPid}, Platforms),
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
    {TrainPid, TrainName, needPlatform} ->
      io:format("Pociag zglosil do stacji ze potrzebuje peron~n"),
      %Zgarniamy listę pidów wszystkich peronów do listy z naszego orddict
      PlatformsPids = orddict:fold(fun(Key,Platform,AccIn) -> [Platform|AccIn] end , [], Platforms),
      io:format("Pidy znalezionych peronow ~p~n",[PlatformsPids]),

      %wywolujemy funkcje ktora znajdzie nasz peron i od razu go zarezerwuje
      PlatformNumber = searchAndReserve(TrainPid, TrainName, PlatformsPids),
      io:format("Numer znalezionego wolnego peronu ~p~n",[PlatformNumber]),

      %jesli nie ma zadnych wolnych peronow, to wysylamy taka informacje do pociagu.
      if PlatformNumber == allOccupied ->
        TrainPid ! {self(), noPlatform},
        io:format("Brak wolnego peronu dla pociagu~n");

      %Jesli jest wolny peron, to wysylamy go do pociagu, zeby wiedzial gdzie jechac
        PlatformNumber =/= allOccupied ->
          io:format("Pociag jedzie na peron ~p~n",[PlatformNumber]),
          TrainPid ! {self(), goOn, PlatformNumber}
      end,
      %Wywolujemy główną petle programu stacji
      loop({Trains, Platforms})




  end.

%Funkcja wyszukujaca pusty peron

%Jesli lista peronow jest pusta, to zwracamy informacje ze wszystkie sa zajete
searchAndReserve(TrainPid, TrainName, []) ->
  allOccupied;

searchAndReserve(TrainPid, TrainName, [{PlatformNumber, PlatformPid}|Rest]) ->
  Ref = make_ref(),
  %Wywylamy do instancji peronu informacje, ze potrzebny jest peron, zeby sprawdzic czy jest wolny
  PlatformPid ! {self(), Ref, TrainName, platformNeeded},
  receive
    %jesli jest wolny, to zwracamy jego numer (jest on juz zajety dla naszego pociagu)
    {Ref, ok} -> PlatformNumber;

    %Jesli jest zajety, to wywolujemy funkcje searchAndReserve dla pozostalych w liscie
    {MsgRef, occupied} ->
      searchAndReserve(TrainPid, TrainName, Rest)
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
