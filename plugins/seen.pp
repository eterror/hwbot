library plugin_seen;

uses
    hwTypes,
    strutils,
    sysutils,
    dateutils;

const
    plugin_name = 'seen';
    plugin_command ='.seen';
    plugin_help = 'Help for seen';
    plugin_author = 'solaris';
    plugin_version = '1.0';
    plugin_usage = '[nickname]';
	
    HW_DB_FILE = '/tmp/hwbot.plugin.seen';
    OLD_SEEN = {DAYS}90 * 86400;

type
    TSeen = packed record
        nickname:       String;
        date:           TDateTime;
    end;


var
    seen:       array[1..HW_MAXUSERS] of TSeen;
    user:	array[0..HW_MAXUSERS+1] of TUser;	 


function saveDB(): boolean;
var
    f:  file;

begin
    {$IFDEF DEBUG}writeln('[#] Dumping database.');{$ENDIF}
    assign(f, HW_DB_FILE);
    {$I-}rewrite(f, 1);{$I+}

    if (IOREsult <> 0) then
    begin
    {$IFDEF DEBUG}writeln('[#] Dumping database error (file access/no free space).');{$ENDIF}
        saveDB:=FALSE;
        exit;
    end;

    blockwrite(f, seen, sizeof(seen));
    close(f);

    saveDB:=TRUE;
end;


function loadDB(): boolean;
var
    f:  file;

begin
    {$IFDEF DEBUG}writeln('[#] Loading database.');{$ENDIF}
    assign(f, HW_DB_FILE);
    {$I-}reset(f, 1);{$I+}

    if (IOREsult <> 0) then
    begin
    {$IFDEF DEBUG}writeln('[#] Dumping database error (file access/no free space).');{$ENDIF}
        loadDB:=FALSE;
        exit;
    end;

    blockread(f, seen, sizeof(seen));
    close(f);

    loadDB:=TRUE;
end;



function calcSeen(who: String):string;
var
    i: Integer;
    s: Int64;

begin
    for i:=1 to high(seen) do
        if (AnsiUpperCase(seen[i].nickname) = AnsiUpperCase(who)) then
        begin
            s:=SecondsBetween(Now, seen[i].date);

            if (s > 0) and (s < 60) then
                calcSeen:=IntToStr(s)+' seconds';

            if (s > 59) and (s < 3600)then
                calcSeen:=IntToStr(s div 60)+ ' minutes';

            if (s > 3599) and (s < 86400) then
                calcSeen:=IntToStr(s div (60 * 60))+' hours';

            if (s > 86399) then
                calcSeen:=IntToStr(s div (60 * 60 * 24))+' days';

            // week
            // month
            exit;
        end;

    calcSeen:='';
end;


function deleteoldSeen():boolean;
var
    i:  Integer;

begin
    for i:=1 to high(seen) do
        if (secondsBetween(Now, seen[i].date) > OLD_SEEN) then
        begin
            seen[i].nickname:='';
            seen[i].date:=0;
        end;

    deleteOldSeen:=TRUE;
end;



function addSeen(who: string):boolean;
var
    i:  Integer;

begin
    for i:=1 to high(seen) do
        if (AnsiUpperCase(seen[i].nickname) = who) then
        begin
            seen[i].date:=now;
            exit;
        end;

    for i:=1 to high(seen) do
        if (seen[i].nickname = '') then
        begin
            seen[i].nickname:=AnsiUpperCase(who);
            seen[i].date:=now;
            exit;
        end;

    addSeen:=TRUE;
end;


function isOnline(who: String):boolean;
var
    i:  Integer;

begin
    for i:=0 to (HW_MAXUSERS+1) do
        if (AnsiUpperCase(user[i].nickname) = AnsiUpperCase(who)) then
        begin
            isOnline:=TRUE;
            exit;
        end;

    isOnline:=FALSE;
end;


function OnJoinRoom(const s: String):String; cdecl; export;
begin
    onJoinRoom:='';
end;


function OnJoinLobby(const s: String):String; cdecl; export;
begin
    // reset seen
    onJoinLobby:='';
end;


function OnQuit(const s: String):String; cdecl; export;
begin
    addSeen(AnsiUpperCase(s));
    deleteOldSeen();
    saveDB();
end;


function PluginParse(const s: String; const u: array of TUser):String; cdecl; export;
var
    i:		Integer;
    param:	String;
    nick:	String;
    buf:	String;
    
begin
    for i:=0 to (HW_MAXUSERS+1) do
	user[i].nickname:=u[i].nickname;
	
    nick:=ExtractWord(1, s, [':']);
    param:=ExtractWord(2, s, [#32]);
    
    if (length(param) = 0) then
    begin
    	PluginParse:=nick+': You need to type username';
	exit;
    end;
    
    if (isOnline(param)) then
    begin
	PluginParse:=nick+': '+param+' is now online!';
	exit;
    end;
    
    buf:=calcSeen(param);
    
    if (buf ='') then
	PluginParse:=nick+': Long time did no see him.' 
    else
	PluginParse:=nick+': Last seen '+buf+' ago';
end;   
 
 
procedure PluginInit(var sin, sout: Text); cdecl; export;
begin
end;

function GetPluginCommand:String; cdecl; export;
begin
    GetPluginCommand:=plugin_command;
end;

    
function GetPluginVersion:String; cdecl; export;
begin
    GetPluginVersion:=plugin_version;
end;

        
function GetPluginAuthor:String; cdecl; export;
begin
    GetPluginAuthor:=plugin_author;
end;
    
            
function GetPluginName:String; cdecl; export;
begin
    GetPluginName:=plugin_name;
end;

function GetPluginUsage:String; cdecl; export;
begin
    GetPluginUsage:=plugin_usage;
end;

function GetPluginHelp:AnsiString; cdecl; export;
begin
    GetPluginHelp:=plugin_help;
end;
                

exports
    PluginInit,
    OnJoinLobby,
    OnJoinRoom,
    OnQuit,
    PluginParse,
    GetPluginCommand,
    GetPluginName,
    GetPluginVersion,
    GetPluginAuthor,
    GetPluginHelp,
    GetPluginUsage;
                                    
                                    
begin
    loadDB();
end.
                                                    
