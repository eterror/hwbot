{$MODE OBJFPC}

unit hwTypes;

interface

uses
    sockets,
    dynlibs;


const
    HW_MAXUSERS	  = 2048;
    HW_MAXPLUGINS = 16;
    HW_IP       = '140.247.62.101';
    HW_PORT     = 46631;
    HW_PROTO    = 47;
    HW_CONFIG   = 'hw.conf';
    VERSION     = '0.3rc3';
    HW_ADMIN    = 'terror';


var
    sAddr:      TInetSockAddr;
    S:          LongInt;
    sIn,
    sOut:       Text;
    i:          Integer;

    quit:       boolean;
    line:       String;
    motd:       AnsiString;

    HW_NICK:    String;
    HW_PLUGINS: String;
    HW_ROOM:    String;
    HW_PASSWORD:String;


type
    TUser = packed record
	mode:		String;
	nickname: 	String;
	upname:		String;
	srcip:		String;
    end;    
    
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
	    TPluginInit =	procedure (var sin, sout: Text); cdecl;
            TParse =		function (const s: String; const u: array of TUser; botnick: String):String; cdecl;
            TOnJoinLobby =	function (const s: String):String; cdecl;
            TOnJoinRoom = 	function (const s: String):String; cdecl;
            TOnQuit =          	function (const s: String):String; cdecl;
            TGetCommand =      	function :String; cdecl;
            TGetPluginVersion =	function :String; cdecl;
            TGetPluginAuthor = 	function: String; cdecl;
            TGetPluginName =   	function: String; cdecl;
            TGetPluginUsage =  	function: String; cdecl;
            TGetPluginHelp =   	function: AnsiString; cdecl;

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
            ginit:		TPluginInit;
    end;

    TRoom = packed record
        password,
        owner, 
        mode,
        map, 
        scheme,
        weapons,
        users, 
        teams:   String;
    end;

implementation

begin
end.
