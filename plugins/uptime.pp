(*
 * This a template plugin for HW InfoBOT
*)

{$MODE OBJFPC}

library plugin_uptime;

uses
    hwTypes,
    sysutils,
    strutils,
    dateutils;


const
    plugin_name = 'uptime';
    plugin_command ='.uptime';
    plugin_help:AnsiString = 'Returns bot uptime';
    plugin_author = 'solaris';
    plugin_version = '1.0';
    plugin_usage = '';
    
var
    d:	TDateTime;


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
var 
    nick:	String;
    days:	Integer;
    num_seconds:Int64;
    hours:	Integer;
    minutes:	Integer;
    
    
begin
    num_seconds:=SecondsBetween(Now, d);
    
    days:=num_seconds div (60 * 60 * 24);
    num_seconds -= days * (60 * 60 * 24);
    hours:=num_seconds div  (60 * 60);
    num_seconds -= hours * (60 * 60);
    minutes:=num_seconds div 60;
    
    nick:=ExtractWord(1, s, [':']);
    PluginParse:=nick+': current bot uptime: '+IntToStr(days)+' days '+IntToStr(hours)+' hours '+IntToStr(minutes)+' minutes.';
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
    d:=Now();
end.
