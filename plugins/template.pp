(*
 * This a template plugin for HW InfoBOT
*)

{$MODE OBJFPC}

library plugin_template;

uses
    hwTypes,
    sysutils;


const
    plugin_name = 'Template';
    plugin_command ='.template';
    plugin_help:AnsiString = 'Template';
    plugin_author = 'Template';
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


function PluginParse(const s: String; const u: array of TUser):String; cdecl; export;
begin
    PluginParse:='';
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
                