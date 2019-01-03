-module(station_server).
-compile(export_all).
%-include_lib("wx/include/wx.hrl").
-import(station, [start/0]).
-import(station_generator, [generate_train/0, generate_platforms/0]).

%idz kursorem do x,y
print({gotoxy, X, Y}) ->
    io:format("\e[~p;~pH", [Y,X]);
%na pozycji x, y wydrukuj msg
print({printxy, X, Y, Msg}) ->
    io:format("\e[~p;~pH~p", [Y,X,Msg]);
%wyczysc ekran
print({clear}) ->
    io:format("\e[2J", []).

printxy({X,Y,Msg}) ->
   io:format("\e[~p;~pH~p~n",[Y,X,Msg]).  

%init the app
init() ->
    print({clear}),
    print({printxy, 10, 3, '+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+'}),
    print({printxy, 10, 4, '|S|t|a|c|j|a| |k|o|l|e|j|o|w|a|'}),
    print({printxy, 10, 5, '+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+'}),
    print({printxy, 6, 8, "station_server:auto(): TRYB AUTOMATYCZNY"}),
    print({printxy, 6, 10, "station_server:user(): TRYB UZYTKOWNIKA"}),
    print({gotoxy, 10, 13}),
    io:format("\n",[]).

loop() ->
    station_generator:generate_train(),
    timer:apply_after(3000, ?MODULE, loop, []).  
%tu sie powinno odpalac tez gui
%tryb automatyczny: generuje losowa ilosc peronow z przedzialu 0-6
%oraz co sekunde generuje pociag o losowej 4-literowej nazwie i losowym czasie
%odjazdu z przedzialu 0-15s
auto() ->
    station:start(),
    PlNo = station_generator:generate_platforms(),
    loop().

%TODO
user() ->
    {ok, [X]} = io:fread("Number of platforms: ","~d"),
    X.
    

