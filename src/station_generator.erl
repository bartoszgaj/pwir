-module(station_generator).
-export([generate_train/0, generate_platforms/0]).
-import(station, [start/0, add_platform/1, add_train/2]).

for(0,_) -> 
   []; 
   
for(N,Term) when N > 0 -> 
   station:add_platform(N), 
   [Term|for(N-1,Term)]. 

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
    
