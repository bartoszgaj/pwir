-module(station).
-compile(export_all).

%Główna pętla programu stacji.
%Zawiera listę(orddict) pociągów i listę peronów.
loop({Trains,Platforms,Requests}, GuiPID) ->
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
      loop({Trains, NewPlatforms, Requests}, GuiPID);

    %Wypisywanie wszystkich peronów na stacji (do debugowania)
    % (źródło -> shell: funkcja get_all_platforms/1)
    {Pid, MsgRef, {getPlatforms}} ->
      %Zwrocenie w odpowiedzi listy wszystkich peronów
      Pid ! {MsgRef, Platforms},
      %Ponowne wywołanie pętli głównej programu stacji
      loop({Trains,Platforms, Requests}, GuiPID);

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
      loop({NewTrains, Platforms, Requests}, GuiPID);

    %Usuwanie pociagu
    %(źródło -> train: funkcja onPlatform())
    {TrainPid, TrainName, Platform, delTrain} ->
      PPid = 0,
      NewTrains = orddict:erase(TrainName, Trains), %usuwa pociag z listy pociagow
      PlatformPid = orddict:find(Platform, Platforms), %znajdz pid peronu
      if
        PlatformPid == error -> {error, noMatch}; %nie znaleziono tego peronu
        true -> ok
      end,

      %wysylanie do peronu wiadomosci o odjeździe
      RetMsg = leave_platform(TrainName, element(2,(element(2,PlatformPid)))),
      if
        RetMsg == ok -> TrainPid ! {self(), left, Requests}
      end,

      % GUI MESSAGE TRAIN LEFT
      GuiPID ! {self(), Platform, left},

      loop({NewTrains, Platforms, Requests}, GuiPID);

    %Przypisanie pociagu z kolejki do konkretnego peronu
    {Pid, TrainPid, TrainName, TrainTime, Queue, Platform, update} ->
        io:format("Im in station:update YO"),
        PlatformPid = orddict:find(Platform, Platforms), %znajdz pid peronu
        if
            PlatformPid == error -> {error, noMatch}; %nie znaleziono
            true -> ok
        end,

        %wyslij info do peronu ze go zajmuje
        RetMsg = reserve_platform(TrainName, element(2,(element(2,PlatformPid)))),
        if
            RetMsg == ok -> Pid ! {self(), gotit} %odeslij pociagowi ok
        end,

        % Gui MESSAGE ON PLATFORM
        GuiPID ! {self(), Platform, TrainName, Requests, onPlatform},
        loop({Trains, Platforms, Queue}, GuiPID);


    %Przypisanie pociąg -> wolny peronu/czekaj
    % (źródło -> train: funkcja/pętla waiting/1)
    {TrainPid, TrainName, TrainTime, needPlatform} ->
      io:format("Pociag zglosil do stacji ze potrzebuje peron~n"),
      %Zgarniamy listę pidów wszystkich peronów do listy z naszego orddict
      PlatformsPids = orddict:fold(fun(Key,Platform,AccIn) -> [Platform|AccIn] end , [], Platforms),
      io:format("Pidy znalezionych peronow ~p~n",[PlatformsPids]),

      %wywolujemy funkcje ktora znajdzie nasz peron i od razu go zarezerwuje
      PlatformNumber = searchAndReserve(TrainPid, TrainName, PlatformsPids),
      io:format("Numer znalezionego wolnego peronu ~p~n",[PlatformNumber]),

      %jesli nie ma zadnych wolnych peronow, to wysylamy taka informacje do pociagu.
      if PlatformNumber == allOccupied ->
        NewRequests = addRequest({TrainPid, TrainName, TrainTime}, Requests),
        io:format("~p", [NewRequests]),
        TrainPid ! {self(), noPlatform, NewRequests},
        io:format("Brak wolnego peronu dla pociagu~n"),
        % GUI MESSAGE NO FREE PLATFORM
        GuiPID ! {self(), TrainName, Requests, waiting};


      %Jesli jest wolny peron, to wysylamy go do pociagu, zeby wiedzial gdzie jechac
        PlatformNumber =/= allOccupied ->
          NewRequests = Requests,
          io:format("Pociag jedzie na peron ~p~n",[PlatformNumber]),
          % GUI MESSAGE ON PLATFORM

          TrainPid ! {self(), goOn, PlatformNumber},
          GuiPID ! {self(), PlatformNumber, TrainName, Requests, onPlatform}
      end,
      %Wywolujemy główną petle programu stacji
      loop({Trains, Platforms, NewRequests}, GuiPID)

  end.

%Funkcja dodajaca pociag do kolejki oczekujacych na wolny pociag
addRequest(TrainInfo, Requests) ->
    queue:in(TrainInfo, Requests).


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

%Wyslanie wiadomosci do peronu o zajeciu go przez pociag z kolejki
reserve_platform(TrainName, PlatformPid) ->
    Ref = make_ref(),
    PlatformPid ! {self(), Ref, TrainName, reqPlatform},
    receive
        {Ref, ok} -> ok
    end.

%Wyslanie wiadomosci do peronu o odjezdzie pociagu
leave_platform(TrainName, PlatformPid) ->
  Ref = make_ref(),
  %Wywylamy do instancji peronu informacje, ze pociag odjezdza z peronu
  PlatformPid ! {self(), Ref, TrainName, leave},
  receive
    {Ref, ok} -> ok
  end.


%Funkcje udostępniona na zewnątrz do wystartowania stacji
%Spawnuje nową instancję init, która z koleji wywołuje loop/1 (główną pętlę programu stacji)
start(GuiPID) ->
  register(?MODULE, Pid=spawn(?MODULE, init, [GuiPID])),
  Pid.

start_link(GuiPID) ->
  register(?MODULE, Pid=spawn_link(?MODULE, init, [GuiPID])),
  Pid.

init(GuiPID) ->
  loop({Trains = orddict:new(), Platforms = orddict:new(), Requests = queue:new()}, GuiPID).


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
