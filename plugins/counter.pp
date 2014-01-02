(*
 * This a template plugin for HW InfoBOT
*)

{$MODE OBJFPC}

library plugin_counter;

uses
    hwTypes,
    sysutils,
    strutils;


const
    plugin_name = 'counter';
    plugin_command ='.counter';
    plugin_help:AnsiString = 'Counts joins to server';
    plugin_author = 'solaris';
    plugin_version = '1.0';
    plugin_usage = '';
    
    HW_DB = '/tmp/hwbot.plugin.counter';

var
    c:	Cardinal;


function saveDB(): boolean;
var
    f:  file;

begin
    assign(f, HW_DB);
    {$I-}rewrite(f, 1);{$I+}

    if (IOREsult <> 0) then
        begin
            saveDB:=FALSE;
            exit;
        end;

    blockwrite(f, c, sizeof(c));
    close(f);

    saveDB:=TRUE;
end;


function loadDB(): boolean;
var
    f:  file;

begin
    assign(f, HW_DB);
    {$I-}reset(f, 1); {$I+}

    if (IOREsult <> 0) then
    begin
        //saveDB();
        loadDB:=FALSE;
        exit;
    end;

    blockread(f, c, sizeof(c));
    close(f);

    loadDB:=TRUE;
end;


function OnJoinRoom(const s: String):String; cdecl; export;
begin
    OnJoinRoom:='';
end;


function OnJoinLobby(const s: String):String; cdecl; export;
begin
    c+=1;
    saveDB();
    onJoinLobby:='';
end;


function OnQuit(const s: String):String; cdecl; export;
begin
    onQuit:='';
end;


function PluginParse(const s: String; const u: array of TUser):String; cdecl; export;
var 
    nick:	String;
    
    
begin
    nick:=ExtractWord(1, s, [':']);
    PluginParse:=nick+': total visitors -> '+IntToStr(c);
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
    OnJoinRoom,
    OnJoinLobby,
    OnQuit,
    PluginParse,
    GetPluginCommand,
    GetPluginName,
    GetPluginVersion,
    GetPluginAuthor,
    GetPluginUsage,
    GetPluginHelp;
                                    
                                    
begin
    c:=0;
    loadDB();
end.
