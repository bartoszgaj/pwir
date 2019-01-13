-module(train).
-compile(export_all).

%Pętla pociągu gdy oczekuje on na wolny peron.
waiting({Creator, Name, GetOutTime}) ->
  %Wysłanie wiadomości o przydzielenie peronu do stacji
  Creator ! {self(), Name, GetOutTime, needPlatform},
  receive
    %Stacja zwraca, że nie ma wolnej stacji
    {Creator, noPlatform, NewRequests} -> 
      io:format("No free platform~n");
    %Stacja zwraca peron, na który pociąg może wjechać
    {Creator, goOn, Platform} ->
      %Następuje zmiana pętli na onPlatform/1
      onPlatform({Creator, Name, GetOutTime, Platform})
  end.

%Zarezerwuj i wjedz na peron --> pociag z kolejki
getPlatform(Creator, {TrainPid, TrainName, TrainTime}, Queue ,Platform) ->
    io:format("Im in getPlatform"),
    Creator ! {self(),TrainPid, TrainName, TrainTime, Queue, Platform, update},
    receive
        {Creator, gotit} ->
            io:format("GOT IT!"),
            onPlatform({Creator, TrainName, TrainTime,Platform})
    end.

%Pobieranie kolejnych pociagow z kolejki
getTrainInfo(Creator, NewRequests,Platform) ->
    {{value, Train}, _} = queue:out(NewRequests),
    {TrainPid, TrainName, TrainTime} = Train,
    Requests = queue:drop(NewRequests),
    io:format("~p, ~p", [TrainName, Requests]),
    getPlatform(Creator, {TrainPid, TrainName, TrainTime}, Requests, Platform).

%sprawdz czy kolejka do peronow jest pusta
checkEmptyReq(Creator,Requests,Platform) ->
    case queue:is_empty(Requests) of
        false -> getTrainInfo(Creator,Requests,Platform);
        true -> io:format("Request queue empty")
    end.

%Pociąg jest już na peronie i odlicza swój GetOutTime do 0.
onPlatform({Creator, Name, GetOutTime, Platform}) when GetOutTime /= 0 ->
  %io:format("Pociag ~p stoi na peronie ~p jeszcze: ~p sec~n",[Name, Platform, GetOutTime]), 
  %Po 1s wywołuje ponownie funkcję onPlatform z o jeden mniejszym czasem	
  timer:apply_after(1000, ?MODULE, onPlatform, [{Creator, Name, GetOutTime-1, Platform}]);

%koniec czasu -- pociąg odjezdza z peronu, peron znowu wolny
onPlatform({Creator, Name, GetOutTime, Platform}) when GetOutTime == 0 ->
	io:format("Pociag ~p odjezdza z peronu ~p~n", [Name, Platform]),
  Creator ! {self(), Name, Platform, delTrain},
  receive
    {Creator, left, Requests} -> checkEmptyReq(Creator,Requests,Platform)
  end.

%Funkcje udostępniane na zewnątrz. Station używa ich do stworzenia instancji pociągu
start(TrainName, GetOutTime) ->
  spawn(?MODULE, init, [self(), TrainName, GetOutTime]).

start_link(TrainName, GetOutTime) ->
  spawn_link(?MODULE, init, [self(), TrainName, GetOutTime]).

init(Creator, TrainName, GetOutTime) ->
  waiting({Creator, TrainName, GetOutTime}).


% Server to pid tego, co tworzy traina.
