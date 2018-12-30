-module(platform).
-compile(export_all).


%Główna pętla programu, która trzyma referencję do stacji, numer peronu, pociągi które znajdują się na peronie
loop({Station, Number, Trains}) ->
  receive
    %(źródło -> stacja: wysłane z pętli loop po zgłoszeniu potrzeby peronu od instancji pociągu)
    {Pid, MsgRef, TrainName, platformNeeded} ->
      %Jeśli lista pociągów na peronie jest obecnie pusta
      if Trains =:= [] ->
          % Do stacji zwracana jest informacja OK.
           Pid ! {MsgRef, ok},
           %Pociąg jest dodawany do listy pociągów na peronie(peron staje się zajęty). Pętla peronu zostaje ponownie wywołana
           loop({Station, Number,[TrainName|Trains]});
         %Jeśli lista pociągów na peronie nie jest pusta(na peronie jest pociąg)
         Trains =/= [] ->
           %Zwracana jest informacja o zajęciu peronu.
           Pid ! {MsgRef, occupied},
           %Ponownie wywoływana jest pętla główna peronu.
           loop({Station, Number, Trains})
      end;
    %(źródło -> stacja: wysłane z pętli loop po zgłoszeniu odjazdu z peronu od instancji pociągu)
    {Pid, MsgRef, TrainName, leave} ->
      %Wysłanie odpowiedzi OK
      Pid ! {MsgRef, ok},
      %Peron ponownie staje się pusty.
      loop({Station, Number, []})
  end.


%Funkcje udostępniane na zewnątrz. Station używa ich do stworzenia instancji peronu

start(PlatformNumber) ->
  spawn(?MODULE, init, [self(), PlatformNumber]).

start_link(PlatformNumber) ->
  spawn_link(?MODULE, init, [self(), PlatformNumber]).

init(Station, Number) ->
  loop({Station, Number, []}).
