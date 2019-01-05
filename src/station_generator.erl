-module(station_generator).
-export([generate_train/0, generate_platforms/0, make_platforms/1, start_link/0, start_link_user/0, init_user/0, loop_user/0, start1/0, init/0, loop/0]).
-import(station, [start/0, add_platform/1, add_train/2]).


for(0,_) ->
   [];

for(N,Term) when N > 0 ->
   station:add_platform(N),
   [Term|for(N-1,Term)].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% AUTO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%generuje losowa ilosc peronow 0-6
platformNo() ->
    crypto:rand_uniform(1,6).

%wybiera i dodaje losowa ilosc peronow z przedzialu 0-6
generate_platforms() ->
    Num = platformNo(),
    for(Num, 1),
    Num.

%generuje losowy czas postoju pociagu w przedziale 0-15s
trainTime() ->
    crypto:rand_uniform(1,15).

randchar(N) ->
   randchar(N, []).

randchar(0, Acc) ->
   Acc;
randchar(N, Acc) ->
   randchar(N - 1, [crypto:rand_uniform(1,26) + 96 | Acc]).

%generuje losowa nazwe pociagu o dlugosci 4 liter
trainName() ->
    randchar(4).

%generuje pociag o losowej nazwie i czasie
generate_train() ->
    station:add_train(trainName(), trainTime()).

start_link() ->
  io:format("TESTSpawn"),
  spawn_link(?MODULE, init, []).

init() ->
  io:format("TEST1"),
  loop().

loop() ->
    io:format("TEST2"),
    generate_train(),
    timer:apply_after(3000, ?MODULE, loop, []).
%%%%%%%%%%%%%%%%%%%%%%%%%%%% USER INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%tworzy pociag o podanej przez usera nazwie i czasie odjazdu
make_train(Name, GetOutTime) ->
    station:add_train(Name, GetOutTime).
%tworzy ilosc peronow podana przez uzytkownika
make_platforms(PlNo) ->
    for(PlNo, 1),
    PlNo.
 
start1() ->
  io:format("TESTStart"),
  spawn(?MODULE, init, []).

start_link_user() ->
   io:format("Spawn for user input"),
   spawn_link(?MODULE, init_user, []).

init_user() ->
  io:format("generator: Init user"),
  loop_user().

loop_user() ->
    {ok, [Name]} = io:fread("Train name: ","~s"),
    {ok, [GetOutTime]} = io:fread("Get out time: ", "~d"),
    make_train(Name, GetOutTime),
    timer:apply_after(2000, ?MODULE, loop_user, []).
