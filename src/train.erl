-module(train).
-compile(export_all).

%Pętla pociągu gdy oczekuje on na wolny peron.
waiting({Creator, Name, GetOutTime}) ->
  %Wysłanie wiadomości o przydzielenie peronu do stacji
  Creator ! {self(), Name, needPlatform},
  receive
    %Stacja zwraca, że nie ma wolnej stacji
    {Creator, noPlatform} ->
      %Ponowne wywołanie pętli waiting/1
      waiting({Creator,Name, GetOutTime});
    %Stacja zwraca peron, na który pociąg może wjechać
    {Creator, goOn, Platform} ->
      %Następuje zmiana pętli na onPlatform/1
      onPlatform({Creator, Name, GetOutTime, Platform})
  end.

%Pociąg jest już na peronie i odlicza swój GetOutTime do 0.
onPlatform({Creator, Name, GetOutTime, Platform}) when GetOutTime /= 0 ->
  io:format("Pociag ~p stoi na peronie ~p jeszcze: ~p sec~n",[Name, Platform, GetOutTime]), 
  %Po 1s wywołuje ponownie funkcję onPlatform z o jeden mniejszym czasem	
  timer:apply_after(1000, ?MODULE, onPlatform, [{Creator, Name, GetOutTime-1, Platform}]);

%koniec czasu -- pociąg odjezdza z peronu 
onPlatform({Creator, Name, GetOutTime, Platform}) when GetOutTime == 0 ->
	io:format("Pociag ~p odjechal z peronu ~p~n", [Name, Platform]).
	%TODO: pociag powinien sie usuwac z listy pociagow i platform znowu dodawany do listy dostepnych


%Funkcje udostępniane na zewnątrz. Station używa ich do stworzenia instancji pociągu
start(TrainName, GetOutTime) ->
  spawn(?MODULE, init, [self(), TrainName, GetOutTime]).

start_link(TrainName, GetOutTime) ->
  spawn_link(?MODULE, init, [self(), TrainName, GetOutTime]).

init(Creator, TrainName, GetOutTime) ->
  waiting({Creator, TrainName, GetOutTime}).


% Server to pid tego, co tworzy traina.
