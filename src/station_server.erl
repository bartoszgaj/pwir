-module(station_server).
-compile(export_all).
-include_lib("wx/include/wx.hrl").
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
            init2(Server);

        #wx{id = 2, event=#wxCommand{type = command_button_clicked}} ->
            user()

      end.

init2(Server) ->
  station:start(),
  PlNo = station_generator:generate_platforms(),
  Wx = make_window2(Server, PlNo),
  GeneratorPid = station_generator:start_link(),
  loop2(Wx).

make_window2(Server ,PlNo) ->
  Frame = wxFrame:new(Server, -1, "Train station simulation", [{size,{1000,500}}]),
  End_Button = wxButton:new(Frame, ?wxID_STOP, [{label, "End simulation"}, {pos, {300,70}}]),
  Platform6 = [{6, wxStaticText:new(Frame, 0, "Peron 6", [{pos, {200, 350}}])}],
  Platform5 = [{5, wxStaticText:new(Frame, 0, "Peron 5", [{pos, {200, 300}}])}|Platform6],
  Platform4 = [{4, wxStaticText:new(Frame, 0, "Peron 4", [{pos, {200, 250}}])}|Platform5],
  Platform3 = [{3, wxStaticText:new(Frame, 0, "Peron 3", [{pos, {200, 200}}])}|Platform4],
  Platform2 = [{2, wxStaticText:new(Frame, 0, "Peron 2", [{pos, {200, 150}}])}|Platform3],
  Platform1 = [{1, wxStaticText:new(Frame, 0, "Peron 1", [{pos, {200, 100}}])}|Platform2],
  PlatformsView = Platform1,

  wxFrame:createStatusBar(Frame),
  wxFrame:show(Frame),

  wxFrame:connect(Frame, close_window),
  wxButton:connect(End_Button, command_button_clicked),
  io:format("TEST"),
  % {Server, Frame, End_Button, Time_Text, ClientsR, ClientsS}.
  {Server, Frame, End_Button, PlatformsView}.

loop2(Wx) ->
  {_, Frame, Auto_Button, Manual_Button} = Wx,
  receive
    #wx{event=#wxClose{}} ->
        io:format("--closing window ~p-- ~n",[self()]),
        wxWindow:destroy(Frame),
        ok


  end.


%TODO
user() ->
    {ok, [X]} = io:fread("Number of platforms: ","~d"),
    X.
