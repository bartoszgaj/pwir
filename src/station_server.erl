-module(station_server).
-compile(export_all).
-include_lib("wx/include/wx.hrl").
%-include_lib("wx/include/wx.hrl").
-import(station, [start/1]).
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
  init1().


init1() ->
    print({clear}),
    print({printxy, 10, 3, '+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+'}),
    print({printxy, 10, 4, '|S|t|a|c|j|a| |k|o|l|e|j|o|w|a|'}),
    print({printxy, 10, 5, '+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+'}),
    print({printxy, 6, 8, "station_server:auto(): TRYB AUTOMATYCZNY"}),
    print({printxy, 6, 10, "station_server:user(): TRYB UZYTKOWNIKA"}),
    print({gotoxy, 10, 13}),
    io:format("\n",[]),
    Server = wx:new(),
    Wx = make_window1(Server),
    loop1(Wx).

  make_window1(Server) ->
      Frame = wxFrame:new(Server, -1, "Train station simulation", [{size,{1000,500}}]),
      Auto_Button = wxButton:new(Frame, 1, [{label, "Auto simulation"}, {pos, {300,70}}]),
      Manual_Button = wxButton:new(Frame, 2, [{label, "Manual simulation"}, {pos, {700,70}}]),

      wxFrame:createStatusBar(Frame),
      wxFrame:show(Frame),

      wxFrame:connect(Frame, close_window),
      wxButton:connect(Auto_Button, command_button_clicked),
      wxButton:connect(Manual_Button, command_button_clicked),
      % {Server, Frame, End_Button, Time_Text, ClientsR, ClientsS}.
      {Server, Frame, Auto_Button, Manual_Button}.

    loop1(Wx) ->
      {Server, Frame, Auto_Button, Manual_Button} = Wx,
      receive
        #wx{event=#wxClose{}} ->
            io:format("--closing window ~p-- ~n",[self()]),
            wxWindow:destroy(Frame),
            ok;
        #wx{id = 1, event=#wxCommand{type = command_button_clicked}} ->
            wxWindow:destroy(Auto_Button),
            wxWindow:destroy(Manual_Button),
            init2(Server,Frame);

        #wx{id = 2, event=#wxCommand{type = command_button_clicked}} ->
            wxWindow:destroy(Auto_Button),
            wxWindow:destroy(Manual_Button),            
            user(Server, Frame)

      end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% AUTO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init2(Server,Frame) ->
  station:start(self()),
  PlNo = station_generator:generate_platforms(),
  Wx = make_window2(Server, Frame, PlNo),
  GeneratorPid = station_generator:start_link(),
  loop2(Wx).

make_window2(Server , Frame, PlNo) ->
  End_Button = wxButton:new(Frame, 3, [{label, "End simulation"}, {pos, {500,50}}]),
  Platform6 = [{6, wxStaticText:new(Frame, 0, "Peron 6", [{pos, {200, 350}}])}],
  Platform5 = [{5, wxStaticText:new(Frame, 0, "Peron 5", [{pos, {200, 300}}])}|Platform6],
  Platform4 = [{4, wxStaticText:new(Frame, 0, "Peron 4", [{pos, {200, 250}}])}|Platform5],
  Platform3 = [{3, wxStaticText:new(Frame, 0, "Peron 3", [{pos, {200, 200}}])}|Platform4],
  Platform2 = [{2, wxStaticText:new(Frame, 0, "Peron 2", [{pos, {200, 150}}])}|Platform3],
  Platform1 = [{1, wxStaticText:new(Frame, 0, "Peron 1", [{pos, {200, 100}}])}|Platform2],
  PlatformsView = Platform1,

  RequestsView = wxStaticText:new(Frame, 0, "Oczekujące", [{pos, {500, 350}}]),

  wxFrame:show(Frame),

  % wxFrame:connect(Frame, close_window),
  % wxButton:connect(End_Button, command_button_clicked),
  io:format("TEST"),
  % {Server, Frame, End_Button, Time_Text, ClientsR, ClientsS}.
  {Server, Frame, End_Button, PlatformsView, RequestsView}.

loop2(Wx) ->
  {_, Frame, End_Button, PlatformsView, RequestsView} = Wx,
  receive
    #wx{event=#wxClose{}} ->
        io:format("--closing window ~p-- ~n",[self()]),
        wxWindow:destroy(Frame),
        ok,
        loop2(Wx);

    #wx{id = 3, event=#wxCommand{type = command_button_clicked}} ->
        % TODO STOP SIMULATION
        
        loop2(Wx);


    {Station, Platform, TrainName, Request, onPlatform} ->
      {Key, Result} = lists:keyfind(Platform, 1, PlatformsView),
      PlatformText = string:concat(string:concat("Peron ", integer_to_list(Platform)),"\n"),
      wxStaticText:setLabel(Result, string:concat(PlatformText, TrainName)),
      WaitingText = "Oczekujace \n",
      TrainsText = getTrainsFromList(queue:to_list(Request)),
      wxStaticText:setLabel(RequestsView, string:concat(WaitingText, TrainsText)),
      loop2(Wx);

    {Station, Platform, left} ->
      {Key, Result} = lists:keyfind(Platform, 1, PlatformsView),
      wxStaticText:setLabel(Result, string:concat("Peron ", integer_to_list(Platform))),
      loop2(Wx);

      {Station, TrainName, Request, waiting} ->
        WaitingText = "Oczekujace \n",
        TrainsText = getTrainsFromList(queue:to_list(Request)),
        wxStaticText:setLabel(RequestsView, string:concat(WaitingText, TrainsText)),
        loop2(Wx)
    end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%USER%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TODO
user(Server, Frame) ->
    {ok, [PlNo]} = io:fread("Number of platforms: ","~d"),
    station:start(self()),
    Pl = station_generator:make_platforms(PlNo),
    Wx = make_window3(Server, Frame, PlNo),
    UserPid = station_generator:start_link_user(),
    loop3(Wx).

make_window3(Server , Frame, PlNo) ->
  End_Button = wxButton:new(Frame, 3, [{label, "End simulation"}, {pos, {500,50}}]),
  Platform6 = [{6, wxStaticText:new(Frame, 0, "Peron 6", [{pos, {200, 350}}])}],
  Platform5 = [{5, wxStaticText:new(Frame, 0, "Peron 5", [{pos, {200, 300}}])}|Platform6],
  Platform4 = [{4, wxStaticText:new(Frame, 0, "Peron 4", [{pos, {200, 250}}])}|Platform5],
  Platform3 = [{3, wxStaticText:new(Frame, 0, "Peron 3", [{pos, {200, 200}}])}|Platform4],
  Platform2 = [{2, wxStaticText:new(Frame, 0, "Peron 2", [{pos, {200, 150}}])}|Platform3],
  Platform1 = [{1, wxStaticText:new(Frame, 0, "Peron 1", [{pos, {200, 100}}])}|Platform2],
  PlatformsView = Platform1,

  RequestsView = wxStaticText:new(Frame, 0, "Oczekujące", [{pos, {500, 350}}]),

  wxFrame:show(Frame),
  {Server, Frame, End_Button, PlatformsView, RequestsView}.

loop3(Wx) ->
  {_, Frame, End_Button, PlatformsView, RequestsView} = Wx,
  receive
    #wx{event=#wxClose{}} ->
        io:format("--closing window ~p-- ~n",[self()]),
        wxWindow:destroy(Frame),
        ok,
        loop3(Wx);

    #wx{id = 3, event=#wxCommand{type = command_button_clicked}} ->
        % TODO STOP SIMULATION      
        loop3(Wx);


    {Station, Platform, TrainName, Request, onPlatform} ->
      {Key, Result} = lists:keyfind(Platform, 1, PlatformsView),
      PlatformText = string:concat(string:concat("Peron ", integer_to_list(Platform)),"\n"),
      wxStaticText:setLabel(Result, string:concat(PlatformText, TrainName)),
      WaitingText = "Oczekujace \n",
      TrainsText = getTrainsFromList(queue:to_list(Request)),
      wxStaticText:setLabel(RequestsView, string:concat(WaitingText, TrainsText)),
      loop3(Wx);

    {Station, Platform, left} ->
      {Key, Result} = lists:keyfind(Platform, 1, PlatformsView),
      wxStaticText:setLabel(Result, string:concat("Peron ", integer_to_list(Platform))),
      loop3(Wx);

      {Station, TrainName, Request, waiting} ->
        WaitingText = "Oczekujace \n",
        TrainsText = getTrainsFromList(queue:to_list(Request)),
        wxStaticText:setLabel(RequestsView, string:concat(WaitingText, TrainsText)),
        loop3(Wx)
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
getTrainsFromList([]) ->
  [];

getTrainsFromList([{_,TrainName,_}|Rest]) ->
  [string:concat(TrainName, "\n")| getTrainsFromList(Rest)].
