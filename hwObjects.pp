{$MODE OBJFPC}

unit hwObjects;

interface

uses
    sysutils,
    dynlibs,
    strutils,
    hwTypes,
    sockets,
    unix,
    errors;

type
    TPlugin = class(TObject)
    public var
        hnd:            TLibHandle;
        cmd:            String[64];
        fname:          String;
        name:           String[64];
        author:         String[128];
        ver:            String[32];
        usage:          String;
        help:           AnsiString;
        
    public type
            TPluginInit =        procedure (var sin, sout: Text); cdecl;
            TParse =                function (const s: String; const u: array of TUser; botnick: String):String; cdecl;
            TOnJoinLobby =        function (const s: String):String; cdecl;
            TOnJoinRoom =         function (const s: String):String; cdecl;
            TOnQuit =                  function (const s: String):String; cdecl;
            TGetCommand =              function :String; cdecl;
            TGetPluginVersion =        function :String; cdecl;
            TGetPluginAuthor =         function: String; cdecl;
            TGetPluginName =           function: String; cdecl;
            TGetPluginUsage =          function: String; cdecl;
            TGetPluginHelp =           function: AnsiString; cdecl;

    public var
            gcmd:               TGetCommand;
            gver:               TGetPluginVersion;
            gauthor:            TGetPluginAuthor;
            gname:              TGetPluginName;
            ghelp:              TGetPluginHelp;
            gusage:             TGetPluginUsage;
            parse:              TParse;
            onjoinlobby:        TOnJoinLobby;
            onjoinroom:         TOnJoinRoom;
            onquit:             TOnQuit;
            ginit:              TPluginInit;
            
            function Reload():Byte;
            function Unload():Boolean;
            function Load(n: String):Byte;
    end;

	
    THwbot = class (TObject)
    	user:       array of hwTypes.TUser;
	plugin:     array of TPlugin;
	pc:         Byte;   
	        
	function Reconnect():boolean;
	function Disconnect():boolean;
	function Connect():boolean;
	function Register():boolean;
	
	function Info():boolean;
	function LoadConfig():Boolean;
	
	procedure InitPlugins(); 
	
	function uAddUser(name: String; flag: String):boolean;
	function uDelUser(name: String):boolean;
	function uAddFlag(name: String; flag: string):boolean;
    end;


implementation

function THwbot.uAddFlag(name: String; flag: string):boolean;
var
    i:  Integer;

begin
    for i:=0 to (high(user)) do
        if (user[i].nickname = name) then
        begin
            user[i].mode:=flag;
            exit(TRUE);
        end;

    exit(FALSE);
end;


function THwbot.uAddUser(name: String; flag: String):boolean;
var
    i:  Integer;

begin
    for i:=0 to high(user) do
        if (user[i].nickname = '') then
        begin
            user[i].upname:=AnsiUpperCase(name);
            user[i].mode:=flag;
            user[i].nickname:=name;
            exit(TRUE);
        end;

    exit(FALSE);
end;


function THwbot.uDelUser(name: String):boolean;
var
    i:  Integer;

begin
    for i:=0 to high(user) do
        if (user[i].upname = AnsiUpperCase(name)) then
        begin
            user[i].nickname:='';
            user[i].upname:='';
            user[i].mode:='';
            exit(TRUE);
        end;

    exit(FALSE);
end;


function THwbot.Reconnect():boolean;
var
    time:	LongInt;
    
begin
    time:=15;
    writeln('[#] Reconnecting (',time,'s)...');
    Disconnect();
    sleep(time * 1000);
    Connect();
    Register();
    exit(TRUE);
end;


function THwbot.Connect():boolean;
begin
    writeln('[#] Estabilising connection to HW server');
    randomize;

    sAddr.sin_family:=AF_INET;
    sAddr.sin_Port:=htons(HW_PORT);
    sAddr.sin_Addr.s_addr:=LongInt((StrToNetAddr(HW_IP)));

    S:=fpSocket(AF_INET, SOCK_STREAM, 0);

    // deprecated function, need fpConnect()
    if not sockets.Connect(S, sAddr, sIn, sOut) then
    begin
        writeln(' error# ', strerror(SocketError));
        Connect:=FALSE;
        exit;
    end;

    Reset(sIn);
    Rewrite(sOut);

    Connect:=TRUE;
end;

function TPlugin.Reload():Byte;
begin
    try
        hnd:=LoadLibrary(fname);
    except
        exit(1);
    end;
    
    try
        Pointer(parse):=GetProcedureAddress(hnd, 'PluginParse');
        Pointer(onquit):=GetProcedureAddress(hnd, 'OnQuit');
        Pointer(onjoinlobby):=GetProcedureAddress(hnd, 'OnJoinLobby');
        Pointer(onjoinroom):=GetProcedureAddress(hnd, 'OnJoinRoom');
        Pointer(gcmd):=GetProcedureAddress(hnd, 'GetPluginCommand');
        Pointer(gver):=GetProcedureAddress(hnd, 'GetPluginVersion');
        Pointer(gauthor):=GetProcedureAddress(hnd, 'GetPluginAuthor');
        Pointer(gname):=GetProcedureAddress(hnd, 'GetPluginName');
        Pointer(ghelp):=GetProcedureAddress(hnd, 'GetPluginHelp');
        Pointer(gusage):=GetProcedureAddress(hnd, 'GetPluginUsage');
        Pointer(ginit):=GetProcedureAddress(hnd, 'PluginInit');
    except
        exit(2);
    end;

    try
	cmd:=gcmd();
	ver:=gver();
	author:=gauthor();
	name:=gname();
	usage:=gusage();
	help:=ghelp();
	fname:=name;
	gInit(hwTypes.sin, hwTypes.sout);
    except;
	exit(3);
    end;

    exit(0);
end;


function TPlugin.Load(n: String):Byte;
var
    i:  Integer;

begin
    write('[@] Loading plugin -> ',n,': ');

    if (not FileExists(n)) then
    begin
        //Free;
        writeln('FAILED');
        exit(1);
    end;

    try
        hnd:=LoadLibrary(n);
    except
        //exit(2);
    end;
    
    if (hnd = 0) then
    begin
        //Free;
        writeln('FAILED') ;
        exit(2);
    end;

    Pointer(parse):=GetProcedureAddress(hnd, 'PluginParse');
    Pointer(onquit):=GetProcedureAddress(hnd, 'OnQuit');
    Pointer(onjoinroom):=GetProcedureAddress(hnd, 'OnJoinRoom');
    Pointer(onjoinlobby):=GetProcedureAddress(hnd, 'OnJoinLobby');
    Pointer(gcmd):=GetProcedureAddress(hnd, 'GetPluginCommand');
    Pointer(gver):=GetProcedureAddress(hnd, 'GetPluginVersion');
    Pointer(gauthor):=GetProcedureAddress(hnd, 'GetPluginAuthor');
    Pointer(gname):=GetProcedureAddress(hnd, 'GetPluginName');
    Pointer(ghelp):=GetProcedureAddress(hnd, 'GetPluginHelp');
    Pointer(gusage):=GetProcedureAddress(hnd, 'GetPluginUsage');
    Pointer(ginit):=GetProcedureAddress(hnd, 'PluginInit');

    if  (Pointer(parse) = nil) or      (Pointer(onquit) = nil) or (Pointer(onjoinlobby) = nil) or
        (Pointer(onjoinroom) = nil) or (Pointer(gcmd) = nil) or   (Pointer(gver) = nil) or 
        (Pointer(gauthor) = nil) or    (Pointer(ghelp) = nil) or  (Pointer(gusage) = nil) or
        (Pointer(gname) = nil) or      (Pointer(gInit) = nil) then
    begin
        writeln('FAIL: Not defined all functions in plugin.');
        exit(3);
    end;

    cmd:=gCmd();
    ver:=gVer();
    author:=gAuthor();
    name:=gName();
    usage:=gUsage();
    help:=gHelp();
    fname:=n;

    writeln(name,':',ver,' / ',author,' -> ',cmd);

    exit(0);
end;


function TPlugin.Unload():boolean;
begin
    write('[*] Removing plugin -> ',name,': ');
    try
        UnloadLibrary(hnd);
        hnd:=0;
        writeln('OK');
        exit(TRUE)
    except
        writeln('FAIL');
        exit(FALSE)
    end;
end;


procedure THwbot.InitPlugins();
var
    i:  Integer;

begin
    for i:=0 to (pc) do
        try
            plugin[i].gInit(sin, sout);
        except
            continue;
        end;
end;

function THwbot.Register():boolean;
var
    k:          Integer;
    buf:        String;

begin
    writeln('[#] Registering user');


    writeln(sOut, 'PROTO');
    writeln(sOut, HW_PROTO,#10);
    writeln(sOut, 'NICK');
    writeln(sOut, HW_NICK,#10);

    // SKIP FIRST DATA
    for i:=1 to 12 do
    begin
        readln(sin, buf);
        {$IFDEF DEBUG}writeln('[DEBUG]',buf,'[!]');{$ENDIF}

        if (buf = 'ASKPASSWORD') and (HW_PASSWORD <> '') then
        begin
            writeln('[*] Sending password (',HW_PASSWORD,')');
            writeln(sout, 'PASSWORD');
            writeln(sout, HW_PASSWORD,#10);
        end;

        if (buf = 'NOTICE') then
        begin
            readln(sin, buf);
            writeln('[%] Server notice: ',buf);

            HW_NICK+=IntToStr(random(10));

            Reconnect();
        end;

        if (buf = 'ERROR') or (buf = 'BYE') then
        begin
            readln(sin, buf);

            writeln('[!] Connection error: ',buf);

            if (buf = 'Authentication failed') then
            begin
                quit:=TRUE;
                exit;
            end;

            Reconnect();
        end;
    end;

    write('[#] Users online: ');
    i:=0;
    repeat
        readln(sin, line);
        if (line = '') then break;
        i+=1;
        //write(line,',');
        uAddUser(line, '+u');
    until (line = '');

    writeln(i);

    Register:=TRUE;

    if (length(HW_ROOM) <> 0) then
    begin
        writeln('[#] Joining to room');
        writeln(sout, 'CREATE_ROOM');
        writeln(sout, HW_ROOM,#10);
        writeln(sout, 'JOIN_ROOM');
        writeln(sout, HW_ROOM,#10);
        writeln(sout, 'TOGGLE_READY');
        writeln(sout);

        writeln(sout, 'ADD_TEAM');
        writeln(sout, 'Welcome to Hedgewars INFOBOT Service by Terror');

        for i:=1 to 22 do
            writeln(sout, chr(65+random(15)));

        writeln(sout);

        writeln(sout, 'ADD_TEAM');
        writeln(sout, 'Type '+HW_CMDCHAR+'help for command list');

        for i:=1 to 22 do
            writeln(sout, chr(65+random(15)));

        writeln(sout);
    end;
end;


function THwbot.Disconnect():boolean;
begin
    writeln(sout, 'QUIT');
    writeln(sout, 'I will be back!',#10);
    close(sOut);
    exit(TRUE);
end;


function THwbot.Info():boolean;
var
    r:  String;

begin
    if (length(HW_ROOM) = 0) then
        r:='Lobby'
    else
        r:=HW_ROOM;

    writeln(Format('[*] Nickname: %s', [HW_NICK]));
    writeln(Format('[*] Protocol: %d ',[HW_PROTO]));
    writeln(Format('[*] Server: %s:%d',[HW_IP, HW_PORT]));
    writeln(Format('[*] Config file: %s', [HW_CONFIG]));
    writeln(Format('[*] Plugins patch: %s', [HW_PLUGINS]));
    writeln(Format('[*] Room: %s', [r]));
    // other options...
    
    exit(TRUE);
end;

function THwbot.LoadConfig():boolean;
var
    f:  text;
    l:  String;
    p:  String;
    e:  Byte;
    dir: String;

begin
    write('[*] Loading config file (',HW_CONFIG,'): ');

    assign(f, HW_CONFIG);
    {$I-}reset(f);{$I+}
    if (IOResult <> 0) then
    begin
        writeln('Failed.');
        exit(FALSE);
    end else
        writeln('OK');
        
    pc:=0;

    while not (eof(f)) do
    begin
        readln(f,l);

        if (l[1] = '#') or (l[2] = '#') then
            readln(f, l);

        if (copy(l, 1, 7) = 'plugin=') then
        begin
            p:=trim(copy(l, pos('=',l)+1, length(l)));

            if (pos('/',p) <> 0) then
                dir:=p
            else
                dir:=(HW_PLUGINS+p);
                
    	    pc+=1;
            plugin[pc]:=TPlugin.Create;
            
            if (plugin[pc].Load(dir) <> 0) then
            begin
        	//plugin[pc].Free;
        	pc-=1;
    	    end;
        end;
        
        if (copy(l, 1,8) = 'notices=') then
        begin
            p:=trim(copy(l, pos('=',l)+1, length(l)));

            if (p <> '') then
                HW_NOTICES:=p;
        end;

        if (copy(l, 1,8) = 'command=') then
        begin
            p:=trim(copy(l, pos('=',l)+1, length(l)));

            if (p <> '') and (length(p) = 1) then
                HW_CMDCHAR:=p[1];
        end;
        
        if (copy(l, 1,5) = 'nick=') then
        begin
            p:=trim(copy(l, pos('=',l)+1, length(l)));

            if (p <> '') then
                HW_NICK:=p;
        end;
        
        if (copy(l, 1,6) = 'admin=') then
        begin
            p:=trim(copy(l, pos('=',l)+1, length(l)));

            if (p <> '') then
                HW_ADMIN:=p;
        end;

        if (copy(l, 1,14) = 'plugins_patch=') then
        begin
            p:=trim(copy(l, pos('=',l)+1, length(l)));

            if (p[length(p)] <> '/') then
                p+='/';

            if (p <> '') then
                HW_PLUGINS:=p;
        end;


        if (copy(l, 1, 5) = 'room=') then
        begin
            p:=trim(copy(l, pos('=',l)+1, length(l)));

            if (p <> '') then
                HW_ROOM:=p;
        end;

        if (copy(l, 1, 9) = 'password=') then
        begin
            p:=trim(copy(l, pos('=',l)+1, length(l)));

            if (p <> '') then
                HW_PASSWORD:=p;
        end;
    end;

    close(f);
    exit(TRUE);
end;


begin
end.
