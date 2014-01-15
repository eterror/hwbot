(*
 * NEED FIX
*)

{$MODE OBJFPC}

library plugin_who;

uses
    hwTypes,
    geoip,
    sysutils,
    strutils,
    unix,
    unixtype;


const
    plugin_name = 'who';
    plugin_command ='.who';
    plugin_help:AnsiString = 'Return some information about user';
    plugin_author = 'solaris';
    plugin_version = '1.0';
    plugin_usage = '[username]';

var
    bin, bout:	Text;


function OnJoinRoom(const s: String):String; cdecl; export;
begin
    OnJoinRoom:='';
end;


function OnJoinLobby(const s: String):String; cdecl; export;
begin	
    onJoinLobby:='';
end;


function OnQuit(const s: String):String; cdecl; export;
begin
    onQuit:='';
end;


function PluginParse(const s: String; const u: array of TUser; botnick: String):String; cdecl; export;

    function isOnline(who: String):boolean;
    var
	i:  Integer;
    
    begin
	for i:=0 to HW_MAXUSERS do
    	    if (u[i].nickname = who) then
        	exit(TRUE);
                            
	exit(FALSE);
    end;

var
    nick:	String;
    param:	String;
    s1, s3,
    s2, s4:	String;
    
begin
    nick:=copy(s, 1, pos(':', s)-1);
        
    if (pos(#32, s) <> 0) then
        param:=copy(s, pos(#32,s)+1, length(s)) else
        param:='';
        
    param:=trim(param);
                            
    if (length(param) = 0) then
    begin
	PluginParse:=nick+': '+plugin_command+#32+plugin_usage;
	exit;
    end;
    
    s1:=ExtractWord(1, param, [':']);

    if not(isOnline(s1)) then
    begin
        PluginParse:=nick+': '+param+' is offline';
        exit;
    end;
    
    writeln(bout, 'INFO');
    writeln(bout, param,#10);
    
    readln(bin);
    readln(bin);
    readln(bin);
    
    readln(bin, s2);
    readln(bin, s3);
    readln(bin, s4);
        
    writeln(bout,'CHAT',#10,nick+': '+param+'('+GetCountry(s2)+'):'+#32+s3+#32+s4+#10);   
    exit('');                     
end;   
 
 
procedure PluginInit(var sin, sout: Text); cdecl; export;
begin
    bin:=sin;
    bout:=sout;
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
    GetPluginUsage,
    GetPluginHelp;
                                    
                                    
begin
end.
                
