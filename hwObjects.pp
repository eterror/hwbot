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
    THwbot = class (TObject)
    	user:       array of hwTypes.TUser;
	plugin:     array of hwTypes.TPlugin;
	pc:         Byte;   
	        
	function Reconnect():boolean;
	function Disconnect():boolean;
	function Connect():boolean;
	function Loop():boolean;
	function Register():boolean;
	function Info():boolean;
	function LoadPlugin(name:string):byte;
	function UnloadPlugin(id: Integer):Boolean;
	function ReloadPlugin(id: byte; name:string):byte;
	function LoadConfig():Boolean;
	procedure InitPLugins(); 
	
	function uAddUser(name: String; flag: String):boolean;
	function uDelUser(name: String):boolean;
    end;


implementation

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
begin
    writeln('[#] Reconnecting (15s)...');
    Disconnect();
    sleep(15000);
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

function THwbot.ReLoadPlugin(id: Byte; name: String):Byte;
begin
    try
        plugin[id].hnd:=LoadLibrary(name);
    except
        exit(1);
    end;

    try
        Pointer(plugin[id].parse):=GetProcedureAddress(plugin[id].hnd, 'PluginParse');
        Pointer(plugin[id].onquit):=GetProcedureAddress(plugin[id].hnd, 'OnQuit');
        Pointer(plugin[id].onjoinlobby):=GetProcedureAddress(plugin[id].hnd, 'OnJoinLobby');
        Pointer(plugin[id].onjoinroom):=GetProcedureAddress(plugin[id].hnd, 'OnJoinRoom');
        Pointer(plugin[id].gcmd):=GetProcedureAddress(plugin[id].hnd, 'GetPluginCommand');
        Pointer(plugin[id].gver):=GetProcedureAddress(plugin[id].hnd, 'GetPluginVersion');
        Pointer(plugin[id].gauthor):=GetProcedureAddress(plugin[id].hnd, 'GetPluginAuthor');
        Pointer(plugin[id].gname):=GetProcedureAddress(plugin[id].hnd, 'GetPluginName');
        Pointer(plugin[id].ghelp):=GetProcedureAddress(plugin[id].hnd, 'GetPluginHelp');
        Pointer(plugin[id].gusage):=GetProcedureAddress(plugin[id].hnd, 'GetPluginUsage');
        Pointer(plugin[id].ginit):=GetProcedureAddress(plugin[id].hnd, 'PluginInit');
    except
        exit(1);
    end;

    plugin[id].cmd:=plugin[id].gcmd();
    plugin[id].ver:=plugin[id].gver();
    plugin[id].author:=plugin[id].gauthor();
    plugin[id].name:=plugin[id].gname();
    plugin[id].usage:=plugin[id].gusage();
    plugin[id].help:=plugin[id].ghelp();
    plugin[id].fname:=name;
    plugin[id].gInit(hwTypes.sin, hwTypes.sout);

    ReloadPlugin:=0;
end;

function THwbot.LoadPlugin(name: String):Byte;
var
    i:  Integer;

begin
    pc+=1;
    plugin[pc]:=TPlugin.Create;

    write('[P:',pc,'] ',name,': ');

    for i:=1 to (pc-1) do
        if (plugin[i].fname = name) then
        begin
            plugin[pc].Free;
            pc-=1;
            writeln('FAILED');
            exit(3);
        end;

    if (not FileExists(name)) then
    begin
        plugin[pc].Free;
        pc-=1;
        writeln('FAILED');
        exit(2);
    end;

    try
        plugin[pc].hnd:=LoadLibrary(name);
    except
        {...}
    end;
    if (plugin[pc].hnd = 0) then
    begin
        plugin[pc].Free;
        writeln('FAILED') ;
        plugin[pc].cmd:='';
        pc-=1;
        exit(1);
    end else
        writeln('OK ');

    Pointer(plugin[pc].parse):=GetProcedureAddress(plugin[pc].hnd, 'PluginParse');
    Pointer(plugin[pc].onquit):=GetProcedureAddress(plugin[pc].hnd, 'OnQuit');
    Pointer(plugin[pc].onjoinroom):=GetProcedureAddress(plugin[pc].hnd, 'OnJoinRoom');
    Pointer(plugin[pc].onjoinlobby):=GetProcedureAddress(plugin[pc].hnd, 'OnJoinLobby');
    Pointer(plugin[pc].gcmd):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginCommand');
    Pointer(plugin[pc].gver):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginVersion');
    Pointer(plugin[pc].gauthor):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginAuthor');
    Pointer(plugin[pc].gname):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginName');
    Pointer(plugin[pc].ghelp):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginHelp');
    Pointer(plugin[pc].gusage):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginUsage');
    Pointer(plugin[pc].ginit):=GetProcedureAddress(plugin[pc].hnd, 'PluginInit');

    if  (Pointer(plugin[pc].parse) = nil) or
        (Pointer(plugin[pc].onquit) = nil) or
        (Pointer(plugin[pc].onjoinlobby) = nil) or
        (Pointer(plugin[pc].onjoinroom) = nil) or
        (Pointer(plugin[pc].gcmd) = nil) or
        (Pointer(plugin[pc].gver) = nil) or
        (Pointer(plugin[pc].gauthor) = nil) or
        (Pointer(plugin[pc].ghelp) = nil) or
        (Pointer(plugin[pc].gusage) = nil) or
        (Pointer(plugin[pc].gname) = nil) or
        (Pointer(plugin[pc].gInit) = nil) then
    begin
        writeln('[!] Not defined all functions in plugin. Case sensivity may cause this errors.');
        pc-=1;
        exit(4);
    end;

    plugin[pc].cmd:=plugin[pc].gcmd();
    plugin[pc].ver:=plugin[pc].gver();
    plugin[pc].author:=plugin[pc].gauthor();
    plugin[pc].name:=plugin[pc].gname();
    plugin[pc].usage:=plugin[pc].gusage();
    plugin[pc].help:=plugin[pc].ghelp();
    plugin[pc].fname:=name;

    writeln('[P:',pc,':NAME]: ',plugin[pc].name,' / ',plugin[pc].author,' ',plugin[pc].ver,' -> ',plugin[pc].cmd);

    LoadPlugin:=0;
end;


function THwbot.UnloadPlugin(id: Integer):boolean;
begin
    write('[*] Removing plugin -> ',id,': ');
    try
        //UnloadLibrary(plugin[i].hnd);
        FreeLibrary(plugin[i].hnd);
        plugin[i].Free;
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
        writeln(sout, 'Type .help for command list');

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

function THwbot.Loop():boolean;
begin
    repeat
        readln(sIn, line);
        {$IFDEF DEBUG}if line<>'' then writeln(' -> "',line,'"');{$ENDIF}
        //Parse(line);
    until (quit);

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

begin
    write('[*] Loading config file (',HW_CONFIG,'): ');

    assign(f, HW_CONFIG);
    {$I-}reset(f);{$I+}
    if (IOResult <> 0) then
    begin
        writeln('Failed.');
        exit;
    end else
        writeln('OK');

    while not (eof(f)) do
    begin
        readln(f,l);

        if (l[1] = '#') or (l[2] = '#') then
            readln(f, l);

        if (copy(l, 1, 7) = 'plugin=') then
        begin
            p:=trim(copy(l, pos('=',l)+1, length(l)));

            if (pos('/',p) <> 0) then
                e:=LoadPlugin(p)
            else
                e:=LoadPlugin(HW_PLUGINS+p);
        end;

        if (copy(l, 1,5) = 'nick=') then
        begin
            p:=trim(copy(l, pos('=',l)+1, length(l)));

            if (p <> '') then
                HW_NICK:=p;
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

    close(f)
end;


begin
end.
