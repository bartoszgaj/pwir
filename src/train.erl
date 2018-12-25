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
onPlatform({Creator, Name, GetOutTime, Platform}) ->
  io:format("Pociag ~p ~p wjechal na peron ~p~n",[Name, GetOutTime, Platform]).
%TODO


%Funkcje udostępniane na zewnątrz. Station używa ich do stworzenia instancji pociągu
start(TrainName, GetOutTime) ->
  spawn(?MODULE, init, [self(), TrainName, GetOutTime]).

start_link(TrainName, GetOutTime) ->
  spawn_link(?MODULE, init, [self(), TrainName, GetOutTime]).

init(Creator, TrainName, GetOutTime) ->
  waiting({Creator, TrainName, GetOutTime}).


% Server to pid tego, co tworzy traina.
