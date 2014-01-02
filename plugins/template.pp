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


function OnJoinRoom(const s: String):String; cdecl; export;
begin
    OnJoinRoom:='';
end;


function onJoinLobby(const s: String):String; cdecl; export;
begin	
    onJoinLobby:='';
end;


function onQuit(const s: String):String; cdecl; export;
begin
    onQuit:='';
end;


function PluginParse(const s: String; const u: array of TUser):String; cdecl; export;
begin
    PluginParse:='';
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
                